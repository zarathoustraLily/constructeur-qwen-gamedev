"""Rendu intact, contrôle statique (compétence E) : rien de ce qui règle l'image n'a changé.

Comparé entre le candidat et la référence, par lecture des fichiers (sans Godot) :
  - project.godot : sections [display] (résolution, étirement) et [rendering] (filtres,
    environnement par défaut, 2D HDR…), clé par clé ;
  - dans chaque scène de la référence, les nœuds qui règlent l'image (lumières, occulteurs,
    CanvasModulate, WorldEnvironment, caméra, calques) : même chemin, mêmes propriétés,
    ressources internes (SubResource) comparées par contenu.

Le contrôle à l'exécution (signature de ce qui serait affiché, gd/mesurer_efficience.gd) couvre
le reste : textures, positions, couleurs, matériaux des éléments dessinés.
"""

from __future__ import annotations

import re
from pathlib import Path

from usine.scene.texte import Document, lire_document

SECTIONS_PROJET = ("display", "rendering")
TYPES_RENDU = ("PointLight2D", "DirectionalLight2D", "LightOccluder2D", "CanvasModulate", "WorldEnvironment",
               "Camera2D", "CanvasLayer", "BackBufferCopy", "ParallaxBackground", "ParallaxLayer")
_SUB = re.compile(r'SubResource\(\s*"([^"]+)"\s*\)')
_EXT = re.compile(r'ExtResource\(\s*"([^"]+)"\s*\)')


def _lire(chemin: Path) -> Document | None:
    if not chemin.is_file():
        return None
    return lire_document(chemin.read_text(encoding="utf-8", errors="replace"))


def reglages_projet(projet: Path) -> dict[str, dict[str, str]]:
    doc = _lire(Path(projet) / "project.godot")
    resultat: dict[str, dict[str, str]] = {s: {} for s in SECTIONS_PROJET}
    if doc is None:
        return resultat
    for section in doc.sections:
        if section.balise in SECTIONS_PROJET:
            for e in section.proprietes():
                resultat[section.balise][e.cle] = e.valeur_brute.strip()
    return resultat


def _resoudre(valeur: str, doc: Document, profondeur: int = 0) -> str:
    """Remplace les SubResource par leur contenu et les ExtResource par leur chemin."""
    if profondeur > 8:
        return valeur
    subs = {s.attribut("id"): s for s in doc.de_balise("sub_resource")}
    exts = {s.attribut("id"): s for s in doc.de_balise("ext_resource")}

    def sub(m: re.Match) -> str:
        s = subs.get(m.group(1))
        if s is None:
            return m.group(0)
        corps = ";".join(f"{e.cle}={_resoudre(e.valeur_brute.strip(), doc, profondeur + 1)}"
                         for e in sorted(s.proprietes(), key=lambda e: e.cle))
        return f"{s.attribut('type')}({corps})"

    def ext(m: re.Match) -> str:
        s = exts.get(m.group(1))
        return f'Ext("{s.attribut("path")}")' if s is not None else m.group(0)

    return _EXT.sub(ext, _SUB.sub(sub, valeur))


def noeuds_rendu(scene: Path) -> dict[str, dict[str, str]]:
    """{chemin du nœud: {propriété: valeur résolue}} pour les nœuds qui règlent l'image."""
    doc = _lire(scene)
    if doc is None:
        return {}
    resultat: dict[str, dict[str, str]] = {}
    for n in doc.de_balise("node"):
        if n.attribut("type") not in TYPES_RENDU:
            continue
        parent = n.attribut("parent")
        chemin = n.attribut("name") if parent is None else f"{parent}/{n.attribut('name')}"
        props = {e.cle: _resoudre(e.valeur_brute.strip(), doc) for e in n.proprietes() if e.cle != "script"}
        props["@type"] = n.attribut("type")
        resultat[chemin] = props
    return resultat


def _scenes(projet: Path) -> list[Path]:
    return sorted((p for p in Path(projet).rglob("*.tscn")
                   if not {"addons", ".godot", "tests", "tests_juge"} & set(p.relative_to(projet).parts)),
                  key=lambda p: p.relative_to(projet).parts)


def comparer(reference: Path, candidat: Path) -> list[str]:
    """Liste des écarts de rendu du candidat par rapport à la référence (vide : rendu intact)."""
    reference, candidat = Path(reference), Path(candidat)
    ecarts: list[str] = []
    ref, cand = reglages_projet(reference), reglages_projet(candidat)
    for section in SECTIONS_PROJET:
        for cle in sorted(set(ref[section]) | set(cand[section])):
            a, b = ref[section].get(cle), cand[section].get(cle)
            if a != b:
                ecarts.append(f"project.godot [{section}] {cle} : {a if a is not None else 'absent'} → "
                              f"{b if b is not None else 'absent'}")
    for scene in _scenes(reference):
        rel = scene.relative_to(reference).as_posix()
        attendu = noeuds_rendu(scene)
        if not attendu:
            continue
        obtenu = noeuds_rendu(candidat / rel)
        for chemin, props in sorted(attendu.items()):
            if chemin not in obtenu:
                ecarts.append(f"{rel} : nœud de rendu {chemin} ({props['@type']}) retiré")
                continue
            for cle in sorted(set(props) | set(obtenu[chemin])):
                if props.get(cle) != obtenu[chemin].get(cle):
                    ecarts.append(f"{rel} : {chemin}.{cle} : {props.get(cle, 'défaut')} → "
                                  f"{obtenu[chemin].get(cle, 'défaut')}")
    return ecarts
