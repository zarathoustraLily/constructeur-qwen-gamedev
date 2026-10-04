"""Les trois juges élémentaires : check_script, load_scene, run_tests.

Chacun renvoie un verdict au format commun. Ils travaillent sur le projet qu'on leur
donne ; pour juger sans rien toucher, passer par `usine.juge.projet` (copie de travail).
"""

from __future__ import annotations

import json
import re
import shutil
import tempfile
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.juge.verdict import dedoublonner, erreur, extraire_erreurs_journal, lire_junit, nouveau_verdict
from usine.processus import Resultat, executer

SCRIPT_SCENE = Path(__file__).resolve().parent / "gd" / "charger_scene.gd"
SCRIPT_COMPILATION = Path(__file__).resolve().parent / "gd" / "charger_script.gd"
MARQUEUR_SCENE = "@@JUGE_SCENE@@"
MARQUEUR_SCRIPT = "@@JUGE_SCRIPT@@"
SCRIPT_LOT = Path(__file__).resolve().parent / "gd" / "verifier_lot.gd"
DEBUT_LOT = "@@JUGE_LOT_DEBUT@@"
MARQUEUR_LOT = "@@JUGE_LOT@@"
CACHE_CLASSES = Path(".godot") / "global_script_class_cache.cfg"
DOSSIER_RAPPORTS = ".usine_rapports"


def trouver_projet(chemin: Path) -> Path:
    """Dossier contenant project.godot, en remontant depuis `chemin`."""
    chemin = Path(chemin).resolve()
    for dossier in [chemin, *chemin.parents]:
        if (dossier / "project.godot").is_file():
            return dossier
    raise FileNotFoundError(f"aucun project.godot au-dessus de {chemin}")


def chemin_res(chemin: Path | str, projet: Path) -> str:
    """Chemin disque ou res:// → res://…"""
    if str(chemin).startswith("res://"):
        return str(chemin)
    return "res://" + Path(chemin).resolve().relative_to(Path(projet).resolve()).as_posix()


def _godot(godot: Path | None) -> Path:
    return Path(godot) if godot else cfg.chemin_godot()


def _delai(delai_s: float | None) -> float:
    return delai_s if delai_s is not None else cfg.delai_juge()


def _expiration(verdict: dict[str, Any], res: Resultat, quoi: str) -> bool:
    if res.expire:
        verdict["erreurs"].append(erreur(f"délai dépassé ({quoi})", categorie="autre"))
        return True
    return False


def importer(projet: Path, godot: Path | None = None, delai_s: float | None = None) -> dict[str, Any]:
    """`godot --headless --import` : construit le cache des classes (.godot/)."""
    verdict = nouveau_verdict("import")
    res = executer([_godot(godot), "--headless", "--path", projet, "--import"], delai_s=_delai(delai_s))
    verdict["duree_s"] = res.duree_s
    if not _expiration(verdict, res, "import") and res.code != 0:
        verdict["erreurs"].append(erreur(f"import en échec (code {res.code})", categorie="autre"))
    verdict["ok"] = not verdict["erreurs"]
    return verdict


def _assurer_import(projet: Path, godot: Path | None, delai_s: float | None) -> dict[str, Any] | None:
    if (Path(projet) / CACHE_CLASSES).is_file():
        return None
    return importer(projet, godot, delai_s)


def autoloads(projet: Path) -> list[str]:
    """Noms des autoloads déclarés dans project.godot."""
    noms: list[str] = []
    dans_section = False
    for ligne in (Path(projet) / "project.godot").read_text(encoding="utf-8").splitlines():
        ligne = ligne.strip()
        if ligne.startswith("["):
            dans_section = ligne == "[autoload]"
        elif dans_section and "=" in ligne:
            noms.append(ligne.split("=", 1)[0].strip())
    return noms


def _autoload_inconnu(erreurs: list[dict[str, Any]], noms: list[str]) -> bool:
    """Vrai si --check-only signale un autoload inconnu (il ne les enregistre pas).

    L'autoload peut être utilisé par le script lui-même ou par un script dont il dépend
    (« Failed to compile depended scripts », « Could not resolve class » en cascade) : dans
    ces cas, seul le second avis, avec les autoloads enregistrés, fait foi. Une vraie erreur
    y reste visible, puisque le script n'est alors pas instanciable.
    """
    if not noms or not erreurs:
        return False
    motif = re.compile(r"Identifier not found: (?:%s)\b|Failed to compile depended scripts|"
                       r"Could not resolve class" % "|".join(map(re.escape, noms)))
    return any(motif.search(e["message"]) for e in erreurs)


def check_script(chemin: Path | str, projet: Path | None = None, godot: Path | None = None,
                 delai_s: float | None = None) -> dict[str, Any]:
    """`godot --headless --check-only -s <script>` : erreurs d'analyse d'un script."""
    projet = Path(projet) if projet else trouver_projet(Path(chemin))
    verdict = nouveau_verdict("check_script")
    imp = _assurer_import(projet, godot, delai_s)
    res_path = chemin_res(chemin, projet)
    res = executer([_godot(godot), "--headless", "--path", projet, "--check-only", "-s", res_path], delai_s=_delai(delai_s))
    verdict["duree_s"] = res.duree_s + (imp["duree_s"] if imp else 0.0)
    if not _expiration(verdict, res, f"check_script {res_path}"):
        verdict["erreurs"] = dedoublonner(extraire_erreurs_journal(res.sortie))
        if res.code != 0 and not verdict["erreurs"]:
            verdict["erreurs"].append(erreur(f"{res_path} : échec de --check-only (code {res.code})", res_path, categorie="parse_error"))
    if _autoload_inconnu(verdict["erreurs"], autoloads(projet)):
        # Second avis : compilation avec les autoloads enregistrés.
        avis = executer([_godot(godot), "--headless", "--path", projet, "-s", SCRIPT_COMPILATION, "--", res_path],
                        delai_s=_delai(delai_s))
        verdict["duree_s"] += avis.duree_s
        if _expiration(verdict, avis, f"check_script {res_path}"):
            verdict["ok"] = False
            return verdict
        reussi = f'{MARQUEUR_SCRIPT}{{"ok":true}}' in avis.sortie
        # Le marqueur fait foi : charger un script seul, hors de sa scène, fait remonter des
        # erreurs de cycle (script ↔ scène préchargée, class_name en cours de chargement)
        # que le jeu ne rencontre jamais. Elles ne comptent que si le script est inutilisable.
        verdict["erreurs"] = [] if reussi else dedoublonner(extraire_erreurs_journal(avis.sortie))
        if not reussi and not verdict["erreurs"]:
            verdict["erreurs"].append(erreur(f"{res_path} : compilation impossible", res_path, categorie="parse_error"))
        verdict["ok"] = reussi
        return verdict
    verdict["ok"] = res.code == 0 and not verdict["erreurs"]
    return verdict


def verifier_lot(projet: Path, mode: str, chemins: list[Path | str], godot: Path | None = None,
                 delai_s: float | None = None) -> dict[str, Any]:
    """Vérifie tous les scripts (mode « scripts ») ou toutes les scènes (« scenes ») en un lancement.

    Renvoie {"a_revoir": [chemins res:// à rejuger un par un], "duree_s": …}. Un élément est à
    revoir si son marqueur manque ou est faux, ou si une erreur du moteur s'affiche pendant sa
    vérification ; une erreur pendant le chargement des classes globales fait tout revoir.
    Le lot ne fait qu'éviter des lancements : il ne conclut jamais à un échec à lui seul.
    """
    projet = Path(projet)
    imp = _assurer_import(projet, godot, delai_s)
    res_chemins = [chemin_res(c, projet) for c in chemins]
    tous = {"a_revoir": list(res_chemins), "duree_s": imp["duree_s"] if imp else 0.0}
    if not res_chemins:
        tous["a_revoir"] = []
        return tous
    delai = _delai(delai_s) * max(1, len(res_chemins) // 10 + 1)
    res = executer([_godot(godot), "--headless", "--path", projet, "-s", SCRIPT_LOT, "--", mode, *res_chemins],
                   delai_s=delai)
    tous["duree_s"] += res.duree_s
    if res.expire:
        return tous
    segments: dict[str, list[str]] = {}
    courant = None
    resultats: dict[str, bool] = {}
    for ligne in res.sortie.splitlines():
        if ligne.startswith(DEBUT_LOT):
            courant = ligne[len(DEBUT_LOT):].strip()
            segments.setdefault(courant, [])
        elif ligne.startswith(MARQUEUR_LOT):
            r = json.loads(ligne[len(MARQUEUR_LOT):])
            resultats[r["chemin"]] = bool(r["ok"])
        elif courant is not None:
            segments[courant].append(ligne)
    if "<fin>" not in segments or extraire_erreurs_journal("\n".join(segments.get("<classes>", []))):
        return tous
    tous["a_revoir"] = [c for c in res_chemins
                        if not resultats.get(c) or extraire_erreurs_journal("\n".join(segments.get(c, [])))]
    return tous


def load_scene(chemin: Path | str, projet: Path | None = None, godot: Path | None = None,
               delai_s: float | None = None) -> dict[str, Any]:
    """Charge et instancie une scène en headless ; liste nœuds, scripts et ressources manquants."""
    projet = Path(projet) if projet else trouver_projet(Path(chemin))
    verdict = nouveau_verdict("load_scene")
    imp = _assurer_import(projet, godot, delai_s)
    res_path = chemin_res(chemin, projet)
    res = executer([_godot(godot), "--headless", "--path", projet, "-s", SCRIPT_SCENE, "--", res_path],
                   delai_s=_delai(delai_s))
    verdict["duree_s"] = res.duree_s + (imp["duree_s"] if imp else 0.0)
    rapport: dict[str, Any] | None = None
    for ligne in res.sortie.splitlines():
        if ligne.startswith(MARQUEUR_SCENE):
            rapport = json.loads(ligne[len(MARQUEUR_SCENE):])
    if _expiration(verdict, res, f"load_scene {res_path}"):
        verdict["ok"] = False
        return verdict
    erreurs = extraire_erreurs_journal(res.sortie)
    if rapport is None:
        erreurs.append(erreur(f"{res_path} : le script de chargement n'a rien rendu (code {res.code})", res_path, categorie="autre"))
    else:
        verdict["scene"] = rapport
        for manquant in rapport["scripts_manquants"] + rapport["ressources_manquantes"]:
            erreurs.append(erreur(f"{res_path} : dépendance manquante {manquant}", manquant, categorie="missing_resource"))
        if not rapport["chargee"]:
            erreurs.append(erreur(f"{res_path} : chargement impossible", res_path, categorie="missing_resource"))
        elif not rapport["instanciee"]:
            erreurs.append(erreur(f"{res_path} : instanciation impossible", res_path, categorie="autre"))
    verdict["erreurs"] = dedoublonner(erreurs)
    verdict["ok"] = res.code == 0 and rapport is not None and not verdict["erreurs"]
    return verdict


def run_tests(projet: Path, filtre: str | Iterable[str] | None = None, godot: Path | None = None,
              delai_s: float | None = None) -> dict[str, Any]:
    """Lance GdUnit4 en ligne de commande et lit son rapport JUnit.

    filtre : dossier(s) ou suite(s) res:// à exécuter (défaut : res://tests).
    """
    projet = Path(projet).resolve()
    verdict = nouveau_verdict("run_tests")
    cibles = [filtre] if isinstance(filtre, str) else list(filtre or ["res://tests"])
    imp = _assurer_import(projet, godot, delai_s)
    # GdUnit4 résout -rd par rapport au projet : on écrit dans un dossier caché du projet, supprimé ensuite.
    parent_rapports = projet / DOSSIER_RAPPORTS
    parent_rapports.mkdir(exist_ok=True)
    dossier_rapport = Path(tempfile.mkdtemp(prefix="gdunit_", dir=parent_rapports))
    try:
        rd = dossier_rapport.relative_to(projet).as_posix()
        commande: list[Any] = [
            _godot(godot), "--headless", "--path", projet, "-s", "-d",
            # Empêche le débogueur interactif de Godot de boucler sur une erreur d'analyse
            # (même astuce que runtest.sh de GdUnit4 : le port 0 n'est jamais ouvert).
            "--remote-debug", "tcp://127.0.0.1:0",
            "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
            "--ignoreHeadlessMode", "-c", "-rd", rd,
        ]
        for cible in cibles:
            commande += ["-a", cible]
        res = executer(commande, delai_s=_delai(delai_s))
        verdict["duree_s"] = res.duree_s + (imp["duree_s"] if imp else 0.0)
        verdict["journal"] = res.sortie
        if _expiration(verdict, res, "run_tests"):
            return verdict
        erreurs = extraire_erreurs_journal(res.sortie)
        rapports = sorted(dossier_rapport.glob("report_*/results.xml"))
        if rapports:
            tests, erreurs_tests = lire_junit(rapports[-1])
            verdict["tests"] = tests
            erreurs = erreurs_tests + erreurs
        else:
            erreurs.append(erreur(f"GdUnit4 n'a produit aucun rapport (code {res.code})", categorie="autre"))
        if verdict["tests"]["total"] == 0 and rapports:
            erreurs.append(erreur("aucun test exécuté", categorie="test_failure"))
        verdict["erreurs"] = dedoublonner(erreurs)
        verdict["ok"] = bool(rapports) and verdict["tests"]["total"] > 0 and not verdict["erreurs"]
    finally:
        shutil.rmtree(dossier_rapport, ignore_errors=True)
        try:
            parent_rapports.rmdir()
        except OSError:
            pass
    return verdict
