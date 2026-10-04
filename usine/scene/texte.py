"""Format texte des ressources Godot 4 (.tscn, .tres) : valeurs et document sans perte.

Deux couches, sans LLM :

- **Valeurs** : `lire_valeur(texte, pos)` décode une valeur Godot (Variant écrit en texte)
  en JSON typé, `ecrire_valeur(json)` la réécrit sous la forme qu'emploie Godot 4.7.
  Codage JSON (détaillé dans SPEC_SCENE.md) :
    null, booléens, entiers, flottants, chaînes → JSON natif ;
    {"Vector2": [x, y]}, {"Color": [r, g, b, a]}, {"PackedStringArray": ["a"]}… → constructeur ;
    {"StringName": "x"}, {"NodePath": "a/b"}, {"ExtResource": "id"}, {"SubResource": "id"} ;
    [..] → Array ; {"Dictionary": [[clé, valeur], ...]} ; {"Array[int]": [...]} ;
    {"float": "inf" | "-inf" | "nan"} ; {"godot": "<texte brut>"} en dernier recours.
- **Document** : `lire_document(texte)` découpe un fichier en sections ([gd_scene], [node]…)
  dont chacune garde son texte d'origine. `Document.texte()` rend les mêmes octets tant
  qu'on n'a rien modifié ; une édition ne réécrit que la ligne ou la section touchée.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from typing import Any

# Constructeurs dont les arguments sont des entiers (écrits sans partie décimale).
CONSTRUCTEURS_ENTIERS = {"Vector2i", "Vector3i", "Vector4i", "Rect2i", "PackedByteArray",
                         "PackedInt32Array", "PackedInt64Array"}
CLES_REFERENCES = {"ExtResource", "SubResource"}
CLES_SPECIALES = {"StringName", "NodePath", "Dictionary", "float", "godot"} | CLES_REFERENCES

_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_NOMBRE = re.compile(r"-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")
_ECHAPPEMENTS = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f", "a": "\a", "v": "\v",
                 '"': '"', "'": "'", "\\": "\\"}


class ErreurTexte(ValueError):
    """Texte de valeur Godot illisible."""


# --------------------------------------------------------------------------- valeurs : lecture

def _espaces(t: str, i: int) -> int:
    while i < len(t) and t[i] in " \t\r\n":
        i += 1
    return i


def _lire_chaine(t: str, i: int) -> tuple[str, int]:
    """Chaîne entre guillemets commençant à t[i] == '"'. Renvoie (chaîne décodée, fin)."""
    assert t[i] == '"'
    i += 1
    morceaux: list[str] = []
    while True:
        if i >= len(t):
            raise ErreurTexte("chaîne non terminée")
        c = t[i]
        if c == '"':
            return "".join(morceaux), i + 1
        if c == "\\":
            if i + 1 >= len(t):
                raise ErreurTexte("échappement en fin de texte")
            e = t[i + 1]
            if e in _ECHAPPEMENTS:
                morceaux.append(_ECHAPPEMENTS[e])
                i += 2
            elif e in "uU":
                n = 4 if e == "u" else 6
                morceaux.append(chr(int(t[i + 2:i + 2 + n], 16)))
                i += 2 + n
            else:
                morceaux.append(e)
                i += 2
        else:
            morceaux.append(c)
            i += 1


def _lire_liste(t: str, i: int, fin: str) -> tuple[list[Any], int]:
    """Éléments séparés par des virgules jusqu'au caractère `fin`."""
    elements: list[Any] = []
    i = _espaces(t, i)
    if i < len(t) and t[i] == fin:
        return elements, i + 1
    while True:
        valeur, i = lire_valeur(t, i)
        elements.append(valeur)
        i = _espaces(t, i)
        if i < len(t) and t[i] == ",":
            i = _espaces(t, i + 1)
            if i < len(t) and t[i] == fin:  # virgule finale
                return elements, i + 1
            continue
        if i < len(t) and t[i] == fin:
            return elements, i + 1
        raise ErreurTexte(f"'{fin}' attendu à la position {i}")


def _lire_dictionnaire(t: str, i: int) -> tuple[list[list[Any]], int]:
    paires: list[list[Any]] = []
    i = _espaces(t, i)
    if i < len(t) and t[i] == "}":
        return paires, i + 1
    while True:
        cle, i = lire_valeur(t, i)
        i = _espaces(t, i)
        if i >= len(t) or t[i] not in ":=":
            raise ErreurTexte(f"':' attendu à la position {i}")
        valeur, i = lire_valeur(t, i + 1)
        paires.append([cle, valeur])
        i = _espaces(t, i)
        if i < len(t) and t[i] == ",":
            i = _espaces(t, i + 1)
            if i < len(t) and t[i] == "}":
                return paires, i + 1
            continue
        if i < len(t) and t[i] == "}":
            return paires, i + 1
        raise ErreurTexte(f"'}}' attendu à la position {i}")


def _crochets(t: str, i: int) -> int:
    """Fin du groupe [...] commençant à t[i] == '['."""
    profondeur = 0
    while i < len(t):
        if t[i] == '"':
            _, i = _lire_chaine(t, i)
            continue
        if t[i] == "[":
            profondeur += 1
        elif t[i] == "]":
            profondeur -= 1
            if profondeur == 0:
                return i + 1
        i += 1
    raise ErreurTexte("crochet non fermé")


def lire_valeur(t: str, i: int = 0) -> tuple[Any, int]:
    """Lit une valeur à partir de t[i]. Renvoie (valeur JSON typée, position de fin)."""
    i = _espaces(t, i)
    if i >= len(t):
        raise ErreurTexte("valeur attendue")
    c = t[i]
    if c == '"':
        return _lire_chaine(t, i)
    if c == "&" and t[i + 1:i + 2] == '"':
        s, j = _lire_chaine(t, i + 1)
        return {"StringName": s}, j
    if c == "^" and t[i + 1:i + 2] == '"':
        s, j = _lire_chaine(t, i + 1)
        return {"NodePath": s}, j
    if c == "[":
        return _lire_liste(t, i + 1, "]")
    if c == "{":
        paires, j = _lire_dictionnaire(t, i + 1)
        return {"Dictionary": paires}, j
    m = _NOMBRE.match(t, i)
    if m and (c.isdigit() or c in "-."):
        texte = m.group()
        if c == "-" and t.startswith("-inf", i):
            return {"float": "-inf"}, i + 4
        if any(x in texte for x in ".eE"):
            return float(texte), m.end()
        return int(texte), m.end()
    if c == "-" and t.startswith("-inf", i):
        return {"float": "-inf"}, i + 4
    m = _IDENT.match(t, i)
    if not m:
        raise ErreurTexte(f"caractère inattendu {c!r} à la position {i}")
    nom, j = m.group(), m.end()
    if nom in ("true", "false"):
        return nom == "true", j
    if nom == "null":
        return None, j
    if nom in ("inf", "nan", "inf_neg"):
        return {"float": "-inf" if nom == "inf_neg" else nom}, j
    if j < len(t) and t[j] == "[" and nom in ("Array", "Dictionary"):
        k = _crochets(t, j)
        type_texte = t[j:k]
        if "(" in type_texte:  # tableau typé par une ressource : on garde le texte brut
            raise ErreurTexte("type de tableau non pris en charge")
        nom = nom + type_texte
        j = k
    j2 = _espaces(t, j)
    if j2 >= len(t) or t[j2] != "(":
        raise ErreurTexte(f"identifiant isolé {nom!r}")
    if nom.startswith("Array["):
        k = _espaces(t, j2 + 1)
        if t[k] != "[":
            raise ErreurTexte("tableau typé : '[' attendu")
        elements, k = _lire_liste(t, k + 1, "]")
        k = _espaces(t, k)
        if t[k] != ")":
            raise ErreurTexte("tableau typé : ')' attendu")
        return {nom: elements}, k + 1
    if nom.startswith("Dictionary["):
        k = _espaces(t, j2 + 1)
        if t[k] != "{":
            raise ErreurTexte("dictionnaire typé : '{' attendu")
        paires, k = _lire_dictionnaire(t, k + 1)
        k = _espaces(t, k)
        if t[k] != ")":
            raise ErreurTexte("dictionnaire typé : ')' attendu")
        return {nom: paires}, k + 1
    if nom == "Object":
        raise ErreurTexte("Object(...) non pris en charge")
    arguments, k = _lire_liste(t, j2 + 1, ")")
    if nom in ("ExtResource", "SubResource", "NodePath", "StringName"):
        if len(arguments) != 1 or not isinstance(arguments[0], str):
            raise ErreurTexte(f"{nom} : un argument chaîne attendu")
        return {nom: arguments[0]}, k
    for a in arguments:
        if not isinstance(a, (int, float, str)) or isinstance(a, bool):
            if not (isinstance(a, dict) and "float" in a):
                raise ErreurTexte(f"{nom} : argument non scalaire")
    return {nom: arguments}, k


def lire_valeur_texte(texte: str) -> Any:
    """Décode une valeur complète ; repli sur {"godot": texte} si elle est illisible."""
    try:
        valeur, fin = lire_valeur(texte, 0)
        if texte[fin:].strip():
            raise ErreurTexte("texte après la valeur")
        return valeur
    except (ErreurTexte, IndexError, ValueError):
        return {"godot": texte.strip()}


# --------------------------------------------------------------------------- valeurs : écriture

def echapper(s: str) -> str:
    """Comme String.c_escape_multiline de Godot : seuls \\ et " sont échappés."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def ecrire_flottant(x: float) -> str:
    """Flottant isolé : toujours avec une partie décimale ou un exposant (6.0, 0.15, 1e-05)."""
    if math.isinf(x):
        return "inf" if x > 0 else "-inf"
    if math.isnan(x):
        return "nan"
    return repr(float(x))


def _composante(x: Any) -> str:
    """Composante d'un constructeur : Godot écrit 320 et non 320.0."""
    if isinstance(x, bool):
        raise ValueError("booléen dans un constructeur")
    if isinstance(x, dict) and "float" in x:
        return x["float"]
    if isinstance(x, float):
        texte = ecrire_flottant(x)
        return texte[:-2] if texte.endswith(".0") else texte
    if isinstance(x, int):
        return str(x)
    if isinstance(x, str):
        return echapper(x)
    raise ValueError(f"composante invalide : {x!r}")


def type_cle(valeur: dict) -> str:
    """Clé unique d'une valeur typée {"Vector2": [...]}."""
    if len(valeur) != 1:
        raise ValueError(f"valeur typée invalide (une seule clé attendue) : {valeur!r}")
    return next(iter(valeur))


def ecrire_valeur(v: Any) -> str:
    """Réécrit une valeur JSON typée en texte Godot 4.7."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return ecrire_flottant(v)
    if isinstance(v, str):
        return echapper(v)
    if isinstance(v, list):
        return "[" + ", ".join(ecrire_valeur(e) for e in v) + "]"
    if not isinstance(v, dict):
        raise ValueError(f"valeur non codable : {v!r}")
    cle = type_cle(v)
    contenu = v[cle]
    if cle == "godot":
        return str(contenu)
    if cle == "float":
        if contenu not in ("inf", "-inf", "nan"):
            raise ValueError(f"flottant spécial inconnu : {contenu!r}")
        return contenu
    if cle == "StringName":
        return "&" + echapper(contenu)
    if cle in ("NodePath", "ExtResource", "SubResource"):
        return f"{cle}({echapper(contenu)})"
    if cle == "Dictionary" or cle.startswith("Dictionary["):
        corps = "{}" if not contenu else "{\n" + ",\n".join(
            f"{ecrire_valeur(k)}: {ecrire_valeur(x)}" for k, x in contenu) + "\n}"
        return corps if cle == "Dictionary" else f"{cle}({corps})"
    if cle.startswith("Array["):
        return f"{cle}({ecrire_valeur(list(contenu))})"
    if not _IDENT.fullmatch(cle):
        raise ValueError(f"constructeur invalide : {cle!r}")
    if not isinstance(contenu, list):
        raise ValueError(f"{cle} : liste d'arguments attendue")
    return f"{cle}(" + ", ".join(_composante(x) for x in contenu) + ")"


def references(v: Any, cle: str) -> list[str]:
    """Toutes les valeurs {cle: ...} (ExtResource ou SubResource) contenues dans v, dans l'ordre."""
    trouvees: list[str] = []

    def parcourir(x: Any) -> None:
        if isinstance(x, list):
            for e in x:
                parcourir(e)
        elif isinstance(x, dict):
            k = type_cle(x) if len(x) == 1 else None
            if k == cle:
                trouvees.append(x[k])
            elif k == "Dictionary" or (k and k.startswith(("Dictionary[", "Array["))):
                parcourir(x[k])

    parcourir(v)
    return trouvees


def remplacer_references(v: Any, cle: str, table: dict) -> Any:
    """Copie de v où chaque {cle: x} devient {cle: table[x]} (x absent : inchangé)."""
    if isinstance(v, list):
        return [remplacer_references(e, cle, table) for e in v]
    if isinstance(v, dict) and len(v) == 1:
        k = type_cle(v)
        if k == cle:
            x = v[k]
            return {k: table.get(x, x) if isinstance(x, str) else x}
        if k == "Dictionary" or k.startswith(("Dictionary[", "Array[")):
            return {k: remplacer_references(v[k], cle, table)}
    return v


# --------------------------------------------------------------------------- document sans perte

@dataclass
class Entree:
    """Une ligne (ou plusieurs, pour une valeur sur plusieurs lignes) du corps d'une section."""
    brut: str                      # texte exact, fin de ligne comprise
    cle: str | None = None         # None : ligne vide, commentaire, texte non reconnu
    valeur_brute: str = ""

    @property
    def valeur(self) -> Any:
        return lire_valeur_texte(self.valeur_brute)


@dataclass
class Section:
    balise: str                                    # gd_scene, ext_resource, node…
    attributs: list[tuple[str, str]]               # (clé, valeur brute) dans l'ordre du fichier
    entete_brut: str                               # "[node ...]" + fin de ligne
    entrees: list[Entree] = field(default_factory=list)

    def attribut(self, cle: str, defaut: Any = None) -> Any:
        for k, brut in self.attributs:
            if k == cle:
                return lire_valeur_texte(brut)
        return defaut

    def a_attribut(self, cle: str) -> bool:
        return any(k == cle for k, _ in self.attributs)

    def definir_attribut(self, cle: str, valeur: Any, apres: str | None = None) -> None:
        """Change ou ajoute un attribut ; seul l'en-tête est réécrit."""
        brut = ecrire_valeur(valeur)
        for n, (k, _) in enumerate(self.attributs):
            if k == cle:
                self.attributs[n] = (cle, brut)
                break
        else:
            position = len(self.attributs)
            if apres is not None:
                for n, (k, _) in enumerate(self.attributs):
                    if k == apres:
                        position = n + 1
            self.attributs.insert(position, (cle, brut))
        self._reecrire_entete()

    def retirer_attribut(self, cle: str) -> None:
        self.attributs = [(k, b) for k, b in self.attributs if k != cle]
        self._reecrire_entete()

    def _reecrire_entete(self) -> None:
        fin = self.entete_brut[len(self.entete_brut.rstrip("\r\n")):] or "\n"
        self.entete_brut = "[" + " ".join([self.balise] + [f"{k}={b}" for k, b in self.attributs]) + "]" + fin

    # --- propriétés du corps
    def proprietes(self) -> list[Entree]:
        return [e for e in self.entrees if e.cle is not None]

    def propriete(self, cle: str) -> Entree | None:
        for e in self.entrees:
            if e.cle == cle:
                return e
        return None

    def definir_propriete(self, cle: str, valeur_brute: str, avant: str | None = None,
                          fin_ligne: str = "\n") -> None:
        """Remplace la ligne de `cle`, ou l'insère (avant la ligne `avant`, sinon après la dernière propriété)."""
        nouvelle = Entree(f"{cle} = {valeur_brute}{fin_ligne}", cle, valeur_brute)
        for n, e in enumerate(self.entrees):
            if e.cle == cle:
                self.entrees[n] = nouvelle
                return
        position = None
        if avant is not None:
            for n, e in enumerate(self.entrees):
                if e.cle == avant:
                    position = n
                    break
        if position is None:
            position = 0
            for n, e in enumerate(self.entrees):
                if e.cle is not None:
                    position = n + 1
        self.entrees.insert(position, nouvelle)

    def retirer_propriete(self, cle: str) -> bool:
        avant = len(self.entrees)
        self.entrees = [e for e in self.entrees if e.cle != cle]
        return len(self.entrees) != avant

    # --- lignes vides de fin (séparation avec la section suivante)
    def lignes_finales(self) -> int:
        n = 0
        for e in reversed(self.entrees):
            if e.cle is None and not e.brut.strip():
                n += 1
            else:
                break
        return n

    def fixer_lignes_finales(self, n: int, fin_ligne: str = "\n") -> None:
        k = self.lignes_finales()
        if k:
            del self.entrees[-k:]
        self.entrees.extend(Entree(fin_ligne) for _ in range(n))

    def texte(self) -> str:
        return self.entete_brut + "".join(e.brut for e in self.entrees)


def _decouper_lignes(texte: str) -> list[str]:
    return texte.splitlines(keepends=True)


def _lire_entete(texte: str, debut: int) -> tuple[str, list[tuple[str, str]], int]:
    """En-tête [balise cle=valeur ...] à partir de texte[debut] == '['. Renvoie (balise, attributs, fin)."""
    i = debut + 1
    m = _IDENT.match(texte, i)
    if not m:
        raise ErreurTexte(f"balise de section attendue à la position {i}")
    balise, i = m.group(), m.end()
    attributs: list[tuple[str, str]] = []
    while True:
        i = _espaces(texte, i)
        if i >= len(texte):
            raise ErreurTexte("en-tête de section non fermé")
        if texte[i] == "]":
            return balise, attributs, i + 1
        m = re.compile(r"[A-Za-z_][A-Za-z0-9_/]*").match(texte, i)
        if not m:
            raise ErreurTexte(f"attribut attendu à la position {i}")
        cle = m.group()
        i = _espaces(texte, m.end())
        if texte[i] != "=":
            raise ErreurTexte(f"'=' attendu après {cle}")
        debut_valeur = _espaces(texte, i + 1)
        _, fin_valeur = lire_valeur(texte, debut_valeur)
        attributs.append((cle, texte[debut_valeur:fin_valeur]))
        i = fin_valeur


_LIGNE_PROPRIETE = re.compile(r"^([^\s=\[;#][^=]*?)\s*=\s*")


@dataclass
class Document:
    """Fichier .tscn ou .tres découpé en sections, sans perte."""
    preambule: str
    sections: list[Section]

    def texte(self) -> str:
        return self.preambule + "".join(s.texte() for s in self.sections)

    def fin_ligne(self) -> str:
        return "\r\n" if "\r\n" in (self.sections[0].entete_brut if self.sections else self.preambule) else "\n"

    def de_balise(self, balise: str) -> list[Section]:
        return [s for s in self.sections if s.balise == balise]

    def index(self, section: Section) -> int:
        for n, s in enumerate(self.sections):
            if s is section:
                return n
        raise ValueError("section absente du document")


def lire_document(texte: str) -> Document:
    """Découpe un fichier de ressource texte Godot en sections ; texte() rend les mêmes octets."""
    sections: list[Section] = []
    i = 0
    n = len(texte)
    preambule_fin = 0
    # Préambule : tout ce qui précède la première ligne commençant par '['.
    while i < n and not texte.startswith("[", i):
        j = texte.find("\n", i)
        i = n if j < 0 else j + 1
    preambule_fin = i
    while i < n:
        debut = i
        balise, attributs, fin_entete = _lire_entete(texte, i)
        j = texte.find("\n", fin_entete)
        fin_ligne = n if j < 0 else j + 1
        section = Section(balise, attributs, texte[debut:fin_ligne])
        i = fin_ligne
        while i < n and not texte.startswith("[", i):
            j = texte.find("\n", i)
            fin = n if j < 0 else j + 1
            ligne = texte[i:fin]
            m = _LIGNE_PROPRIETE.match(ligne)
            if m:
                debut_valeur = i + m.end()
                try:
                    _, fin_valeur = lire_valeur(texte, debut_valeur)
                    k = texte.find("\n", fin_valeur)
                    fin = n if k < 0 else k + 1
                    valeur_brute = texte[debut_valeur:fin_valeur]
                except (ErreurTexte, IndexError, ValueError):
                    valeur_brute = ligne[m.end():].rstrip("\r\n")
                section.entrees.append(Entree(texte[i:fin], m.group(1).strip(), valeur_brute))
            else:
                section.entrees.append(Entree(ligne))
            i = fin
        sections.append(section)
    return Document(texte[:preambule_fin], sections)
