"""Opérateurs de mutation, ligne par ligne, sur GDScript et sur les scènes .tscn.

Chaque opérateur ne touche que le code : les chaînes ("…", '…', &"…", ^"…") et les
commentaires (# …) sont masqués avant toute recherche. Un mutant = une seule modification
d'une seule ligne (ou la suppression d'une ligne de connexion). L'énumération est
déterministe : fichiers triés, lignes dans l'ordre, opérateurs dans l'ordre de OPERATEURS,
occurrences de gauche à droite.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Callable, Iterator

SUFFIXE = "_mut"


@dataclass(frozen=True)
class Mutant:
    fichier: str          # chemin relatif posix dans le projet
    ligne: int            # numéro de ligne (1-based) dans le fichier d'origine
    operateur: str
    occurrence: int
    avant: str            # ligne d'origine (sans fin de ligne)
    apres: str | None     # ligne mutée ; None = ligne supprimée

    @property
    def id(self) -> str:
        return f"{self.fichier}:{self.ligne}:{self.operateur}:{self.occurrence}"

    def appliquer(self, texte: str) -> str:
        lignes = texte.split("\n")
        if lignes[self.ligne - 1] != self.avant:
            raise ValueError(f"mutant {self.id} : la ligne {self.ligne} ne correspond plus")
        if self.apres is None:
            del lignes[self.ligne - 1]
        else:
            lignes[self.ligne - 1] = self.apres
        return "\n".join(lignes)


def masque_code(ligne: str) -> str:
    """Même longueur que `ligne`, chaînes et commentaire remplacés par des espaces (« \x00 »)."""
    sortie = []
    i = 0
    n = len(ligne)
    while i < n:
        c = ligne[i]
        if c == "#":
            sortie.append("\x00" * (n - i))
            break
        if c in "\"'":
            debut = i
            triple = ligne[i:i + 3] == c * 3
            fin = c * 3 if triple else c
            i += len(fin)
            while i < n and ligne[i:i + len(fin)] != fin:
                i += 2 if ligne[i] == "\\" else 1
            i = min(n, i + len(fin))
            sortie.append("\x00" * (i - debut))
            continue
        sortie.append(c)
        i += 1
    return "".join(sortie)


def _remplacer(ligne: str, debut: int, fin: int, par: str) -> str:
    return ligne[:debut] + par + ligne[fin:]


def _par_motif(motif: re.Pattern[str], remplacement: Callable[[re.Match[str]], str | None]):
    def operateur(ligne: str, code: str) -> Iterator[str]:
        for m in motif.finditer(code):
            par = remplacement(m)
            if par is not None and par != m.group(0):
                yield _remplacer(ligne, m.start(), m.end(), par)
    return operateur


def _indentation(ligne: str) -> str:
    return ligne[:len(ligne) - len(ligne.lstrip())]


# --- GDScript ----------------------------------------------------------------------------------

_COMPARAISONS = {"<=": "<", "<": "<=", ">=": ">", ">": ">=", "==": "!=", "!=": "=="}
comparaison_inversee = _par_motif(re.compile(r"(?<![<>=!\-])(<=|>=|==|!=|<(?![<=])|>(?![>=]))"),
                                  lambda m: _COMPARAISONS[m.group(1)])

_ARITH = {" + ": " - ", " - ": " + ", " * ": " / ", " / ": " * ", " += ": " -= ", " -= ": " += "}
operateur_arithmetique = _par_motif(re.compile(r" (?:\+=|-=|\+|-|\*|/) "), lambda m: _ARITH[m.group(0)])


def _constante(m: re.Match[str]) -> str:
    texte = m.group(0)
    if "." in texte:
        valeur = float(texte)
        return repr(valeur * 2 if valeur else 1.0)
    return str(int(texte) + 1)


constante_modifiee = _par_motif(re.compile(r"(?<![\w.])\d+(?:\.\d+)?(?![\w.])"), _constante)

chemin_noeud_casse = _par_motif(re.compile(r"\$[A-Za-z_]\w*(?:/[A-Za-z_]\w*)*"), lambda m: m.group(0) + SUFFIXE)

await_retire = _par_motif(re.compile(r"\bawait\s+"), lambda m: "")

_TYPES = {"float": "int", "int": "float", "bool": "int", "String": "int", "Vector2": "Vector3",
          "PackedScene": "Script"}
type_exporte = _par_motif(re.compile(r"(?<=@export var )([A-Za-z_]\w*\s*:\s*)([A-Za-z_]\w*)"),
                          lambda m: m.group(1) + _TYPES[m.group(2)] if m.group(2) in _TYPES else None)

booleen_inverse = _par_motif(re.compile(r"\b(true|false)\b"), lambda m: "false" if m.group(1) == "true" else "true")

signal_renomme = _par_motif(re.compile(r"^(signal\s+)([A-Za-z_]\w*)"), lambda m: m.group(1) + m.group(2) + SUFFIXE)

methode_renommee = _par_motif(re.compile(r"^((?:static\s+)?func\s+)([A-Za-z_]\w*)"),
                              lambda m: m.group(1) + m.group(2) + SUFFIXE)

_MOTS_CLES = {"return", "if", "elif", "else", "for", "while", "match", "var", "const", "pass", "await", "func",
              "signal", "break", "continue", "class_name", "extends", "static", "enum", "class", "assert"}


def appel_supprime(ligne: str, code: str) -> Iterator[str]:
    """Une instruction qui n'est qu'un appel (`f(x)`, `a.b.emit()`, `queue_free()`) devient `pass`."""
    contenu = code.strip()
    if not ligne.startswith(("\t", " ")) or not contenu.endswith(")"):
        return
    tete = re.match(r"[A-Za-z_][\w.]*", contenu)
    if not tete or tete.group(0).split(".")[0] in _MOTS_CLES or tete.end() >= len(contenu) or contenu[tete.end()] != "(":
        return
    profondeur = 0
    for c in contenu:
        profondeur += c in "([{"
        profondeur -= c in ")]}"
        if profondeur == 0 and c == "=":
            return
    yield _indentation(ligne) + "pass"


def connexion_retiree_gd(ligne: str, code: str) -> Iterator[str]:
    if ligne.startswith(("\t", " ")) and re.search(r"\.connect\(", code) and code.strip().endswith(")"):
        yield _indentation(ligne) + "pass"


def condition_niee(ligne: str, code: str) -> Iterator[str]:
    m = re.match(r"^(\s*)(if|elif|while)\s+(.+?)\s*:\s*$", code)
    if m:
        debut = m.start(3)
        fin = m.end(3)
        yield ligne[:debut] + f"not ({ligne[debut:fin]})" + ligne[fin:]


def argument_retire(ligne: str, code: str) -> Iterator[str]:
    m = re.match(r"^((?:static\s+)?func\s+[A-Za-z_]\w*\()(.*)(\)\s*(?:->\s*[^:]+)?:.*)$", code)
    if not m or not m.group(2).strip():
        return
    arguments = ligne[m.start(2):m.end(2)]
    morceaux = [a for a in arguments.split(",")]
    if any("(" in a or "[" in a for a in morceaux):
        return  # valeur par défaut composée : on s'abstient (découpage par virgules incertain)
    yield ligne[:m.start(2)] + ",".join(morceaux[:-1]).rstrip() + ligne[m.end(2):]


OPERATEURS_GD: dict[str, Callable[[str, str], Iterator[str]]] = {
    "comparaison_inversee": comparaison_inversee,
    "operateur_arithmetique": operateur_arithmetique,
    "constante_modifiee": constante_modifiee,
    "chemin_noeud_casse": chemin_noeud_casse,
    "connexion_supprimee": connexion_retiree_gd,
    "await_retire": await_retire,
    "type_exporte": type_exporte,
    "appel_supprime": appel_supprime,
    "condition_niee": condition_niee,
    "signal_renomme": signal_renomme,
    "booleen_inverse": booleen_inverse,
    "methode_renommee": methode_renommee,
    "argument_retire": argument_retire,
}

# --- Scènes .tscn ------------------------------------------------------------------------------

_CONNEXION = re.compile(r'^\[connection signal="([^"]+)"')
_PARENT = re.compile(r'(?<= parent=")([^".][^"]*)(?=")')


def operateurs_tscn(ligne: str) -> Iterator[tuple[str, str | None]]:
    m = _CONNEXION.match(ligne)
    if m:
        yield "connexion_supprimee", None
        yield "signal_renomme", ligne[:m.start(1)] + m.group(1) + SUFFIXE + ligne[m.end(1):]
    m = _PARENT.search(ligne)
    if m and ligne.startswith("[node "):
        yield "chemin_noeud_casse", ligne[:m.start(1)] + m.group(1) + SUFFIXE + ligne[m.end(1):]


def mutants_fichier(rel: str, texte: str, lignes: set[int] | None = None,
                    operateurs: set[str] | None = None) -> list[Mutant]:
    """Tous les mutants d'un fichier, éventuellement restreints à certaines lignes (1-based)."""
    resultat: list[Mutant] = []
    for num, ligne in enumerate(texte.split("\n"), start=1):
        if lignes is not None and num not in lignes:
            continue
        candidats: list[tuple[str, str | None]] = []
        if rel.endswith(".gd"):
            if ligne.lstrip().startswith("#") or not ligne.strip():
                continue
            code = masque_code(ligne)
            for nom, op in OPERATEURS_GD.items():
                candidats += [(nom, m) for m in op(ligne, code)]
        elif rel.endswith(".tscn"):
            candidats = list(operateurs_tscn(ligne))
        compte: dict[str, int] = {}
        for nom, apres in candidats:
            if operateurs is not None and nom not in operateurs:
                continue
            k = compte.get(nom, 0)
            compte[nom] = k + 1
            resultat.append(Mutant(rel, num, nom, k, ligne, apres))
    return resultat


def mutants_projet(fichiers: dict[str, str], cibles: dict[str, set[int] | None] | None = None,
                   operateurs: set[str] | None = None) -> list[Mutant]:
    """Mutants des scripts et scènes du jeu (hors tests/). `cibles` : {fichier: lignes ou None}."""
    if cibles is None:
        cibles = {rel: None for rel in fichiers
                  if rel.endswith((".gd", ".tscn")) and not rel.startswith("tests/")}
    resultat: list[Mutant] = []
    for rel in sorted(cibles):
        if rel in fichiers:
            resultat += mutants_fichier(rel, fichiers[rel], cibles[rel], operateurs)
    return resultat


NOMS_OPERATEURS = sorted(set(OPERATEURS_GD) | {"connexion_supprimee", "signal_renomme", "chemin_noeud_casse"})
