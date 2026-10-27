"""Les preuves citées dans les exemples de débogage : chaque citation est relue dans son fichier source."""
from __future__ import annotations

import re

from usine.cours.base import chemins

SOURCE_RENOMS = "la table des renommages de Godot 3 à Godot 4 du moteur (`editor/project_upgrade/renames_map_3_to_4.cpp`, Godot 4.7.2)"


def _doc(chemin: str, texte: str) -> str:
    contenu = (chemins.actuels().docs_godot / chemin).read_text(encoding="utf-8")
    assert texte in contenu, (chemin, texte)
    propre = re.sub(r"``([^`]+)``", r"`\1`", re.sub(r"\s+", " ", texte))
    return propre


def renommage(ancien: str, neuf: str) -> str | None:
    """La ligne de la table du moteur, telle quelle, ou None si la paire n'y est pas."""
    for ligne in chemins.actuels().renommages.read_text(encoding="utf-8").splitlines():
        if re.search(rf'\{{ "{re.escape(ancien)}", "{re.escape(neuf)}" \}}', ligne):
            return ligne.strip().split("//")[0].strip().rstrip(",")
    return None


DOC_EXPORT = ("GDScript exported properties", "tutorials/scripting/gdscript/gdscript_exports.rst",
              "Exporting is done by using\nthe ``@export`` annotation.")
DOC_ONREADY = ("GDScript reference", "tutorials/scripting/gdscript/gdscript_basics.rst",
               "GDScript has the ``@onready`` annotation, that\ndefers initialization of a member variable until ``_ready()`` is called.")
DOC_UNTYPED = ("Static typing in GDScript", "tutorials/scripting/gdscript/static_typing.rst",
               "You can enable the ``UNTYPED_DECLARATION`` warning if you want to always use\nstatic types.")
DOC_CAST = ("Shading language", "tutorials/shaders/shader_reference/shading_language.rst",
            "Just like GLSL ES 3.0, implicit casting between scalars and vectors of the same\nsize but different type is not allowed.")
DOC_ERREURS = ("GDScript warning system", "tutorials/scripting/gdscript/warning_system.rst",
               "errors if you'd like. This way your game won't compile unless you fix")


# La référence des classes (dépôt de Godot, étiquette 4.7.2-stable) : (classe, membre, texte exact, BBCode compris).
REF_UNTYPED = ("ProjectSettings", "debug/gdscript/warnings/untyped_declaration",
               "When set to [b]Warn[/b] or [b]Error[/b], produces a warning or an error respectively when a variable or "
               "parameter has no static type, or if a function has no static return type.")
REF_GET_NODE = ("Node", "get_node", "If [param path] does not point to a valid node, generates an error and returns "
                "[code]null[/code].")


def citation_reference(ref: tuple[str, str, str]) -> str:
    """Une phrase de la référence des classes, relue dans son fichier XML, sans son BBCode."""
    classe, membre, texte = ref
    contenu = (chemins.actuels().classes / f"{classe}.xml").read_text(encoding="utf-8")
    assert texte in contenu, (classe, membre, texte)
    propre = re.sub(r"\[param (\w+)\]", r"\1", re.sub(r"\[/?(?:b|code)\]", "", texte))
    return f"Référence de `{classe}` (Godot 4.7.2), `{membre}` : « {propre} »"


def citation(doc: tuple[str, str, str]) -> str:
    titre, chemin, texte = doc
    return f"*{titre}* (documentation de Godot) : « {_doc(chemin, texte)} »"


def renommage_de(ancien: str) -> tuple[str, str] | None:
    """(ligne de la table, nouveau nom) pour un nom de Godot 3, ou None."""
    for ligne in chemins.actuels().renommages.read_text(encoding="utf-8").splitlines():
        m = re.match(rf'\s*\{{ "{re.escape(ancien)}", "(\w+)" \}}', ligne)
        if m:
            return ligne.strip().split("//")[0].strip().rstrip(","), m.group(1)
    return None
