"""Lecture légère et déterministe de GDScript : déclarations de premier niveau seulement.

Ce n'est pas un analyseur complet : on repère class_name, extends, signal, var/const,
enum et func au niveau d'indentation 0, avec leurs lignes. Le juge Godot reste
l'autorité sur la validité du script ; ceci sert à décrire et à éditer.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

_CLASS_NAME = re.compile(r"^class_name\s+([A-Za-z_]\w*)")
_EXTENDS = re.compile(r"^extends\s+(\"[^\"]+\"|'[^']+'|[A-Za-z_][\w.]*)")
_SIGNAL = re.compile(r"^signal\s+([A-Za-z_]\w*)\s*(?:\((.*)\))?\s*(?:#.*)?$")
_VAR = re.compile(r"^((?:@[\w.]+(?:\([^)]*\))?\s+)*)(?:static\s+)?var\s+([A-Za-z_]\w*)\s*(?::\s*([^=:]+?))?\s*(?::?=\s*(.+?))?\s*(?::\s*$|$)")
_CONST = re.compile(r"^const\s+([A-Za-z_]\w*)")
_ENUM = re.compile(r"^enum\s+([A-Za-z_]\w*)")
_FUNC = re.compile(r"^(static\s+)?func\s+([A-Za-z_]\w*)\s*\(")


@dataclass
class Argument:
    nom: str
    type: str | None = None
    defaut: str | None = None

    def texte(self) -> str:
        t = self.nom + (f": {self.type}" if self.type else "")
        if self.defaut is not None:
            t += " = " + self.defaut
        return t


@dataclass
class Fonction:
    nom: str
    arguments: list[Argument]
    retour: str | None
    statique: bool
    ligne_debut: int          # index (0-based) de la ligne « func »
    ligne_corps: int          # première ligne du corps (après la signature)
    ligne_fin: int            # index exclu : fin du corps (lignes vides et commentaires finaux exclus)
    une_ligne: bool = False   # func f() -> int: return 1

    @property
    def nb_obligatoires(self) -> int:
        return sum(1 for a in self.arguments if a.defaut is None)

    def signature(self) -> str:
        t = ("static " if self.statique else "") + f"func {self.nom}(" + ", ".join(a.texte() for a in self.arguments) + ")"
        return t + (f" -> {self.retour}" if self.retour else "")


@dataclass
class Signal:
    nom: str
    arguments: list[Argument]
    ligne: int

    def texte(self) -> str:
        return f"signal {self.nom}" + (f"({', '.join(a.texte() for a in self.arguments)})" if self.arguments else "")


@dataclass
class Variable:
    nom: str
    type: str | None
    defaut: str | None
    annotations: str
    ligne: int

    @property
    def exportee(self) -> bool:
        return "@export" in self.annotations

    def texte(self) -> str:
        t = (self.annotations.strip() + " " if self.annotations.strip() else "") + f"var {self.nom}"
        if self.type:
            t += f": {self.type}"
        if self.defaut is not None:
            t += f" = {self.defaut}"
        return t


@dataclass
class Script:
    chemin: str
    class_name: str | None = None
    extends: str | None = None
    signaux: list[Signal] = field(default_factory=list)
    variables: list[Variable] = field(default_factory=list)
    constantes: list[str] = field(default_factory=list)
    enums: list[str] = field(default_factory=list)
    fonctions: list[Fonction] = field(default_factory=list)
    lignes: list[str] = field(default_factory=list)
    fin_entete: int = 0       # index de la ligne qui suit class_name/extends/@tool et la doc ##

    def fonction(self, nom: str) -> Fonction | None:
        return next((f for f in self.fonctions if f.nom == nom), None)

    def signal(self, nom: str) -> Signal | None:
        return next((s for s in self.signaux if s.nom == nom), None)

    def variable(self, nom: str) -> Variable | None:
        return next((v for v in self.variables if v.nom == nom), None)


def _decouper_virgules(texte: str) -> list[str]:
    morceaux, profondeur, courant, chaine = [], 0, [], None
    for c in texte:
        if chaine:
            courant.append(c)
            if c == chaine:
                chaine = None
            continue
        if c in "\"'":
            chaine = c
        elif c in "([{":
            profondeur += 1
        elif c in ")]}":
            profondeur -= 1
        elif c == "," and profondeur == 0:
            morceaux.append("".join(courant))
            courant = []
            continue
        courant.append(c)
    if "".join(courant).strip():
        morceaux.append("".join(courant))
    return [m.strip() for m in morceaux if m.strip()]


def lire_arguments(texte: str) -> list[Argument]:
    arguments = []
    for morceau in _decouper_virgules(texte):
        defaut = None
        if ":=" in morceau:
            morceau, defaut = (x.strip() for x in morceau.split(":=", 1))
            nom, type_ = morceau, None
        else:
            if "=" in morceau:
                morceau, defaut = (x.strip() for x in morceau.split("=", 1))
            nom, _, type_ = (x.strip() for x in morceau.partition(":"))
            type_ = type_ or None
        arguments.append(Argument(nom, type_, defaut))
    return arguments


def _indentation(ligne: str) -> int:
    return len(ligne) - len(ligne.lstrip(" \t"))


def _est_code_niveau0(ligne: str) -> bool:
    return bool(ligne.strip()) and _indentation(ligne) == 0 and not ligne.lstrip().startswith("#")


def _signature(lignes: list[str], debut: int) -> tuple[str, int]:
    """Signature complète (éventuellement sur plusieurs lignes). Renvoie (texte, index de la dernière ligne)."""
    texte = ""
    for k in range(debut, len(lignes)):
        texte += lignes[k].rstrip("\r\n") + " "
        profondeur, fermee, chaine = 0, False, None
        for c in texte:
            if chaine:
                chaine = None if c == chaine else chaine
            elif c in "\"'":
                chaine = c
            elif c == "(":
                profondeur += 1
            elif c == ")":
                profondeur -= 1
                fermee = profondeur == 0
        if fermee and profondeur == 0 and ":" in texte[texte.rfind(")"):]:
            return texte, k
    return texte, len(lignes) - 1


def fin_bloc(lignes: list[str], debut: int) -> int:
    """Fin (exclue) du bloc indenté qui commence à `debut` : avant la ligne de code suivante
    de niveau 0, sans les lignes vides ni les commentaires de niveau 0 qui la précèdent."""
    k = debut
    while k < len(lignes) and not _est_code_niveau0(lignes[k]):
        k += 1
    while k > debut and (not lignes[k - 1].strip() or (_indentation(lignes[k - 1]) == 0 and lignes[k - 1].lstrip().startswith("#"))):
        k -= 1
    return k


def lire_script(texte: str, chemin: str = "") -> Script:
    lignes = texte.splitlines(keepends=True)
    s = Script(chemin=chemin, lignes=lignes)
    entete_ouverte = True
    k = 0
    while k < len(lignes):
        brute = lignes[k]
        ligne = brute.rstrip("\r\n")
        if not ligne.strip() or _indentation(ligne) > 0:
            k += 1
            continue
        if ligne.lstrip().startswith("#"):
            if entete_ouverte and ligne.startswith("##"):
                s.fin_entete = k + 1
            k += 1
            continue
        m = _CLASS_NAME.match(ligne)
        if m:
            s.class_name = m.group(1)
            # « class_name X extends Y » sur une ligne
            reste = ligne[m.end():].strip()
            if reste.startswith("extends"):
                me = _EXTENDS.match(reste)
                if me:
                    s.extends = me.group(1).strip("\"'")
            s.fin_entete = k + 1
            k += 1
            continue
        m = _EXTENDS.match(ligne)
        if m:
            s.extends = m.group(1).strip("\"'")
            s.fin_entete = k + 1
            k += 1
            continue
        if ligne.startswith(("@tool", "@icon", "@static_unload", "@abstract")) and "var " not in ligne and "func " not in ligne:
            if entete_ouverte:
                s.fin_entete = k + 1
            k += 1
            continue
        entete_ouverte = False
        m = _SIGNAL.match(ligne)
        if m:
            s.signaux.append(Signal(m.group(1), lire_arguments(m.group(2) or ""), k))
            k += 1
            continue
        m = _FUNC.match(ligne)
        if m:
            texte_sig, derniere = _signature(lignes, k)
            ouverture = texte_sig.index("(")
            profondeur, fermeture = 0, ouverture
            for n in range(ouverture, len(texte_sig)):
                if texte_sig[n] == "(":
                    profondeur += 1
                elif texte_sig[n] == ")":
                    profondeur -= 1
                    if profondeur == 0:
                        fermeture = n
                        break
            args = lire_arguments(texte_sig[ouverture + 1:fermeture])
            apres = texte_sig[fermeture + 1:]
            mr = re.match(r"\s*->\s*([^:]+?)\s*:", apres)
            retour = mr.group(1).strip() if mr else None
            deux_points = apres.index(":") if ":" in apres else len(apres)
            une_ligne = bool(apres[deux_points + 1:].split("#", 1)[0].strip())
            corps = derniere + 1
            fin = corps if une_ligne else fin_bloc(lignes, corps)
            s.fonctions.append(Fonction(m.group(2), args, retour, bool(m.group(1)), k, corps, fin, une_ligne))
            k = max(fin, corps)
            continue
        m = _VAR.match(ligne)
        if m and " var " in f" {ligne} ".replace("\t", " "):
            s.variables.append(Variable(m.group(2), (m.group(3) or "").strip() or None,
                                        (m.group(4) or None), (m.group(1) or "").strip(), k))
            k = fin_bloc(lignes, k + 1) if ligne.rstrip().endswith(":") else k + 1
            continue
        m = _CONST.match(ligne)
        if m:
            s.constantes.append(m.group(1))
        m = _ENUM.match(ligne)
        if m:
            s.enums.append(m.group(1))
        k += 1
    return s


def lire_fichier(chemin: Path, res: str = "") -> Script:
    return lire_script(Path(chemin).read_text(encoding="utf-8"), res or str(chemin))


def unite_indentation(lignes: list[str]) -> str:
    """Unité d'indentation d'un script : tabulation (défaut) ou n espaces."""
    for ligne in lignes:
        if ligne.strip() and _indentation(ligne) > 0:
            blanc = ligne[:_indentation(ligne)]
            if blanc.startswith("\t"):
                return "\t"
            return " " * len(blanc)
    return "\t"


def reindenter(code: str, unite: str, niveau_base: int = 0) -> list[str]:
    """Réindente un bloc de code avec `unite`, en conservant les niveaux relatifs.

    Le niveau minimal du code devient `niveau_base`. Les tabulations comptent pour un niveau ;
    les espaces sont regroupés selon la plus petite indentation non nulle rencontrée.
    """
    lignes = code.replace("\r\n", "\n").split("\n")
    while lignes and not lignes[-1].strip():
        lignes.pop()
    while lignes and not lignes[0].strip():
        lignes.pop(0)

    def niveau_brut(ligne: str) -> tuple[int, int]:
        blanc = ligne[:_indentation(ligne)]
        return blanc.count("\t"), blanc.count(" ")

    pas_espaces = min((niveau_brut(l)[1] for l in lignes if l.strip() and niveau_brut(l)[1] > 0), default=4)
    niveaux = []
    for l in lignes:
        t, e = niveau_brut(l)
        niveaux.append(t + (e // pas_espaces if pas_espaces else 0))
    minimum = min((n for n, l in zip(niveaux, lignes) if l.strip()), default=0)
    sortie = []
    for n, l in zip(niveaux, lignes):
        if not l.strip():
            sortie.append("\n")
        else:
            sortie.append(unite * (n - minimum + niveau_base) + l.lstrip(" \t") + "\n")
    return sortie


# --------------------------------------------------------------------------- types GDScript

TYPES_INTEGRES = {
    "bool", "int", "float", "String", "StringName", "NodePath", "Vector2", "Vector2i", "Vector3", "Vector3i",
    "Vector4", "Vector4i", "Rect2", "Rect2i", "Transform2D", "Transform3D", "Basis", "Quaternion", "Plane",
    "AABB", "Projection", "Color", "RID", "Callable", "Signal", "Dictionary", "Array", "Variant", "void",
    "PackedByteArray", "PackedInt32Array", "PackedInt64Array", "PackedFloat32Array", "PackedFloat64Array",
    "PackedStringArray", "PackedVector2Array", "PackedVector3Array", "PackedVector4Array", "PackedColorArray",
}


def arguments_json(arguments: list[Argument]) -> list[dict[str, Any]]:
    return [{"nom": a.nom, "type": a.type, **({"defaut": a.defaut} if a.defaut is not None else {})} for a in arguments]
