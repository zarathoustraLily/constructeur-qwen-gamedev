"""Filtre des symboles (décision 24 de laurent, 2026-11-18 : « on ajoute il faut que le lora soit solide »).

Une paire est refusée à l'assemblage quand le code que sa réponse ÉCRIT contient :

- un nom de Godot 3 : un nom ancien de `editor/project_upgrade/renames_map_3_to_4.cpp` (Godot 4.7.2, règle 5.2) qui
  n'existe plus nulle part dans `extension_api.json` 4.7.2 ni dans `@GDScript.xml`, et que la paire ne déclare pas
  elle-même (une fonction du projet peut s'appeler `instance`) ;
- un membre absent : `Classe.membre` où `Classe` est une classe, un type intégré, un singleton ou une énumération
  globale de l'API 4.7.2, et où `membre` n'est ni une méthode, ni une propriété, ni un signal, ni une constante, ni une
  énumération, ni une valeur d'énumération de la classe ou de ses parents.

Ce que la réponse écrit : les blocs de code de ses messages, sauf le texte à remplacer (règle 7.3 : la faute n'y
apparaît que comme texte à remplacer, juste après « remplace ») et les blocs de commande ou de sortie ; le `newString`
d'un `edit`, le `content` d'un `write`. Les explications en prose (« `rand_range` est le nom de Godot 3 ») ne comptent
pas. Les chaînes et les commentaires du code sont retirés avant la recherche.

Déterministe : aucun modèle, seulement la table de Godot et l'API.
"""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any

from usine import config as cfg

# Tables du fichier de Godot lues pour GDScript et pour les shaders.
TABLES_GDSCRIPT = ("enum_renames", "gdscript_function_renames", "gdscript_properties_renames",
                   "gdscript_signals_renames", "builtin_types_renames", "class_renames")
TABLES_SHADER = ("shaders_renames",)
ENTREE = re.compile(r'\{\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\}')
BLOC = re.compile(r"```([\w+-]*)[^\n]*\n(.*?)```", re.S)
ACCES = re.compile(r"(?<![\w.@$])([A-Z][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)")
MOT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
CLASSE_OU_APPEL = re.compile(r"(?<![\w.$%])([A-Z][A-Za-z0-9_]*\b|[a-z_][a-z0-9_]*(?=\s*\())")
CHEMIN_NOEUD = re.compile(r"[$%][A-Za-z_][\w/]*")
SHADER = re.compile(r"^\s*shader_type\b|^\s*(?:instance\s+|global\s+)?uniform\b|\bvoid\s+(?:fragment|vertex|light)\s*\(",
                    re.M)
DECLARE = re.compile(r"\b(?:func|var|const|signal|class_name|class|enum)\s+([A-Za-z_]\w*)")
# Membres que toute classe a sans qu'ils soient listés comme tels dans l'API.
TOUJOURS = {"new"}
LANGAGES_SHADER = {"gdshader", "glsl", "gdshaderinc", "shader"}
LANGAGES_GDSCRIPT = {"gdscript", "gd", ""}
SORTIE = re.compile(r"SCRIPT ERROR|^ERROR:|^WARNING:|^\s+at: |Godot Engine v|code de sortie", re.M)


@dataclass
class Api:
    """Les noms de l'API 4.7.2, par classe (parents compris) et à plat."""
    parents: dict[str, str | None] = field(default_factory=dict)
    membres: dict[str, set[str]] = field(default_factory=dict)
    tous: set[str] = field(default_factory=set)

    def a_membre(self, classe: str, membre: str) -> bool:
        vue: set[str] = set()
        nom: str | None = classe
        while nom and nom not in vue:
            vue.add(nom)
            if membre in self.membres.get(nom, set()):
                return True
            nom = self.parents.get(nom)
        return membre in TOUJOURS

    def connait(self, classe: str) -> bool:
        return classe in self.membres


def _noms_enums(enums: list[dict[str, Any]] | None) -> set[str]:
    noms: set[str] = set()
    for e in enums or []:
        noms.add(e["name"])
        noms.update(v["name"] for v in e.get("values", []))
    return noms


def lire_api(chemin: Path) -> Api:
    donnees = json.loads(chemin.read_text(encoding="utf-8"))
    api = Api()
    for c in donnees["classes"]:
        noms = {m["name"] for m in c.get("methods") or []} | {p["name"] for p in c.get("properties") or []}
        noms |= {s["name"] for s in c.get("signals") or []} | {k["name"] for k in c.get("constants") or []}
        noms |= _noms_enums(c.get("enums"))
        api.membres[c["name"]] = noms
        api.parents[c["name"]] = c.get("inherits")
    for c in donnees["builtin_classes"]:
        noms = {m["name"] for m in c.get("methods") or []} | {p["name"] for p in c.get("members") or []}
        noms |= {k["name"] for k in c.get("constants") or []} | _noms_enums(c.get("enums"))
        api.membres[c["name"]] = noms
        api.parents[c["name"]] = None
    for e in donnees["global_enums"]:
        # « Key.KEY_A », « MouseButton.MOUSE_BUTTON_LEFT » ; les énumérations à point (« Variant.Type ») restent hors
        # de cette vérification.
        if "." not in e["name"]:
            api.membres.setdefault(e["name"], set()).update(v["name"] for v in e.get("values", []))
            api.parents.setdefault(e["name"], None)
    for s in donnees["singletons"]:
        if s["name"] not in api.membres and s["type"] in api.membres:
            api.membres[s["name"]] = set(api.membres[s["type"]])
            api.parents[s["name"]] = api.parents.get(s["type"])
    api.tous = set(api.membres)
    for noms in api.membres.values():
        api.tous |= noms
    api.tous |= {f["name"] for f in donnees["utility_functions"]}
    api.tous |= {k["name"] for k in donnees["global_constants"]} | _noms_enums(donnees["global_enums"])
    return api


def lire_gdscript(chemin: Path) -> set[str]:
    """Fonctions et constantes de @GDScript (preload, len, PI…)."""
    racine = ET.parse(chemin).getroot()
    return {e.get("name", "") for e in racine.iter() if e.tag in ("method", "constant")}


def lire_renommages(chemin: Path, tables: tuple[str, ...]) -> dict[str, str]:
    """{ancien nom : nouveau} des tables demandées."""
    texte = chemin.read_text(encoding="utf-8")
    sortie: dict[str, str] = {}
    for table in tables:
        debut = texte.find(f"RenamesMap3To4::{table}[][2]")
        if debut < 0:
            raise ValueError(f"table {table} absente de {chemin}")
        fin = texte.find("};", debut)
        for ancien, neuf in ENTREE.findall(texte[debut:fin]):
            sortie.setdefault(ancien, neuf)
    return sortie


@dataclass
class Filtre:
    api: Api
    godot3: dict[str, str]          # GDScript : ancien nom absent de 4.7.2 → nom de Godot 4
    godot3_shader: dict[str, str]

    @classmethod
    def charger(cls, api: Path | None = None, source_godot: Path | None = None) -> "Filtre":
        return _charger(str(api or _chemin_api()), str(source_godot or _source_godot()))

    def verifier(self, paire: dict[str, Any]) -> list[str]:
        """Les fautes du code écrit par la réponse ; vide si la paire est propre."""
        declares = set(DECLARE.findall(_texte_paire(paire)))
        fautes: list[str] = []
        for langage, code in code_ecrit(paire):
            propre = _sans_chaines_ni_commentaires(code, shader=langage in LANGAGES_SHADER)
            if langage in LANGAGES_SHADER:
                for mot in set(MOT.findall(propre)):
                    if mot in self.godot3_shader and mot not in declares:
                        fautes.append(f"nom de Godot 3 (shader) : {mot} → {self.godot3_shader[mot]}")
                continue
            # Les noms de Godot 3 retenus : une classe (« Camera », « KinematicBody »), ou une fonction appelée sans
            # receveur (« rand_range( », « deg2rad( »). Un nom en minuscules sous un receveur (`_solver.add_force(`) ou
            # sans appel (`control`, `on`) est trop souvent un nom du projet, déclaré dans un autre fichier.
            for mot in set(CLASSE_OU_APPEL.findall(propre)):
                if mot in self.godot3 and mot not in declares:
                    fautes.append(f"nom de Godot 3 : {mot} → {self.godot3[mot]}")
            for classe, membre in set(ACCES.findall(propre)):
                if classe in declares or not self.api.connait(classe):
                    continue
                if not self.api.a_membre(classe, membre):
                    fautes.append(f"absent de l'API 4.7.2 : {classe}.{membre}")
        return sorted(set(fautes))


@lru_cache(maxsize=4)
def _charger(api: str, source_godot: str) -> Filtre:
    a = lire_api(Path(api))
    source = Path(source_godot)
    connus = a.tous | lire_gdscript(source / "modules/gdscript/doc_classes/@GDScript.xml")
    table = source / "editor/project_upgrade/renames_map_3_to_4.cpp"
    gd = {k: v for k, v in lire_renommages(table, TABLES_GDSCRIPT).items() if k not in connus and k != v}
    sh = {k: v for k, v in lire_renommages(table, TABLES_SHADER).items() if k != v}
    return Filtre(a, gd, sh)


def _chemin_api() -> Path:
    return Path(cfg.dossier_donnees()) / "vocab" / "extension_api_4.7.2.json"


def _source_godot() -> Path:
    valeur = cfg.charger_config().get("chemins", {}).get("source_godot")
    if not valeur:
        raise RuntimeError("[chemins].source_godot manque dans config.toml (table des renommages de Godot 3)")
    return Path(valeur)


def _texte_paire(paire: dict[str, Any]) -> str:
    morceaux: list[str] = []
    for m in paire["messages"]:
        morceaux.append(m.get("content") or "")
        for tc in m.get("tool_calls") or []:
            arguments = tc["function"]["arguments"]
            morceaux.append(json.dumps(arguments, ensure_ascii=False) if not isinstance(arguments, str) else arguments)
    return "\n".join(morceaux)


def _langage_fichier(chemin: str) -> str:
    if chemin.endswith((".gdshader", ".gdshaderinc")):
        return "gdshader"
    if chemin.endswith(".gd"):
        return "gdscript"
    return "autre"


def code_ecrit(paire: dict[str, Any]) -> list[tuple[str, str]]:
    """(langage, code) de tout ce que les messages de l'assistant écrivent."""
    sortie: list[tuple[str, str]] = []
    for m in paire["messages"]:
        if m["role"] != "assistant":
            continue
        texte = m.get("content") or ""
        for b in BLOC.finditer(texte):
            langage = b.group(1).lower()
            code = b.group(2)
            if langage not in LANGAGES_GDSCRIPT | LANGAGES_SHADER:
                continue
            # Le texte à remplacer : le bloc qui suit « … je remplace : » (règle 7.3).
            derniere = texte[:b.start()].rstrip().rsplit("\n", 1)[-1].lower()
            if re.search(r"\bremplace[^\n]*:$", derniere):
                continue
            # Un bloc sans langage qui est une commande ou une sortie de Godot.
            if langage == "" and (code.lstrip().startswith(("$", ">")) or SORTIE.search(code)):
                continue
            shader = langage in LANGAGES_SHADER or (langage in ("", "gdscript", "gd") and SHADER.search(code) is not None)
            sortie.append(("gdshader" if shader else "gdscript", code))
        for tc in m.get("tool_calls") or []:
            fonction = tc["function"]
            arguments = fonction["arguments"]
            if isinstance(arguments, str):
                try:
                    arguments = json.loads(arguments)
                except json.JSONDecodeError:
                    continue
            chemin = str(arguments.get("path") or arguments.get("filePath") or "")
            langage = _langage_fichier(chemin)
            if langage == "autre":
                continue
            if fonction["name"] == "edit":
                sortie.append((langage, str(arguments.get("newString", ""))))
            elif fonction["name"] == "write":
                sortie.append((langage, str(arguments.get("content", ""))))
    return sortie


_CHAINE = re.compile(r'"""(?:.|\n)*?"""|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'')


def _sans_chaines_ni_commentaires(code: str, shader: bool) -> str:
    """Le code sans ses chaînes (vidées : `""`) ni ses commentaires, lignes gardées."""
    sans = _CHAINE.sub('""', code)
    if shader:
        sans = re.sub(r"/\*.*?\*/", " ", sans, flags=re.S)
        return "\n".join(l.split("//", 1)[0] for l in sans.split("\n"))
    # Les StringName et NodePath (&"x", ^"x") ont été vidés avec les chaînes ; les chemins de nœud ($Arm/Camera,
    # %Light) sont des noms de la scène, pas des classes.
    return CHEMIN_NOEUD.sub(" ", "\n".join(l.split("#", 1)[0] for l in sans.split("\n")))
