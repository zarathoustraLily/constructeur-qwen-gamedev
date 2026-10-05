"""Rapport de mesure : rapport_mesure.md et son CSV, à partir des lignes de résultats.

Une ligne par compétence (les 14, mesurées ou non) : les 4 scores au premier essai avec leur
intervalle de Wilson à 95 %, la référence frontière (sans adaptation, sans et avec le même RAG)
si elle a été mesurée, et le verdict de stats.verdict (frontière avec RAG).
"""

from __future__ import annotations

import csv
import io
from pathlib import Path
from typing import Any, Iterable

from usine.mesure.executer import COMPETENCES, CONFIGURATIONS, FRONTIERES
from usine.mesure.stats import Score, regression, verdict, wilson

COLONNES_SCORES = tuple(CONFIGURATIONS) + FRONTIERES
NOMS = {"base": "base", "base_rag": "base + RAG", "lora": "LoRA", "lora_rag": "LoRA + RAG",
        "frontiere": "frontière", "frontiere_rag": "frontière + RAG"}


def scores(lignes: Iterable[dict[str, Any]], tour: str | None = None) -> dict[str, dict[str, Score]]:
    """{compétence: {configuration: Score}}. Le tour s'applique aux 4 configurations de Qwen ;
    la frontière, mesurée une fois, est prise quel que soit son tour."""
    lignes = list(lignes)
    if tour is None:
        tours = sorted({str(l.get("tour")) for l in lignes if l["configuration"] in CONFIGURATIONS})
        if len(tours) > 1:
            raise ValueError(f"résultats de plusieurs tours ({', '.join(tours)}) : préciser le tour")
    comptes: dict[str, dict[str, list[int]]] = {}
    for l in lignes:
        conf = l["configuration"]
        if tour is not None and conf in CONFIGURATIONS and l.get("tour") != tour:
            continue
        c = comptes.setdefault(l["competence"], {}).setdefault(conf, [0, 0])
        c[0] += 1 if l["ok"] else 0
        c[1] += 1
    return {comp: {conf: wilson(k, n) for conf, (k, n) in confs.items()} for comp, confs in comptes.items()}


def tableau(lignes: Iterable[dict[str, Any]], tour: str | None = None) -> list[dict[str, Any]]:
    par_comp = scores(lignes, tour)
    resultat = []
    for comp in list(COMPETENCES) + sorted(set(par_comp) - set(COMPETENCES)):
        s = par_comp.get(comp, {})
        v, motif = verdict(s.get("lora_rag"), s.get("base_rag"), s.get("frontiere_rag"))
        n = max((x.n for x in s.values()), default=0)
        resultat.append({"competence": comp, "n": n, "scores": s, "verdict": v, "motif": motif})
    return resultat


def ecrire_csv(lignes_tableau: list[dict[str, Any]]) -> str:
    sortie = io.StringIO()
    w = csv.writer(sortie, lineterminator="\n")
    entete = ["competence", "n"]
    for conf in COLONNES_SCORES:
        entete += [f"{conf}_k", f"{conf}_n", f"{conf}_taux", f"{conf}_bas", f"{conf}_haut"]
    w.writerow(entete + ["verdict", "motif"])
    for l in lignes_tableau:
        rangee: list[Any] = [l["competence"], l["n"]]
        for conf in COLONNES_SCORES:
            s = l["scores"].get(conf)
            rangee += ([s.k, s.n, f"{s.k / s.n:.4f}", f"{s.bas:.4f}", f"{s.haut:.4f}"] if s and s.n
                       else ["", "", "", "", ""])
        w.writerow(rangee + [l["verdict"], l["motif"]])
    return sortie.getvalue()


def ecrire_markdown(lignes_tableau: list[dict[str, Any]], titre: str, notes: list[str] | None = None,
                    gamedevbench: list[str] | None = None) -> str:
    out = [f"# {titre}", ""]
    out += ["Score : réussite au premier essai selon le juge de la tâche, intervalle de Wilson à 95 % entre crochets.",
            "Verdict (CLAUDE.md) : **victoire** si LoRA + RAG dépasse base + RAG au-delà de l'intervalle "
            "**et** atteint la frontière mesurée avec le même RAG ; **défaite** si LoRA + RAG est sous "
            "base + RAG au-delà de l'intervalle ; **égalité** sinon (motif en dernière colonne).", ""]
    for note in notes or []:
        out.append(f"> {note}")
    if notes:
        out.append("")
    entete = ["Compétence", "n"] + [NOMS[c] for c in COLONNES_SCORES] + ["Verdict", "Motif"]
    out.append("| " + " | ".join(entete) + " |")
    out.append("| " + " | ".join("---" for _ in entete) + " |")
    for l in lignes_tableau:
        cellules = [l["competence"], str(l["n"] or "—")]
        for conf in COLONNES_SCORES:
            s = l["scores"].get(conf)
            cellules.append(s.texte() if s and s.n else "—")
        cellules += [f"**{l['verdict']}**", l["motif"]]
        out.append("| " + " | ".join(cellules) + " |")
    bilan: dict[str, int] = {}
    for l in lignes_tableau:
        bilan[l["verdict"]] = bilan.get(l["verdict"], 0) + 1
    out += ["", "Bilan : " + ", ".join(f"{v} {n}" for v, n in sorted(bilan.items())), ""]
    if gamedevbench:
        out += ["## GameDevBench", ""] + gamedevbench + [""]
    return "\n".join(out)


def ecrire(lignes: list[dict[str, Any]], dossier: Path, tour: str | None = None, titre: str = "Rapport de mesure",
           notes: list[str] | None = None, gamedevbench: list[str] | None = None) -> tuple[Path, Path]:
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    t = tableau(lignes, tour)
    md, fichier_csv = dossier / "rapport_mesure.md", dossier / "rapport_mesure.csv"
    md.write_text(ecrire_markdown(t, titre, notes, gamedevbench), encoding="utf-8", newline="\n")
    fichier_csv.write_text(ecrire_csv(t), encoding="utf-8", newline="\n")
    return md, fichier_csv


def texte_regression(ancien: list[dict[str, Any]], nouveau: list[dict[str, Any]],
                     configuration: str = "lora_rag") -> tuple[str, bool]:
    """Tableau de non-régression entre deux tours (une configuration) ; vrai si rien ne bloque."""
    def par_comp(lignes: list[dict[str, Any]]) -> dict[str, Score]:
        return {comp: confs[configuration] for comp, confs in scores(lignes).items() if configuration in confs}
    lignes = regression(par_comp(ancien), par_comp(nouveau))
    out = [f"Non-régression ({NOMS.get(configuration, configuration)}) :", "",
           f"{'compétence':10s} {'ancien':>28s} {'nouveau':>28s}  statut"]
    for l in lignes:
        a = l["ancien"].texte() if l["ancien"] else "—"
        b = l["nouveau"].texte() if l["nouveau"] else "—"
        out.append(f"{l['competence']:10s} {a:>28s} {b:>28s}  {l['statut']}{'  ← BLOQUANT' if l['bloquant'] else ''}")
    ok = not any(l["bloquant"] for l in lignes)
    out.append("")
    out.append("Aucune compétence ne recule." if ok else
               "RECUL : " + ", ".join(l["competence"] for l in lignes if l["bloquant"]))
    return "\n".join(out), ok
