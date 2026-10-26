"""Nos sources vérifiées pour le RAG : les cours (notes en français et code) et les fiches de plugins.

- Notes : le README de chaque projet d'étape fabriqué (`donnees/cours/<cours>/projets/<projet>/README.md`), un
  fragment par point (« ### N. Titre »), genre « cours ». Elles expliquent en français chaque classe en situation.
- Code : le dernier projet d'étape de chaque cours (et de chaque ville pour les bâtiments), vérifié par Godot 4.7.2
  avec les avertissements en erreurs : scripts découpés par fonction, shaders entiers, genre « exemple ».
  `addons/` n'entre pas : ce n'est pas notre code.
- Plugins : `rag/plugins/<id>/fiche.md`, un fragment par section, genre « plugin », et l'exemple vérifié
  (`exemple/exemple.gd`), genre « exemple ».
- Effets : `rag/effets/<id>/fiche.md`, un fragment par section, genre « effet », et l'exemple vérifié par ses pixels
  (shaders et `exemple/exemple.gd`), genre « exemple ».
- Morceaux de code : `rag/morceaux/<id>/fiche.md`, genre « morceau », et l'exemple vérifié par son comportement
  (scripts du morceau et `exemple/exemple.gd`), genre « exemple ».

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


def sections(texte: str) -> list[str]:
    """Coupe une fiche à ses titres « ## » : l'en-tête, puis chaque section sans son « ## ». Un « ## » dans un bloc
    de code (commentaire de documentation GDScript) n'est pas un titre."""
    morceaux = [[]]
    dans_code = False
    for ligne in texte.splitlines(keepends=True):
        if ligne.startswith("```"):
            dans_code = not dans_code
        if not dans_code and ligne.startswith("## "):
            morceaux.append([ligne[3:]])
        else:
            morceaux[-1].append(ligne)
    return ["".join(m) for m in morceaux]


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
        morceaux = sections(texte)
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


SECTIONS_DE_CODE = ("Le shader", "Le code", "Le piloter", "L'employer")


def fragments_catalogue(nom: str, genre: str, dossier: Path | None = None) -> tuple[list[Fragment], dict[str, int]]:
    """Fiches d'un catalogue vérifié (`rag/effets/`, `rag/morceaux/`) : un fragment par section, du genre du catalogue ;
    leur code vient des fichiers vérifiés, indexés une seule fois en genre « exemple » (shaders entiers, scripts
    découpés par fonction). Les sections de la fiche qui recopient ce code n'entrent donc pas une seconde fois."""
    dossier = Path(dossier or cfg.RACINE / "rag" / nom)
    fragments: list[Fragment] = []
    compte = {nom: 0, "sections": 0, "shaders": 0, "scripts": 0}
    for fiche in sorted(dossier.glob("*/fiche.md")):
        ident = fiche.parent.name
        texte = fiche.read_text(encoding="utf-8")
        titre_fiche = texte.splitlines()[0].lstrip("# ").strip()
        source = f"rag/{nom}/{ident}/fiche.md"
        parties = sections(texte)
        fragments.append(Fragment(source, titre_fiche, f"{genre} {titre_fiche}", _coupe(parties[0].strip()), genre))
        for m in parties[1:]:
            titre, _, corps = m.partition("\n")
            if titre.startswith(SECTIONS_DE_CODE):
                continue
            fragments.append(Fragment(source, titre_fiche, f"{genre} {titre_fiche} › {titre.strip()}",
                                      _coupe(f"# {genre} {titre_fiche}\n{corps.strip()}"), genre))
            compte["sections"] += 1
        exemple = fiche.parent / "exemple"
        for fichier in sorted(p for p in exemple.rglob("*") if p.is_file()):
            rel = fichier.relative_to(exemple).as_posix()
            code = fichier.read_text(encoding="utf-8")
            if fichier.suffix in SHADERS:
                fragments.append(Fragment(f"rag/{nom}/{ident}/exemple/{rel}", f"{genre} vérifié {titre_fiche}",
                                          f"{titre_fiche} › {rel}",
                                          _coupe(f"// {genre} vérifié {titre_fiche} — res://exemple/{rel}\n{code}"),
                                          "exemple"))
                compte["shaders"] += 1
            elif fichier.suffix == ".gd":
                fragments += fragments_script(ident, f"res://exemple/{rel}", code, prefixe=f"rag/{nom}",
                                              etiquette=f"exemple vérifié ({genre} {titre_fiche}),")
                compte["scripts"] += 1
        compte[nom] += 1
    return fragments, compte


def fragments_effets(dossier: Path | None = None) -> tuple[list[Fragment], dict[str, int]]:
    return fragments_catalogue("effets", "effet", dossier)


def fragments_morceaux(dossier: Path | None = None) -> tuple[list[Fragment], dict[str, int]]:
    return fragments_catalogue("morceaux", "morceau", dossier)
