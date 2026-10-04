"""Format commun des tâches : lecture, empreinte, jugement, vérification des modèles.

    donnees/taches/<competence>/<id>/
      tache.json      {id, competence, consigne, origine, empreinte, gelee, juge?}
      depart/         projet Godot de départ (sans addons : GdUnit4 est injecté par le juge)
      reference/      solution : superposée à depart/ (fichiers ajoutés ou remplacés)
      tests_caches/   tests du juge, copiés dans res://tests_juge/ seulement au moment de juger

Champ optionnel `juge` de tache.json :
    etapes            sous-ensemble de import/check_script/load_scene/run_tests (défaut : toutes)
    patch_max_lignes  plafond de lignes +/- entre depart/ et le candidat (K3)
"""

from __future__ import annotations

import difflib
import hashlib
import json
import shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.juge.projet import DOSSIER_TESTS_JUGE, ETAPES, IGNORES_COPIE, juger_projet
from usine.juge.verdict import comparable, erreur, nouveau_verdict

SOUS_DOSSIERS = ("depart", "reference", "tests_caches")
CHAMPS_OBLIGATOIRES = ("id", "competence", "consigne", "origine", "empreinte", "gelee")
EXTENSIONS_TEXTE = {".gd", ".tscn", ".tres", ".godot", ".json", ".txt", ".md", ".cfg", ".gdshader"}


def lire_tache(dossier: Path) -> dict[str, Any]:
    tache = json.loads((Path(dossier) / "tache.json").read_text(encoding="utf-8"))
    manquants = [c for c in CHAMPS_OBLIGATOIRES if c not in tache]
    if manquants:
        raise ValueError(f"{dossier} : champs manquants dans tache.json : {manquants}")
    return tache


def _fichiers(dossier: Path) -> list[Path]:
    if not dossier.is_dir():
        return []
    return sorted(p for p in dossier.rglob("*") if p.is_file() and ".godot" not in p.relative_to(dossier).parts)


def calculer_empreinte(dossier: Path, tache: dict[str, Any] | None = None) -> str:
    """SHA-256 du contenu de la tâche (tache.json sans « empreinte » ni « gelee », plus les trois dossiers)."""
    dossier = Path(dossier)
    tache = dict(tache if tache is not None else lire_tache(dossier))
    tache.pop("empreinte", None)
    tache.pop("gelee", None)
    h = hashlib.sha256()
    h.update(json.dumps(tache, sort_keys=True, ensure_ascii=False).encode("utf-8"))
    for sous in SOUS_DOSSIERS:
        racine = dossier / sous
        for f in _fichiers(racine):
            h.update(f"\n{sous}/{f.relative_to(racine).as_posix()}\n".encode("utf-8"))
            h.update(hashlib.sha256(f.read_bytes()).hexdigest().encode("ascii"))
    return h.hexdigest()


def verifier_empreinte(dossier: Path) -> bool:
    tache = lire_tache(dossier)
    return tache["empreinte"] == calculer_empreinte(dossier, tache)


def _textes(projet: Path) -> dict[str, list[str]]:
    resultat = {}
    for f in _fichiers(projet):
        rel = f.relative_to(projet)
        if rel.parts[0] in ("addons", DOSSIER_TESTS_JUGE) or f.suffix not in EXTENSIONS_TEXTE:
            continue
        resultat[rel.as_posix()] = f.read_text(encoding="utf-8", errors="replace").splitlines()
    return resultat


def lignes_modifiees(avant: Path, apres: Path) -> int:
    """Nombre de lignes ajoutées ou retirées entre deux projets (fichiers texte, hors addons)."""
    a, b = _textes(Path(avant)), _textes(Path(apres))
    total = 0
    for chemin in sorted(set(a) | set(b)):
        for ligne in difflib.unified_diff(a.get(chemin, []), b.get(chemin, []), lineterm="", n=0):
            if ligne.startswith(("+", "-")) and not ligne.startswith(("+++", "---")):
                total += 1
    return total


def juger_tache(dossier: Path, version: str = "reference", candidat: Path | None = None,
                repetition: int | None = None) -> dict[str, Any]:
    """Juge une tâche : `depart`, `reference` (depart + superposition) ou un projet candidat.

    `repetition` (portillon) : passe par le cache des verdicts (usine.juge.cache), une clé par
    répétition ; None = jugement direct, sans cache.
    """
    dossier = Path(dossier)
    tache = lire_tache(dossier)
    regles = tache.get("juge", {})
    etapes = regles.get("etapes", list(ETAPES))
    if candidat is not None:
        source, superpositions = Path(candidat), []
    elif version == "depart":
        source, superpositions = dossier / "depart", []
    elif version == "reference":
        source, superpositions = dossier / "depart", [dossier / "reference"]
    else:
        raise ValueError(f"version inconnue : {version}")

    plafond = regles.get("patch_max_lignes")
    if plafond is not None:
        import tempfile
        with tempfile.TemporaryDirectory(prefix="usine_patch_") as tmp:
            projet = Path(tmp) / "p"
            shutil.copytree(source, projet, ignore=IGNORES_COPIE)
            for sup in superpositions:
                shutil.copytree(sup, projet, dirs_exist_ok=True, ignore=IGNORES_COPIE)
            taille = lignes_modifiees(dossier / "depart", projet)
        if taille > plafond:
            verdict = nouveau_verdict("taille_patch")
            verdict["erreurs"].append(erreur(f"patch de {taille} lignes, plafond {plafond}", categorie="autre"))
            verdict["tache_id"] = tache["id"]
            return verdict

    if repetition is not None:
        from usine.juge import cache
        verdict = cache.juger(source, superpositions, dossier / "tests_caches", etapes, repetition)
    else:
        verdict = juger_projet(source, f"res://{DOSSIER_TESTS_JUGE}", etapes, superpositions, dossier / "tests_caches")
    verdict["tache_id"] = tache["id"]
    return verdict


def lister_taches(racine: Path) -> list[Path]:
    return sorted(p.parent for p in Path(racine).glob("*/*/tache.json"))


def installer_modeles(source: Path | None = None, destination: Path | None = None) -> list[Path]:
    """Copie les tâches modèles versionnées vers donnees/taches/ après vérification d'empreinte."""
    source = Path(source) if source else cfg.RACINE / "godot" / "taches_modeles"
    destination = Path(destination) if destination else cfg.dossier_donnees() / "taches"
    copiees = []
    for dossier in lister_taches(source):
        if not verifier_empreinte(dossier):
            raise ValueError(f"empreinte invalide : {dossier}")
        cible = destination / dossier.relative_to(source)
        if cible.exists():
            shutil.rmtree(cible)
        shutil.copytree(dossier, cible)
        copiees.append(cible)
    return copiees


def _verifier_une(dossier: Path) -> dict[str, Any]:
    tache = lire_tache(dossier)
    res: dict[str, Any] = {"id": tache["id"], "competence": tache["competence"],
                           "empreinte_ok": tache["empreinte"] == calculer_empreinte(dossier, tache)}
    for version in ("depart", "reference"):
        v1 = juger_tache(dossier, version)
        v2 = juger_tache(dossier, version)
        res[version] = {
            "ok": v1["ok"],
            "etape": v1["etape"],
            "tests": v1["tests"],
            "stable": comparable(v1) == comparable(v2),
            "duree_s": [v1["duree_s"], v2["duree_s"]],
        }
    res["conforme"] = (res["empreinte_ok"] and not res["depart"]["ok"] and res["reference"]["ok"]
                       and res["depart"]["stable"] and res["reference"]["stable"])
    return res


def verifier_modeles(racine: Path, travailleurs: int = 2) -> bool:
    """Pour chaque tâche : FAIL sur depart, PASS sur reference, deux exécutions identiques."""
    dossiers = lister_taches(racine)
    with ThreadPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        resultats = list(pool.map(_verifier_une, dossiers))
    print(f"{'tâche':<28} {'départ':<34} {'référence':<26} stable  empreinte  conforme")
    for r in resultats:
        d, f = r["depart"], r["reference"]
        dep = f"{'PASS' if d['ok'] else 'FAIL'} @{d['etape']} {d['tests']['passes']}/{d['tests']['total']}"
        ref = f"{'PASS' if f['ok'] else 'FAIL'} {f['tests']['passes']}/{f['tests']['total']}"
        stable = "oui" if d["stable"] and f["stable"] else "NON"
        print(f"{r['id']:<28} {dep:<34} {ref:<26} {stable:<7} {'oui' if r['empreinte_ok'] else 'NON':<10} "
              f"{'OUI' if r['conforme'] else 'NON'}")
    conformes = sum(r["conforme"] for r in resultats)
    print(f"\n{conformes}/{len(resultats)} tâches conformes")
    return conformes == len(resultats) and bool(resultats)


def main(argv: list[str] | None = None) -> int:
    """python -m usine.taches installer | verifier [dossier]"""
    import argparse
    import sys

    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.taches")
    sous = parser.add_subparsers(dest="commande", required=True)
    sous.add_parser("installer", help="copier godot/taches_modeles vers donnees/taches (empreintes vérifiées)")
    p = sous.add_parser("verifier", help="vérifier format et empreintes d'un dossier de tâches")
    p.add_argument("dossier", type=Path, nargs="?", default=cfg.dossier_donnees() / "taches")
    args = parser.parse_args(argv)
    if args.commande == "installer":
        for chemin in installer_modeles():
            print(chemin)
        return 0
    taches = lister_taches(args.dossier)
    mauvaises = [t for t in taches if not verifier_empreinte(t)]
    for t in mauvaises:
        print(f"empreinte invalide : {t}")
    print(f"{len(taches) - len(mauvaises)}/{len(taches)} tâches valides")
    return 0 if taches and not mauvaises else 1


if __name__ == "__main__":
    raise SystemExit(main())
