"""Nos sources vérifiées pour le RAG : les cours (notes en français et code) et les fiches de plugins.

- Notes : le README de chaque projet d'étape fabriqué (`donnees/cours/<cours>/projets/<projet>/README.md`), un
  fragment par point (« ### N. Titre »), genre « cours ». Elles expliquent en français chaque classe en situation.
- Code : le dernier projet d'étape de chaque cours (et de chaque ville pour les bâtiments), vérifié par Godot 4.7.2
  avec les avertissements en erreurs : scripts découpés par fonction, shaders entiers, genre « exemple ».
  `addons/` n'entre pas : ce n'est pas notre code.
- Plugins : `rag/plugins/<id>/fiche.md`, un fragment par section, genre « plugin », et l'exemple vérifié
  (`exemple/exemple.gd`), genre « exemple ».

Rien ne vient de Starfox ni des jeux gelés : l'index passe chaque fragment par `Exclusion.texte_exclu` (règle 4).
"""

from __future__ import annotations

import re
from pathlib import Path

from usine import config as cfg
from usine.rag.exemples import TAILLE_MAX, fragments_script
from usine.rag.rst import Fragment

RE_POINT = re.compile(r"^### (\d+\.\s+.+)$", re.M)
RE_ETAPE = re.compile(r"_etape_(\d+)$")
SHADERS = (".gdshader", ".gdshaderinc")


def _coupe(texte: str) -> str:
    return texte if len(texte) <= TAILLE_MAX else texte[:TAILLE_MAX].rsplit("\n", 1)[0] + "\n[…]"


def fragments_notes(readme: Path, cours: str) -> list[Fragment]:
    texte = readme.read_text(encoding="utf-8")
    projet = readme.parent.name
    titre_note = texte.splitlines()[0].lstrip("# ").strip() if texte else projet
    source = f"cours/{cours}/{projet}/README.md"
    fragments = []
    points = list(RE_POINT.finditer(texte))
    for i, m in enumerate(points):
        fin = points[i + 1].start() if i + 1 < len(points) else len(texte)
        corps = texte[m.end():fin]
        section = re.search(r"^## ", corps, re.M)
        corps = (corps[:section.start()] if section else corps).strip()
        if corps:
            fragments.append(Fragment(source, titre_note, f"{titre_note} › {m.group(1).strip()}",
                                      _coupe(f"# cours {cours}, {projet}\n{corps}"), "cours"))
    return fragments


def derniers_projets(donnees: Path) -> list[tuple[str, Path]]:
    """Le dernier projet d'étape de chaque cours ; pour les bâtiments, le dernier de chaque ville."""
    retenus: dict[tuple[str, str], Path] = {}
    for projet in sorted((donnees / "cours").glob("*/projets/*_etape_*")):
        cours = projet.parts[-3]
        famille = RE_ETAPE.sub("", projet.name)
        cle = (cours, famille)
        if cle not in retenus or projet.name > retenus[cle].name:
            retenus[cle] = projet
    return [(c, p) for (c, _), p in sorted(retenus.items())]


def fragments_code(projet: Path, cours: str) -> list[Fragment]:
    fragments = []
    for fichier in sorted(projet.rglob("*")):
        rel = fichier.relative_to(projet).as_posix()
        if not fichier.is_file() or rel.startswith(("addons/", ".godot/")):
            continue
        res = "res://" + rel
        if fichier.suffix == ".gd":
            fragments += fragments_script(projet.name, res, fichier.read_text(encoding="utf-8", errors="replace"),
                                          prefixe=f"cours/{cours}", etiquette="cours vérifié")
        elif fichier.suffix in SHADERS:
            texte = fichier.read_text(encoding="utf-8", errors="replace")
            fragments.append(Fragment(f"cours/{cours}/{projet.name}/{rel}", f"cours vérifié {projet.name}",
                                      f"{projet.name} › {fichier.name}",
                                      _coupe(f"// cours vérifié {projet.name} — {res}\n{texte}"), "exemple"))
    return fragments


def fragments_cours(donnees: Path | None = None) -> tuple[list[Fragment], dict[str, int]]:
    donnees = Path(donnees or cfg.dossier_donnees())
    fragments: list[Fragment] = []
    compte = {"notes": 0, "points": 0, "projets_code": 0, "fragments_code": 0}
    for readme in sorted((donnees / "cours").glob("*/projets/*/README.md")):
        f = fragments_notes(readme, readme.parts[-4])
        fragments += f
        compte["notes"] += 1
        compte["points"] += len(f)
    for cours, projet in derniers_projets(donnees):
        f = fragments_code(projet, cours)
        fragments += f
        compte["projets_code"] += 1
        compte["fragments_code"] += len(f)
    return fragments, compte


def fragments_plugins(dossier: Path | None = None) -> tuple[list[Fragment], dict[str, int]]:
    dossier = Path(dossier or cfg.RACINE / "rag" / "plugins")
    fragments: list[Fragment] = []
    compte = {"plugins": 0, "sections": 0}
    for fiche in sorted(dossier.glob("*/fiche.md")):
        ident = fiche.parent.name
        texte = fiche.read_text(encoding="utf-8")
        nom = texte.splitlines()[0].lstrip("# ").strip()
        source = f"rag/plugins/{ident}/fiche.md"
        morceaux = re.split(r"^## ", texte, flags=re.M)
        entete = morceaux[0].strip()
        fragments.append(Fragment(source, nom, f"plugin {nom}", _coupe(entete), "plugin"))
        for m in morceaux[1:]:
            titre, _, corps = m.partition("\n")
            fragments.append(Fragment(source, nom, f"plugin {nom} › {titre.strip()}",
                                      _coupe(f"# plugin {nom}\n{corps.strip()}"), "plugin"))
        exemple = fiche.parent / "exemple" / "exemple.gd"
        if exemple.is_file():
            fragments += fragments_script(ident, "res://exemple/exemple.gd", exemple.read_text(encoding="utf-8"),
                                          prefixe="rag/plugins", etiquette=f"exemple vérifié du plugin {nom},")
        compte["plugins"] += 1
        compte["sections"] += len(morceaux)
    return fragments, compte
