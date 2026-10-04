"""Outils communs aux générateurs : lecture d'un projet source, écriture d'une tâche,
exécution d'un script GDScript de mesure dans une copie du projet.

Un générateur ne produit que des tâches candidates (format commun de usine/taches.py) :
c'est le portillon qui décide si elles sont acceptées. Règle 5 : une tâche fausse se
corrige dans le générateur, jamais à la main dans le dossier produit.
"""

from __future__ import annotations

import json
import random
import re
import shutil
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine import socle
from usine.juge import godot as juges
from usine.juge.projet import preparer_copie
from usine.processus import executer
from usine.taches import calculer_empreinte

SOURCE_REFERENCE = cfg.RACINE / "godot" / "reference"
EXCLUS = {"addons", ".godot", "reports", "__pycache__", ".import", ".usine_rapports"}
MARQUEUR = "@@USINE@@"


@dataclass
class Production:
    """Ce que rend un générateur : les dossiers de tâches écrits et les cas écartés (avec raison)."""
    taches: list[Path] = field(default_factory=list)
    ecartes: list[dict[str, Any]] = field(default_factory=list)

    def ecarter(self, generateur: str, ident: str, raison: str, detail: str = "") -> None:
        self.ecartes.append({"generateur": generateur, "id": ident, "raison": raison, "detail": detail})

    def etendre(self, autre: "Production") -> None:
        self.taches += autre.taches
        self.ecartes += autre.ecartes


def lire_projet(source: Path) -> dict[str, str]:
    """Fichiers texte du projet source (hors addons et caches) : {chemin relatif posix: texte}.

    Les fichiers .uid (non versionnés) sont ignorés. Les fichiers non textuels (sons, images,
    modèles, .import) restent dans le socle du projet (usine/socle.py) : le dictionnaire porte
    alors son nom sous la clé `.usine_socle`, et toute copie de travail les retrouve.
    """
    source = Path(source)
    fichiers = {}
    for f in sorted(source.rglob("*")):
        if not f.is_file():
            continue
        rel = f.relative_to(source)
        if EXCLUS & set(rel.parts) or f.suffix == ".uid":
            continue
        if rel.as_posix() != socle.MARQUEUR and not socle.est_texte(f):
            continue
        fichiers[rel.as_posix()] = f.read_text(encoding="utf-8")
    if socle.MARQUEUR not in fichiers:
        nom = socle.construire(source)
        if nom is not None:
            fichiers[socle.MARQUEUR] = nom + "\n"
    return fichiers


def nom_source(source: Path) -> str:
    return Path(source).name


def tests_regression(projet: dict[str, str]) -> dict[str, str]:
    """Les tests du projet (tests/…), à placer dans tests_caches/ (copiés dans res://tests_juge/)."""
    return {rel[len("tests/"):]: t for rel, t in projet.items() if rel.startswith("tests/")}


def scripts_jeu(projet: dict[str, str]) -> list[str]:
    return [rel for rel in projet if rel.endswith(".gd") and not rel.startswith("tests/")]


def scenes_jeu(projet: dict[str, str]) -> list[str]:
    return [rel for rel in projet if rel.endswith(".tscn") and not rel.startswith("tests/")]


def echantillon(elements: list[Any], plafond: int | None, cle: str) -> list[Any]:
    """Au plus `plafond` éléments, tirés avec une graine fixe ; ordre d'origine conservé."""
    if plafond is None or len(elements) <= plafond:
        return list(elements)
    choisis = set(random.Random(cle).sample(range(len(elements)), plafond))
    return [e for k, e in enumerate(elements) if k in choisis]


_REF_RES = re.compile(r'res://[^"\s)]+\.(?:gd|tscn)')
_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def identifiants_tests(projet: dict[str, str]) -> set[str]:
    """Identifiants qui apparaissent dans les tests du projet (noms de méthodes, de classes…)."""
    return {m for rel, t in projet.items() if rel.startswith("tests/") for m in _IDENT.findall(t)}


def fichiers_testes(projet: dict[str, str]) -> set[str]:
    """Scripts et scènes du jeu que les tests atteignent : par leur class_name, leur nom d'autoload, leur chemin
    res://, ou par une scène chargée dans les tests (et les scènes qu'elle instancie, de proche en
    proche). Approximation syntaxique, sans exécuter : sert seulement à ne pas gaspiller de
    jugements sur du code qu'aucun test ne peut voir ; le portillon reste l'autorité."""
    tests = "\n".join(t for rel, t in projet.items() if rel.startswith("tests/"))
    noms = identifiants_tests(projet)
    vus: set[str] = set()
    a_voir = [r[len("res://"):] for r in _REF_RES.findall(tests)]
    while a_voir:
        rel = a_voir.pop()
        if rel in vus or rel not in projet:
            continue
        vus.add(rel)
        if rel.endswith(".tscn"):
            a_voir += [r[len("res://"):] for r in _REF_RES.findall(projet[rel])]
    for nom, chemin in re.findall(r'^(\w+)="\*?res://([^"]+)"', projet.get("project.godot", ""), re.M):
        if nom in noms or f'"{nom}"' in tests:
            vus.add(chemin)
    for rel in scripts_jeu(projet):
        m = re.search(r"^class_name\s+(\w+)", projet[rel], re.M)
        if m and m.group(1) in noms:
            vus.add(rel)
    return {rel for rel in vus if rel.endswith((".gd", ".tscn")) and not rel.startswith("tests/")}


def scripts_testes(projet: dict[str, str]) -> set[str]:
    return {rel for rel in fichiers_testes(projet) if rel.endswith(".gd")}


def ident(*morceaux: Any) -> str:
    texte = "_".join(str(m) for m in morceaux if m != "")
    return re.sub(r"[^a-z0-9_]+", "_", texte.lower()).strip("_")


def _ecrire(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8", newline="\n")


def ecrire_tache(sortie: Path, tache: dict[str, Any], depart: dict[str, str], reference: dict[str, str],
                 tests_caches: dict[str, str]) -> Path:
    """Écrit donnees/…/<competence>/<id>/ et calcule l'empreinte. Remplace un dossier existant."""
    dossier = Path(sortie) / tache["competence"] / tache["id"]
    if dossier.exists():
        shutil.rmtree(dossier)
    for sous, fichiers in (("depart", depart), ("reference", reference), ("tests_caches", tests_caches)):
        (dossier / sous).mkdir(parents=True, exist_ok=True)
        for rel, texte in sorted(fichiers.items()):
            _ecrire(dossier / sous / rel, texte)
    tache = {"empreinte": "", "gelee": False, **tache}
    tache["empreinte"] = calculer_empreinte(dossier, tache)
    _ecrire(dossier / "tache.json", json.dumps(tache, ensure_ascii=False, indent=1) + "\n")
    return dossier


def ecrire_projet(fichiers: dict[str, str], destination: Path) -> Path:
    for rel, texte in fichiers.items():
        _ecrire(Path(destination) / rel, texte)
    return Path(destination)


def executer_gd(fichiers: dict[str, str], script: str, arguments: list[str] | None = None,
                delai_s: float = 300) -> tuple[list[Any], str]:
    """Écrit le projet dans une copie jetable, y ajoute `script` (extends SceneTree) et le lance.

    Le script imprime ses résultats sur des lignes « @@USINE@@<json> ». Renvoie (résultats, sortie brute).
    """
    with tempfile.TemporaryDirectory(prefix="usine_gen_") as tmp:
        src = ecrire_projet(fichiers, Path(tmp) / "src")
        projet = preparer_copie(src, Path(tmp) / "projet")
        _ecrire(projet / "usine_mesure.gd", script)
        juges.importer(projet)
        res = executer([cfg.chemin_godot(), "--headless", "--path", projet, "-s", "res://usine_mesure.gd",
                        "--", *(arguments or [])], delai_s=delai_s)
    resultats = [json.loads(l[len(MARQUEUR):]) for l in res.sortie.splitlines() if l.startswith(MARQUEUR)]
    return resultats, res.sortie


def journal_execution(fichiers: dict[str, str]) -> str:
    """Sortie de Godot quand on lance le projet (3 images à pas fixe), chemins anonymisés (comme les D1 modèles)."""
    from usine.juge.verdict import sans_ansi
    with tempfile.TemporaryDirectory(prefix="usine_d1_") as tmp:
        src = ecrire_projet(fichiers, Path(tmp) / "src")
        projet = preparer_copie(src, Path(tmp) / "projet")
        juges.importer(projet)
        res = executer([cfg.chemin_godot(), "--headless", "--path", projet, "--fixed-fps", "60",
                        "--quit-after", "3"], delai_s=120)
        texte = sans_ansi(res.sortie).replace(str(projet), "<projet>")
    return texte.replace("\r\n", "\n")
