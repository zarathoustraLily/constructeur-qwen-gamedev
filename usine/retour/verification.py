"""Vérification du vocabulaire Godot d'un script, sans moteur et sans modèle.

`godot --check-only` ne voit pas tout : sur une variable typée, `m.set_surface_overide_material()`
ou `p.left_to_rightx = 0.5` passent sans erreur (appel non sûr, résolu à l'exécution). Ici on
relève, dans le texte du script :
  - les types écrits (`extends`, `: T`, `-> T`, `T.new()`, `as T`, `is T`, `Array[T]`) qui ne sont
    ni une classe Godot, ni une `class_name` du projet, ni déclarés dans le script ;
  - les accès `x.membre` dont le type de `x` est connu sans ambiguïté (variable ou paramètre
    typé, `T.new()`, `as T`, ou une classe nommée directement : `Input.is_action_pressed`) ;
  - l'arité des appels de méthodes Godot.
Un membre absent de la classe Godot mais déclaré par un script du projet n'est pas signalé :
l'objet peut porter ce script (appel dynamique valide). On préfère se taire que se tromper.

Chaque membre Godot reconnu renvoie sa signature officielle, lue dans `extension_api.json`.
"""

from __future__ import annotations

import difflib
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from usine.projet.gdscript import lire_script

IDENT = r"[A-Za-z_]\w*"
TYPE = rf"{IDENT}(?:\.{IDENT})*(?:\[[^\]\n]*\])?"
_VAR = re.compile(rf"\bvar\s+({IDENT})\s*(?::\s*({TYPE})?)?\s*(?:=\s*(.*))?$")
_NEW = re.compile(rf"^\s*({IDENT})\.new\(")
_AS_FIN = re.compile(rf"\bas\s+({IDENT})\s*\)?\s*$")
_ACCES = re.compile(rf"(?<![\w$%/.@\"'])({IDENT})\.({IDENT})(\s*\()?")
_TYPES_ECRITS = [
    re.compile(rf"^\s*extends\s+({IDENT})", re.M),
    re.compile(rf"->\s*({IDENT})"),
    re.compile(rf"\b({IDENT})\.new\("),
    re.compile(rf"\bas\s+({IDENT})"),
    re.compile(rf"\bis\s+(?:not\s+)?({IDENT})"),
    re.compile(rf"\b(?:Array|Dictionary)\[\s*({IDENT})"),
    re.compile(rf"\bDictionary\[\s*{IDENT}\s*,\s*({IDENT})"),
]
_CLASSE_INTERNE = re.compile(rf"^\s*class\s+({IDENT})", re.M)
_DECLARATIONS = re.compile(rf"^\s*(?:@{IDENT}(?:\([^)\n]*\))?\s+)*(?:static\s+)?(?:func|var|const|signal|enum|class)\s+({IDENT})", re.M)
_CLASS_NAME = re.compile(rf"^class_name\s+({IDENT})", re.M)
_EXTENDS = re.compile(rf"^(?:class_name\s+{IDENT}\s+)?extends\s+(\"[^\"]+\"|'[^']+'|{IDENT})", re.M)
# GdUnitTestSuite : GdUnit4 est injecté par le juge dans les copies qui ne l'ont pas.
TOUJOURS_CONNUS = {"void", "Variant", "Self", "GdUnitTestSuite"}
MAX_SIGNATURES = 15
# Membres d'Object fournis par le langage, absents d'extension_api.json.
MEMBRES_IMPLICITES = {"free"}


def nettoyer(texte: str) -> str:
    """Remplace le contenu des chaînes et les commentaires par des espaces (lignes conservées)."""
    sortie: list[str] = []
    i, n = 0, len(texte)
    while i < n:
        c = texte[i]
        if c == "#":
            while i < n and texte[i] != "\n":
                sortie.append(" ")
                i += 1
            continue
        if c in "\"'":
            triple = texte.startswith(c * 3, i)
            fin = c * 3 if triple else c
            sortie.append(c)
            i += len(fin)
            if triple:
                sortie.append(c * 2)
            while i < n and not texte.startswith(fin, i):
                if texte[i] == "\\" and i + 1 < n:
                    sortie.append("  " if texte[i + 1] != "\n" else " \n")
                    i += 2
                    continue
                if texte[i] == "\n" and not triple:
                    break
                sortie.append("\n" if texte[i] == "\n" else " ")
                i += 1
            if texte.startswith(fin, i):
                sortie.append(fin)
                i += len(fin)
            continue
        sortie.append(c)
        i += 1
    return "".join(sortie)


def _base_type(t: str | None) -> str | None:
    """`Array[Node]` → Array ; `Node.ProcessMode` (énumération) → None ; vide → None."""
    if not t:
        return None
    t = t.strip()
    if "[" in t:
        t = t.split("[", 1)[0]
    return None if "." in t else t


def _arguments_appel(texte: str, ouverture: int) -> int | None:
    """Nombre d'arguments de l'appel dont la parenthèse ouvrante est à `ouverture`."""
    profondeur, nb, contenu = 0, 0, False
    for k in range(ouverture, len(texte)):
        c = texte[k]
        if c in ")]}":
            profondeur -= 1
            if profondeur == 0:
                return nb + 1 if contenu else 0
        if k > ouverture and not c.isspace():
            contenu = True
        if c in "([{":
            profondeur += 1
        elif c == "," and profondeur == 1:
            nb += 1
    return None


@dataclass
class ScriptProjet:
    chemin: str
    class_name: str | None
    extends: str | None
    noms: set[str]


@dataclass
class IndexProjet:
    """Scripts du projet : `class_name`, parent et noms déclarés (fonctions, variables…)."""

    scripts: dict[str, ScriptProjet] = field(default_factory=dict)

    @classmethod
    def lire(cls, projet: Path | None) -> "IndexProjet":
        index = cls()
        if projet is None:
            return index
        projet = Path(projet)
        for f in sorted(projet.rglob("*.gd")):
            rel = f.relative_to(projet)
            if rel.parts[0] == ".godot":
                continue
            try:
                texte = f.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue
            index.ajouter("res://" + rel.as_posix(), texte)
        return index

    def ajouter(self, chemin: str, texte: str) -> ScriptProjet:
        propre = nettoyer(texte)
        cn = _CLASS_NAME.search(propre)
        ex = _EXTENDS.search(propre)
        s = ScriptProjet(chemin, cn.group(1) if cn else None, ex.group(1).strip("\"'") if ex else None,
                         set(_DECLARATIONS.findall(propre)))
        self.scripts[chemin] = s
        return s

    def par_classe(self, nom: str) -> ScriptProjet | None:
        return next((s for s in self.scripts.values() if s.class_name == nom), None)

    def classes(self) -> set[str]:
        return {s.class_name for s in self.scripts.values() if s.class_name}

    def tous_les_noms(self) -> set[str]:
        return set().union(*(s.noms for s in self.scripts.values())) if self.scripts else set()

    def chaine(self, depart: ScriptProjet, vocab) -> tuple[set[str], str | None]:
        """Noms déclarés le long de la chaîne de scripts, et la première classe Godot atteinte."""
        noms: set[str] = set()
        s: ScriptProjet | None = depart
        vus: set[str] = set()
        while s is not None and s.chemin not in vus:
            vus.add(s.chemin)
            noms |= s.noms
            parent = s.extends
            if parent is None:
                return noms, "RefCounted"
            if parent.startswith("res://"):
                s = self.scripts.get(parent)
            elif vocab.classe_existe(parent):
                return noms, parent
            else:
                s = self.par_classe(parent)
        return noms, None


class Signatures:
    """Signatures officielles des membres, avec un cache par classe."""

    def __init__(self, vocab):
        self.vocab = vocab
        self._cache: dict[str, dict[str, list[tuple[str, dict]]]] = {}

    def membres(self, classe: str) -> dict[str, list[tuple[str, dict]]]:
        if classe not in self._cache:
            table: dict[str, list[tuple[str, dict]]] = {}
            v = self.vocab
            for genre, liste in (("méthode", v.methodes(classe)), ("propriété", v.proprietes(classe)),
                                 ("signal", v.signaux(classe)), ("constante", v.constantes(classe)),
                                 ("énumération", v.enums(classe))):
                for m in liste:
                    table.setdefault(m["nom"], []).append((genre, m))
            for e in v.enums(classe):
                for val in e["valeurs"]:
                    table.setdefault(val["nom"], []).append(("valeur", {**val, "origine": e["origine"]}))
            self._cache[classe] = table
        return self._cache[classe]

    def texte(self, classe: str, membre: str) -> str | None:
        trouves = self.membres(classe).get(membre)
        if not trouves:
            return None
        genre, m = trouves[0]
        return f"{m['origine']}.{signature(m)}" if genre != "valeur" else f"{m['origine']}.{m['nom']} = {m['valeur']}"

    def dans_une_descendante(self, classe: str, membre: str) -> bool:
        """Vrai si une classe dérivée de `classe` définit `membre` (accès dynamique valide)."""
        if not hasattr(self, "_enfants"):
            self._enfants: dict[str, list[str]] = {}
            for nom, parent in self.vocab.db.execute("SELECT nom, parent FROM classes WHERE parent IS NOT NULL"):
                self._enfants.setdefault(parent, []).append(nom)
        a_voir, descendantes = list(self._enfants.get(classe, [])), []
        while a_voir:
            c = a_voir.pop()
            descendantes.append(c)
            a_voir += self._enfants.get(c, [])
        if not descendantes:
            return False
        marques = ",".join("?" * len(descendantes))
        for table in ("methodes", "proprietes", "signaux", "constantes"):
            if self.vocab.db.execute(f"SELECT 1 FROM {table} WHERE nom=? AND classe IN ({marques}) LIMIT 1",
                                     (membre, *descendantes)).fetchone():
                return True
        return False

    def proches(self, classe: str, membre: str, n: int = 3) -> list[str]:
        noms = difflib.get_close_matches(membre, list(self.membres(classe)), n=n, cutoff=0.6)
        return [self.texte(classe, x) or x for x in noms]


def signature(m: dict[str, Any]) -> str:
    if "valeurs" in m:
        return m["nom"] + "{" + ",".join(v["nom"] for v in m["valeurs"]) + "}"
    if "valeur" in m:
        return f"{m['nom']} = {m['valeur']}"
    if "arguments" in m:
        args = ", ".join(f"{a['nom']}: {a['type']}" + (f" = {a['defaut']}" if a.get("defaut") not in (None, "") else "")
                         for a in m["arguments"])
        retour = f" -> {m['retour']}" if m.get("retour") else ""
        return f"{m['nom']}({args}{', ...' if m.get('vararg') else ''}){retour}"
    return f"{m['nom']}: {m['type']}" if m.get("type") else m["nom"]


def _types_variables(propre: str, texte: str, chemin: str) -> dict[str, str]:
    """Nom → type, pour les variables et paramètres typés sans ambiguïté."""
    vus: dict[str, set[str | None]] = {}
    for ligne in propre.splitlines():
        m = _VAR.search(ligne)
        if not m:
            continue
        t = _base_type(m.group(2))
        valeur = (m.group(3) or "").strip()
        if t is None and valeur:
            mn = _NEW.match(valeur)
            ma = _AS_FIN.search(valeur)
            t = mn.group(1) if mn else (ma.group(1) if ma else None)
        vus.setdefault(m.group(1), set()).add(t)
    for f in lire_script(texte, chemin).fonctions:
        for a in f.arguments:
            vus.setdefault(a.nom, set()).add(_base_type(a.type))
    return {nom: next(iter(ts)) for nom, ts in vus.items() if len(ts) == 1 and next(iter(ts))}


def verifier_script(texte: str, chemin: str, vocab, projet: IndexProjet | None = None,
                    signatures: Signatures | None = None) -> dict[str, Any]:
    """Rapport : {"verifies", "problemes": [{ligne, message}], "signatures": [...]}."""
    projet = projet or IndexProjet()
    projet.ajouter(chemin, texte)
    sig = signatures or Signatures(vocab)
    propre = nettoyer(texte)
    locaux = set(_DECLARATIONS.findall(propre)) | set(_CLASSE_INTERNE.findall(propre))
    classes_projet = projet.classes()
    noms_projet = projet.tous_les_noms()
    problemes: list[dict[str, Any]] = []
    signes: dict[str, None] = {}
    verifies = 0

    def ligne_de(pos: int) -> int:
        return propre.count("\n", 0, pos) + 1

    def connu(t: str) -> bool:
        return t in TOUJOURS_CONNUS or t in locaux or t in classes_projet or vocab.classe_existe(t)

    # 1. Types écrits
    deja: set[str] = set()
    for motif in _TYPES_ECRITS:
        for m in motif.finditer(propre):
            t = m.group(1)
            if t in deja or not t[0].isupper():
                continue
            deja.add(t)
            if not connu(t):
                proches = difflib.get_close_matches(t, sorted(classes_projet) + _classes_godot(vocab), n=3, cutoff=0.7)
                problemes.append({"ligne": ligne_de(m.start(1)), "message":
                                  f"type inconnu : {t} n'est ni une classe de Godot {vocab.version()} ni une "
                                  "class_name du projet" + (f". Proches : {', '.join(proches)}" if proches else "")})
    for numero, ligne in enumerate(propre.splitlines(), 1):
        m = _VAR.search(ligne)
        t = _base_type(m.group(2)) if m else None
        if t and t not in deja and t[0].isupper():
            deja.add(t)
            if not connu(t):
                problemes.append({"ligne": numero, "message":
                                  f"type inconnu : {t} n'est ni une classe de Godot {vocab.version()} ni une "
                                  "class_name du projet"})

    # 2. Accès à des membres
    types = _types_variables(propre, texte, chemin)
    for m in _ACCES.finditer(propre):
        recepteur, membre, appel = m.group(1), m.group(2), m.group(3)
        if recepteur in ("self", "super") or membre == "new" or membre in MEMBRES_IMPLICITES:
            continue
        if recepteur in types:
            t = types[recepteur]
        elif recepteur[0].isupper() and recepteur not in locaux and (vocab.classe_existe(recepteur) or recepteur in classes_projet):
            t = recepteur
        else:
            continue
        ligne = ligne_de(m.start())
        script = projet.par_classe(t) if t in classes_projet else None
        if script is not None:
            noms, natif = projet.chaine(script, vocab)
            if membre in noms:
                verifies += 1
                continue
            if natif is None or membre in noms_projet or sig.dans_une_descendante(natif, membre):
                continue  # chaîne illisible, ou objet d'un script dérivé : on se tait
            if sig.texte(natif, membre) is None:
                proches = difflib.get_close_matches(membre, sorted(noms) + list(sig.membres(natif)), n=3, cutoff=0.6)
                problemes.append({"ligne": ligne, "message":
                                  f"{t} n'a aucun membre {membre} (ni dans ses scripts, ni dans {natif})"
                                  + (f". Proches : {', '.join(proches)}" if proches else "")})
                continue
            t = natif
        elif not vocab.classe_existe(t) or (t == "Dictionary" and not appel):
            continue  # d.cle lit une clé de dictionnaire
        texte_sig = sig.texte(t, membre)
        if texte_sig is None:
            if membre in noms_projet or sig.dans_une_descendante(t, membre):
                continue  # l'objet peut être d'une classe dérivée, ou porter un script du projet
            proches = sig.proches(t, membre)
            problemes.append({"ligne": ligne, "message":
                              f"{t} n'a aucun membre {membre} dans Godot {vocab.version()} (héritage compris)"
                              + (f". Proches : {' ; '.join(proches)}" if proches else "")})
            continue
        verifies += 1
        signes[texte_sig] = None
        if appel:
            genre, info = sig.membres(t)[membre][0]
            if genre == "méthode":
                nb = _arguments_appel(propre, m.end() - 1)
                obligatoires = sum(1 for a in info["arguments"] if a.get("defaut") in (None, ""))
                maximum = None if info.get("vararg") else len(info["arguments"])
                if nb is not None and (nb < obligatoires or (maximum is not None and nb > maximum)):
                    attendu = (f"{obligatoires}" if obligatoires == maximum else
                               f"{obligatoires} à {maximum}" if maximum is not None else f"au moins {obligatoires}")
                    problemes.append({"ligne": ligne, "message":
                                      f"{t}.{membre} attend {attendu} argument(s), l'appel en passe {nb} : {texte_sig}"})
    problemes.sort(key=lambda p: p["ligne"])
    return {"verifies": verifies, "problemes": problemes, "signatures": list(signes)}


_CLASSES: list[str] | None = None


def _classes_godot(vocab) -> list[str]:
    global _CLASSES
    if _CLASSES is None:
        _CLASSES = [r[0] for r in vocab.db.execute("SELECT nom FROM classes WHERE nom NOT LIKE '@%'")]
    return _CLASSES


def formater_rapport(rapport: dict[str, Any], chemin: str, version: str) -> str:
    """Texte court pour le modèle."""
    lignes = []
    if rapport["problemes"]:
        lignes.append(f"Vocabulaire Godot {version} dans {chemin} : {len(rapport['problemes'])} problème(s).")
        lignes += [f"✗ ligne {p['ligne']} : {p['message']}" for p in rapport["problemes"]]
    else:
        lignes.append(f"Vocabulaire Godot {version} dans {chemin} : aucun membre inconnu "
                      f"({rapport['verifies']} accès vérifiés).")
    signes = rapport["signatures"]
    if signes:
        lignes.append("Signatures officielles des membres Godot utilisés :")
        lignes += [f"✓ {s}" for s in signes[:MAX_SIGNATURES]]
        if len(signes) > MAX_SIGNATURES:
            lignes.append(f"… et {len(signes) - MAX_SIGNATURES} autres.")
    return "\n".join(lignes)
