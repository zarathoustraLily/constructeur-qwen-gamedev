"""Vérifier l'API de Godot 4.7.2 : signatures (extension_api.json du binaire 4.7.2) et descriptions
(référence des classes du dépôt de Godot, étiquette 4.7.2-stable ; fonctions de shader : doc stable)."""
from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from functools import lru_cache

from usine.cours.base import chemins

SHADERS = "tutorials/shaders/shader_reference/shader_functions.rst"
BANALES = {"range", "len", "str", "print", "preload", "load", "assert", "is_instance_valid", "int", "float", "bool",
           "push_error", "push_warning", "printerr", "print_rich", "typeof", "type_string", "char", "ord"}
BANALES_SHADER = {"vec2", "vec3", "vec4", "float", "int", "bool", "mat3", "mat4", "uint", "ivec2", "ivec3", "bvec3"}


@lru_cache(maxsize=1)
def _api() -> dict:
    api = chemins.actuels().api
    if not api.is_file():
        from usine.vocab.construire import extraire_api
        extraire_api(api)
    d = json.loads(api.read_text(encoding="utf-8"))
    classes = {c["name"]: c for c in d["classes"]}
    builtins = {c["name"]: c for c in d["builtin_classes"]}
    utilitaires = {f["name"]: f for f in d["utility_functions"]}
    return {"classes": classes, "builtins": builtins, "utilitaires": utilitaires}


def _type(t: dict | None) -> str:
    if not t:
        return "void"
    return t.get("type", "void")


def _t(t: str) -> str:
    t = re.sub(r"^typedarray::(.+)$", r"Array[\1]", t or "")
    return re.sub(r"^(enum|bitfield)::", "", t)


def _args(m: dict) -> str:
    morceaux = []
    for a in m.get("arguments", []) or []:
        s = f"{a['name']}: {_t(a['type'])}"
        if "default_value" in a:
            s += f" = {a['default_value']}"
        morceaux.append(s)
    if m.get("is_vararg"):
        morceaux.append("...")
    return ", ".join(morceaux)


def classe_existe(nom: str) -> bool:
    a = _api()
    return nom in a["classes"] or nom in a["builtins"]


def _chaine(nom: str) -> list[str]:
    a = _api()
    chaine = []
    while nom and nom in a["classes"]:
        chaine.append(nom)
        nom = a["classes"][nom].get("inherits", "")
    return chaine or ([nom] if nom in a["builtins"] else [])


def membre(classe: str, nom: str) -> tuple[str, str] | None:
    """(signature, classe d'origine) d'un membre, héritage compris ; None s'il n'existe pas."""
    a = _api()
    for c in _chaine(classe):
        info = a["classes"].get(c) or a["builtins"].get(c)
        for m in info.get("methods", []) or []:
            if m["name"] == nom:
                ret = _t(_type(m.get("return_value")) if "return_value" in m else m.get("return_type", "void"))
                statique = "static " if m.get("is_static") else ""
                return f"{statique}{c}.{nom}({_args(m)}) -> {ret}", c
        for p in info.get("properties", []) or []:
            if p["name"] == nom:
                return f"{c}.{nom}: {_type_propriete(c, nom, p['type'])}", c
        for p in info.get("members", []) or []:
            if p["name"] == nom:
                return f"{c}.{nom}: {p['type']}", c
        for s in info.get("signals", []) or []:
            if s["name"] == nom:
                return f"signal {c}.{nom}({_args(s)})", c
        for k in info.get("constants", []) or []:
            if k["name"] == nom:
                return f"{c}.{nom}", c
        for e in info.get("enums", []) or []:
            if e["name"] == nom:
                return f"enum {c}.{nom}", c
            for v in e.get("values", []) or []:
                if v["name"] == nom:
                    return f"{c}.{e['name']}.{nom} = {v['value']}", c
    return None


def _type_propriete(classe: str, nom: str, brut: str) -> str:
    """Le type d'une propriété tel que l'écrit la référence : l'énumération si c'en est une
    (`MultiMesh.TransformFormat` plutôt que `int`), la classe déclarée plutôt que la liste de classes
    acceptées par l'inspecteur (`Material` plutôt que `BaseMaterial3D,ShaderMaterial`)."""
    racine = _xml(classe)
    if racine is not None:
        for e in racine.findall("members/member"):
            if e.get("name") == nom:
                if e.get("enum"):
                    return e.get("enum")
                if "," in brut and e.get("type"):
                    return e.get("type")
    return _t(brut)


def utilitaire(nom: str) -> str | None:
    f = _api()["utilitaires"].get(nom)
    if not f:
        return None
    return f"{nom}({_args(f)}) -> {f.get('return_type', 'void')}"


@lru_cache(maxsize=None)
def _xml(classe: str) -> ET.Element | None:
    ch = chemins.actuels()
    chemin = ch.gdscript_xml if classe == "@GDScript" else ch.classes / f"{classe}.xml"
    try:
        return ET.parse(chemin).getroot()
    except (FileNotFoundError, ET.ParseError):
        return None


def _premiere_phrase(texte: str) -> str:
    texte = re.sub(r"\s+", " ", (texte or "").strip())
    texte = re.sub(r"\[(?:member|method|constant|signal|enum|param|code|annotation) ([^\]]+)\]", r"\1", texte)
    texte = re.sub(r"\[/?(?:b|i|code|codeblock|codeblocks|gdscript|csharp|kbd)\]", "", texte)
    texte = re.sub(r"\[url=[^\]]*\]([^\[]*)\[/url\]", r"\1", texte)
    texte = re.sub(r"\[([A-Za-z@][\w.]*)\]", r"\1", texte)
    # « i.e. », « e.g. », « etc. » ne finissent pas la phrase.
    texte = re.sub(r"\b(i\.e|e\.g|etc|vs|cf)\.", lambda a: a.group(0).replace(".", "\x00"), texte, flags=re.I)
    m = re.match(r"(.+?[.!?])(\s|$)", texte)
    return (m.group(1) if m else texte)[:300].replace("\x00", ".")


def description_classe(classe: str) -> str:
    racine = _xml(classe)
    if racine is None:
        return ""
    return _premiere_phrase(racine.findtext("brief_description") or "")


def description_membre(classe: str, nom: str) -> str:
    for c in _chaine(classe) or [classe]:
        racine = _xml(c)
        if racine is None:
            continue
        for chemin in ("methods/method", "members/member", "signals/signal", "constants/constant"):
            for e in racine.findall(chemin):
                if e.get("name") == nom:
                    texte = e.findtext("description") if e.find("description") is not None else e.text
                    return _premiere_phrase(texte or "")
    return ""


def description_utilitaire(nom: str) -> str:
    racine = _xml("@GlobalScope")
    if racine is not None:
        for e in racine.findall("methods/method"):
            if e.get("name") == nom:
                return _premiere_phrase(e.findtext("description") or "")
    return ""


TYPE_DECL = re.compile(r"\b(\w+)\s*:\s*([A-Z]\w*)\b")
NEW = re.compile(r"\b(\w+)\s*(?::\s*\w+)?\s*=\s*([A-Z]\w*)\.new\(")


def usages_gdscript(nouvelles: list[str], fichier_complet: str) -> list[tuple[str, str]]:
    """(signature vérifiée, description) des classes et membres Godot employés dans les lignes nouvelles."""
    types: dict[str, str] = {}
    for nom, t in TYPE_DECL.findall(fichier_complet):
        if classe_existe(t):
            types.setdefault(nom, t)
    for nom, t in NEW.findall(fichier_complet):
        if classe_existe(t):
            types.setdefault(nom, t)
    code = "\n".join(l.split("#", 1)[0] if not l.strip().startswith("#") else "" for l in nouvelles)
    vus: dict[str, tuple[str, str]] = {}
    for c, m in re.findall(r"\b([A-Z]\w*)\.(\w+)", code):
        if classe_existe(c):
            r = membre(c, m)
            if r:
                vus.setdefault(r[0], (r[0], description_membre(r[1], m)))
    for v, m in re.findall(r"\b([a-z_]\w*)\.(\w+)", code):
        t = types.get(v)
        if t:
            r = membre(t, m)
            if r:
                vus.setdefault(r[0], (r[0], description_membre(r[1], m)))
    for c in set(re.findall(r"\b([A-Z]\w*)\b", code)):
        if c in _api()["classes"] and not any(s.startswith(c + ".") or f" {c}." in s for s in vus):
            vus.setdefault(c, (f"classe {c} (hérite de {' < '.join(_chaine(c)[1:]) or '—'})", description_classe(c)))
    for f in set(re.findall(r"(?<![.\w])([a-z_]\w*)\s*\(", code)):
        if f in BANALES:
            continue
        s = utilitaire(f)
        if s:
            vus.setdefault(s, (s, description_utilitaire(f)))
    return sorted(vus.values())


@lru_cache(maxsize=1)
def _fonctions_shader() -> dict[str, list[tuple[str, str]]]:
    table: dict[str, list[tuple[str, str]]] = {}
    lignes = (chemins.actuels().docs_godot / SHADERS).read_text(encoding="utf-8").split("\n")
    for k, ligne in enumerate(lignes):
        m = re.search(r":ref:`(\w+)<shader_func_\w+>`\\ \(\\ ?([^)]*)\)\s*\|\s*(.*?)\s*\|\s*$", ligne)
        if not m:
            continue
        nom, args, desc = m.group(1), m.group(2), m.group(3)
        # Une cellule de description peut continuer sur les lignes suivantes (colonnes de gauche vides).
        j = k + 1
        while j < len(lignes):
            suite = re.match(r"^\s*\|(?:\s*\|)?\s+\|\s+\|\s*(.+?)\s*\|\s*$", lignes[j]) or \
                re.match(r"^\s*\|\s+\|\s+\|\s*(.+?)\s*\|\s*$", lignes[j])
            if not suite or ":ref:" in lignes[j]:
                break
            desc = (desc + " " + suite.group(1)).strip()
            j += 1
        args = re.sub(r"\|(\w+)\|", r"\1", args).replace("\\ ", "").strip()
        desc = re.sub(r"``([^`]+)``", r"\1", desc).strip()
        table.setdefault(nom, []).append((f"{nom}({args})", desc))
    return table


def usages_shader(nouvelles: list[str]) -> list[tuple[str, str]]:
    code = "\n".join(l.split("//", 1)[0] for l in nouvelles)
    table = _fonctions_shader()
    vus: list[tuple[str, str]] = []
    for f in sorted(set(re.findall(r"(?<![.\w])([a-z]\w*)\s*\(", code))):
        if f in BANALES_SHADER or f not in table:
            continue
        sig, desc = table[f][0]
        desc = desc or next((d for _, d in table[f] if d), "")
        vus.append((sig, desc))
    return vus
