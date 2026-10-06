"""Adaptateur GameDevBench (Chi et al., ICML 2026 ; dépôt public waynchi/gamedevbench, Apache 2.0).

Faits relevés dans le dépôt (2026-10-05) :
  - 333 tâches Godot, une archive par tâche (tasks/task_NNNN.zip) et leur vérité terrain
    (tasks_gt/) ; chaque tâche porte un task_config.json (instruction, métadonnées) ;
  - liste des tâches : tasks.yaml (`tasks:` puis `- task_NNNN`) ; aucune catégorie par tâche
    dans le dépôt (gameplay, UI, 2D, 3D ne sont donnés qu'en proportions) ;
  - Godot 4.4.1 exact (GODOT_EXEC_PATH) ; le runner refuse une autre version ;
  - runner : gamedevbench/src/benchmark_runner.py --agent opencode --model <fournisseur/modèle>
    [--confinement strict|off] run --task-list <yaml> ; il écrit final_results.json
    (success, tasks_attempted, task_success_rate, tasks[...]) ;
  - classement publié : results/leaderboard.csv (pass@1 en %, IC 95 %) ; le meilleur fait
    69,97 % sur les 333 tâches.

L'adaptateur ne réécrit pas leur harness (le score ne serait plus comparable). Il :
  1. vérifie le dépôt copié hors-ligne et le binaire Godot 4.4.1 (séparé du 4.7.2) ;
  2. décompresse les archives (sans bash, donc aussi sous Windows) ;
  3. écrit la liste des tâches à faire tourner (toutes, ou un sous-ensemble : `--ids`, par
     exemple les tâches de logique de gameplay si laurent en obtient la liste) ;
  4. construit et lance la commande du runner, avec OpenCode branché sur llama-server ;
  5. lit final_results.json : réussites / tâches tentées, intervalle de Wilson, et les lignes
     du classement publié pour comparer.
Le score n'est comparable au classement que sur les 333 tâches, avec Godot 4.4.1 et le
confinement strict (Linux, bubblewrap). Sous Windows, `--confinement off` : le runner marque
alors le résultat « non confiné ».
"""

from __future__ import annotations

import csv
import json
import os
import re
import subprocess
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any

from usine import config as cfg
from usine.mesure.stats import Score, wilson

VERSION_GODOT = "4.4.1"
RUNNER = Path("gamedevbench") / "src" / "benchmark_runner.py"
_ID = re.compile(r"^\s*-\s*(task_\d+)\s*$")


def reglages(config: dict[str, Any] | None = None) -> dict[str, Any]:
    config = cfg.charger_config() if config is None else config
    g = config.get("gamedevbench", {})
    depot = g.get("depot")
    godot = config.get("godot", {}).get("console_gamedevbench")
    return {"depot": None if not depot or depot == cfg.A_RENSEIGNER else Path(depot).expanduser(),
            "godot": None if not godot or godot == cfg.A_RENSEIGNER else Path(godot).expanduser(),
            "modele": g.get("modele", "llamacpp/qwen"), "confinement": g.get("confinement", "off"),
            "python": list(g.get("python", ["uv", "run", "python"])), "agent": g.get("agent", "opencode")}


def verifier_depot(depot: Path) -> list[str]:
    """Problèmes du dépôt copié (liste vide si tout y est)."""
    depot = Path(depot)
    manque = [str(p) for p in ("tasks.yaml", RUNNER, Path("results") / "leaderboard.csv") if not (depot / p).is_file()]
    if not list((depot / "tasks").glob("task_*.zip")) and not list((depot / "tasks").glob("task_*/task_config.json")):
        manque.append("tasks/task_*.zip")
    return [f"absent du dépôt : {m}" for m in manque]


def version_godot(godot: Path) -> str:
    """Première ligne de `godot --version` (le binaire 4.4.1 de GameDevBench)."""
    sortie = subprocess.run([str(godot), "--headless", "--version"], capture_output=True, text=True, timeout=60)
    return (sortie.stdout or sortie.stderr).strip().splitlines()[0] if (sortie.stdout or sortie.stderr).strip() else ""


def lire_liste(chemin: Path) -> list[str]:
    ids = []
    for ligne in Path(chemin).read_text(encoding="utf-8").splitlines():
        m = _ID.match(ligne)
        if m:
            ids.append(m.group(1))
    return ids


def ecrire_liste(chemin: Path, ids: list[str]) -> Path:
    chemin = Path(chemin)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text("tasks:\n" + "".join(f"- {i}\n" for i in ids), encoding="utf-8", newline="\n")
    return chemin


def decompresser(depot: Path) -> int:
    """Décompresse tasks/*.zip et tasks_gt/*.zip à la racine du dépôt (équivalent de unzip_tasks.sh).
    Refuse un chemin d'archive absolu ou qui remonte ('..'). Renvoie le nombre d'archives ouvertes."""
    depot = Path(depot)
    n = 0
    for dossier in ("tasks", "tasks_gt"):
        for archive in sorted((depot / dossier).glob("task_*.zip")):
            with zipfile.ZipFile(archive) as z:
                for nom in z.namelist():
                    p = PurePosixPath(nom)
                    if p.is_absolute() or ".." in p.parts:
                        raise ValueError(f"chemin refusé dans {archive.name} : {nom}")
                z.extractall(depot)
            n += 1
    return n


def commande(r: dict[str, Any], liste: Path, resultats: Path | None = None) -> tuple[list[str], dict[str, str]]:
    """Commande du runner officiel et variables d'environnement (GODOT_EXEC_PATH)."""
    cmd = [*r["python"], str(RUNNER), "--agent", r["agent"], "--model", r["modele"],
           "--confinement", r["confinement"], "run", "--task-list", str(Path(liste).resolve())]
    env = {"GODOT_EXEC_PATH": str(r["godot"])} if r.get("godot") else {}
    return cmd, env


def lancer(r: dict[str, Any], liste: Path) -> int:
    """Lance le runner dans le dépôt (processus enfant, sortie à l'écran). Long : une session
    OpenCode par tâche."""
    cmd, env = commande(r, liste)
    return subprocess.run(cmd, cwd=r["depot"], env={**os.environ, **env}).returncode


def score(final_results: Path) -> tuple[Score, dict[str, Any]]:
    """Réussites sur tâches tentées (définition du runner : les tâches sautées ne comptent pas)."""
    d = json.loads(Path(final_results).read_text(encoding="utf-8"))
    taches = d.get("tasks") or d.get("results") or []
    if taches:
        tentees = [t for t in taches if not t.get("skipped", False)]
        k, n = sum(1 for t in tentees if t.get("success")), len(tentees)
    else:
        k, n = int(d["success"]), int(d["tasks_attempted"])
    config = d.get("configuration", {}) if isinstance(d.get("configuration"), dict) else {}
    return wilson(k, n), {"configuration": config, "taux_publie_par_le_runner": d.get("task_success_rate")}


def classement(depot: Path, n: int = 5) -> list[dict[str, str]]:
    chemin = Path(depot) / "results" / "leaderboard.csv"
    if not chemin.is_file():
        return []
    with chemin.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))[:n]


def lignes_rapport(s: Score, info: dict[str, Any], tableau: list[dict[str, str]], n_total: int = 333) -> list[str]:
    out = [f"Qwen (OpenCode, llama-server) : **{s.texte()}** sur les tâches tentées.",
           "" if s.n == n_total else
           f"Attention : {s.n} tâches tentées sur {n_total} ; seul le score sur les {n_total} tâches est comparable au classement.",
           ""]
    if tableau:
        out += ["Classement publié (results/leaderboard.csv, pass@1, IC 95 %) :", "",
                "| rang | modèle | harness | pass@1 | IC 95 % |", "| --- | --- | --- | --- | --- |"]
        out += [f"| {t.get('rank')} | {t.get('model')} | {t.get('harness')} | {t.get('pass_at_1_percent')} % | "
                f"± {t.get('ci_95_percent')} |" for t in tableau]
    return [l for l in out if l is not None]
