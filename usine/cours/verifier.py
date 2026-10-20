"""Vérifie les projets fabriqués d'un cours : le juge des règles, puis Godot 4.7.2 pour de vrai.

Pour chaque projet d'étape :
- juge des règles d'architecture (usine/regles) : 0 écart attendu ;
- import du projet ; analyse de chaque script (`--check-only`), avec les avertissements que le projet traite en
  erreurs (bloc [debug] de son project.godot) ;
- tests de l'étape (scripts `extends SceneTree` de 7_tests) : code 0, aucune « SCRIPT ERROR », aucun « ÉCHEC » ;
- une image en Compatibilité (`--rendering-method gl_compatibility`) : les shaders ne se compilent qu'au rendu.

Cours « de jeu » (usine/cours/jeu.py, le kart) : les tests de l'étape sont des suites GdUnit4 (7_tests/, lancées comme
7_tests/lancer_tests.bat, cadence fixe) ; l'image vient de la partie elle-même, par l'autoload de capture de l'usine
(usine/retour/capture.py), fenêtre hors de l'écran, à l'image 90. À l'import, l'éditeur sans fenêtre affiche une
erreur de son moteur de rendu factice en chargeant sa disposition (« Parameter "material" is null », à
material_get_instance_shader_parameters, servers/rendering/dummy/) : elle ne dépend pas du projet et n'est pas
comptée (relevée le 2026-10-20 dès le premier import du kart, avant toute modification).

Sous Linux sans écran, le rendu passe par xvfb-run (comme usine/retour/capture.py). Seuls nos processus sont
arrêtés (règle 8). Lignes retirées des sorties : lignes vides et lignes d'information de Godot (règle 5.1).
"""

from __future__ import annotations

import os
import re
import shutil
import sys
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.processus import executer
from usine.regles import par_regle, verifier_regles

BRUIT = re.compile(r"^\s*$|^Godot Engine v|^OpenGL API|^Vulkan \d|V-Sync mode|gl_manager_x11|^Using present mode"
                   r"|Failed to load cached shader|_load_from_cache")
_EXTENDS_SCENETREE = re.compile(r"^extends\s+SceneTree\b", re.M)


def nettoyer_sortie(texte: str, projet: Path) -> str:
    """Retire les lignes d'information et les chemins de la machine : le projet devient « . »."""
    lignes = [l.rstrip() for l in texte.splitlines() if not BRUIT.search(l)]
    absolu = str(Path(projet).resolve())
    return "\n".join(lignes).replace(absolu + "/", "").replace(absolu, ".")


def prefixe_ecran() -> tuple[list[str], dict[str, str]]:
    """(préfixe de commande, variables d'environnement) pour un rendu : xvfb-run sous Linux sans écran."""
    if sys.platform.startswith("linux") and not os.environ.get("DISPLAY") and shutil.which("xvfb-run"):
        return ["xvfb-run", "-a", "-s", "-screen 0 960x540x24"], {"LIBGL_ALWAYS_SOFTWARE": "1"}
    return [], {}


def scripts(projet: Path) -> list[str]:
    projet = Path(projet)
    return sorted("res://" + f.relative_to(projet).as_posix() for f in projet.rglob("*.gd")
                  if ".godot" not in f.relative_to(projet).parts and "addons" not in f.relative_to(projet).parts)


def tests(projet: Path) -> list[str]:
    """Les tests de l'étape : scripts de 7_tests lancés avec -s (extends SceneTree)."""
    projet = Path(projet)
    return [res for res in scripts(projet) if res.startswith("res://7_tests/")
            and _EXTENDS_SCENETREE.search((projet / res.removeprefix("res://")).read_text(encoding="utf-8"))]


_BRUIT_IMPORT = re.compile(r'Parameter "material" is null|material_get_instance_shader_parameters '
                           r'\(servers/rendering/dummy/|update_scripts_classes')


def suites_gdunit(projet: Path) -> list[str]:
    """Les suites GdUnit4 de l'étape (7_tests/, `extends GdUnitTestSuite`), si l'extension est là."""
    projet = Path(projet)
    if not (projet / "addons/gdUnit4/bin/GdUnitCmdTool.gd").is_file():
        return []
    return [res for res in scripts(projet) if res.startswith("res://7_tests/") and re.search(
        r"^extends\s+GdUnitTestSuite\b", (projet / res.removeprefix("res://")).read_text(encoding="utf-8"), re.M)]


def lancer_gdunit(projet: Path, godot: Path, delai_s: float = 1200) -> dict[str, Any]:
    """Toutes les suites de 7_tests, sans fenêtre, à cadence fixe : {code, resume, sortie}."""
    r = executer([godot, "--headless", "--path", projet, "--fixed-fps", "60", "-s", "-d", "--remote-debug",
                  "tcp://127.0.0.1:0", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "--ignoreHeadlessMode", "-c",
                  "-rd", ".godot/rapports_tests", "-a", "res://7_tests", "++", "cadence_fixe"], delai_s=delai_s)
    texte = re.sub(r"\x1b\[[0-9;]*m", "", nettoyer_sortie(r.sortie, projet))
    resume = next((l.strip() for l in texte.splitlines() if l.strip().startswith("Overall Summary")), "")
    return {"code": r.code, "resume": resume, "sortie": texte}


def gdunit_reussi(t: dict[str, Any]) -> bool:
    return t["code"] == 0 and bool(t["resume"]) and "SCRIPT ERROR" not in t["sortie"]


def test_reussi(code: int | None, texte: str) -> bool:
    return code == 0 and "SCRIPT ERROR" not in texte and "ÉCHEC" not in texte and bool(
        re.search(r"(?<![\d])0 échec", texte))


def verifier_projet(projet: Path, godot: Path | None = None, rendu: bool = True, image: Path | None = None,
                    delai_s: float = 300) -> dict[str, Any]:
    """Le bilan d'un projet : {nom, ok, regles, import, analyses, tests, rendu}."""
    projet = Path(projet)
    bilan: dict[str, Any] = {"nom": projet.name}
    verdict = verifier_regles(projet)
    bilan["regles"] = par_regle(verdict)
    bilan["regles_detail"] = [f"{e['fichier']}:{e['ligne']} {e['message']}" for e in verdict.get("erreurs", [])][:20]
    if godot is None:
        try:
            godot = cfg.chemin_godot()
        except cfg.GodotIntrouvable:
            bilan["godot"] = False
            bilan["ok"] = verdict["ok"]
            return bilan
    shutil.rmtree(projet / ".godot", ignore_errors=True)
    imp = executer([godot, "--headless", "--path", projet, "--import"], delai_s=delai_s)
    bilan["import"] = "\n".join(l for l in nettoyer_sortie(imp.sortie, projet).splitlines()
                                if re.search(r"error|warning|erreur", l, re.I) and not _BRUIT_IMPORT.search(l))
    bilan["analyses"] = {}
    from usine.juge import godot as juges
    singletons = juges.autoloads(projet)
    for res in scripts(projet):
        if singletons:
            # --check-only ignore les singletons : le juge de l'usine recompile alors avec eux (check_script).
            v = juges.check_script(projet / res.removeprefix("res://"), projet, godot)
            if v["erreurs"]:
                bilan["analyses"][res] = "\n".join(f"{e.get('fichier')}:{e.get('ligne')} {e['message']}"
                                                   for e in v["erreurs"])
            continue
        r = executer([godot, "--headless", "--path", projet, "--check-only", "-s", res], delai_s=120)
        texte = nettoyer_sortie(r.sortie, projet)
        if texte.strip():
            bilan["analyses"][res] = texte
    bilan["tests"] = {}
    for res in tests(projet):
        r = executer([godot, "--headless", "--path", projet, "-s", res], delai_s=delai_s)
        bilan["tests"][res] = {"code": r.code, "sortie": nettoyer_sortie(r.sortie, projet)}
    gdunit = None
    if suites_gdunit(projet):
        gdunit = lancer_gdunit(projet, godot)
        bilan["gdunit"] = {"code": gdunit["code"], "resume": gdunit["resume"],
                           "erreurs": [l for l in gdunit["sortie"].splitlines()
                                       if "FAILED" in l or "SCRIPT ERROR" in l][:20]}
    jeu = not (projet / "2_sequence/step_viewer/step_viewer.gd").is_file()
    if rendu and jeu:
        from usine.retour.capture import capturer
        png = (Path(image) if image else projet / ".godot" / "verification.png").resolve()
        png.parent.mkdir(parents=True, exist_ok=True)
        c = capturer(projet, [90], sortie=png.parent, colonnes=1, echelle=1.0, godot=godot, hors_ecran=True)
        if c.get("grille"):
            shutil.move(c["grille"], png)
        bilan["rendu"] = {"code": 0 if c["ok"] else 1, "image": png.is_file(),
                          "erreurs": c.get("erreurs", []) + ([c["erreur"]] if c.get("erreur") else [])}
    elif rendu:
        prefixe, env = prefixe_ecran()
        # Chemin absolu : avec --path, Godot travaille depuis le dossier du projet.
        png = (Path(image) if image else projet / ".godot" / "verification.png").resolve()
        png.parent.mkdir(parents=True, exist_ok=True)
        r = executer([*prefixe, godot, "--path", projet, "--rendering-method", "gl_compatibility",
                      "--rendering-driver", "opengl3", "--audio-driver", "Dummy", "--resolution", "960x540",
                      "--quit-after", "6000", "--", f"--shot={png}"], delai_s=delai_s, env=env)
        texte = nettoyer_sortie(r.sortie, projet)
        bilan["rendu"] = {"code": r.code, "erreurs": [l for l in texte.splitlines() if "ERROR" in l],
                          "image": png.is_file()}
    bilan["ok"] = (verdict["ok"] and not bilan["import"] and not bilan["analyses"]
                   and all(test_reussi(t["code"], t["sortie"]) for t in bilan["tests"].values())
                   and (bool(bilan["tests"]) or gdunit is not None)
                   and (gdunit is None or gdunit_reussi(gdunit))
                   and (not rendu or (not bilan["rendu"]["erreurs"] and bilan["rendu"]["image"])))
    return bilan
