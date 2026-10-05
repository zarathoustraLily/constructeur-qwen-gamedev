"""Règles d'acceptation d'une tâche candidate (sans LLM).

Une tâche est acceptée si :
  1. son format est valide (champs, empreinte, au moins un test caché) ;
  2. le départ est rouge et la référence verte, N fois sur N (N = 3 par défaut) ;
  3. ses tests cachés tuent au moins X % des mutants de la référence (X configurable),
     les mutants étant pris dans la zone que la référence change (mutants.py) ;
  4. elle n'est pas un doublon d'un jeu gelé (empreinte ou fragments) — vérifié par chaine.py.

Compétence E (optimisation stricte) : le juge ajoute l'étape « mesure_efficience »
(usine/efficience/juge.py). Le départ doit y échouer (comportement intact, efficience
insuffisante) et la référence y passer. Si la référence échoue à cette étape, la raison du
rejet est la catégorie de l'erreur : efficience_allocations, efficience_draw_calls,
efficience_temps ou rendu_degrade. Ces quatre raisons servent aussi au tri des essais de Qwen
(session 5) : ce sont les catégories du verdict d'un candidat refusé.

Chaque rejet porte une raison (RAISONS) et un détail lisible.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.generateurs.mutants import score_mutation_tache
from usine.taches import calculer_empreinte, juger_tache, lire_tache

RAISONS = {
    "format_invalide": "tache.json incomplet, empreinte fausse ou aucun test caché",
    "depart_pas_rouge": "le départ passe le juge (la tâche n'a rien à faire)",
    "reference_pas_verte": "la référence échoue au juge",
    "instable": "verdicts différents d'une répétition à l'autre",
    "score_mutation_insuffisant": "les tests cachés tuent trop peu de mutants",
    "doublon_gele": "doublon d'une tâche des jeux gelés (empreinte ou fragments)",
    "doublon_candidat": "doublon d'une autre candidate déjà acceptée (empreinte)",
    # Compétence E (étape mesure_efficience)
    "efficience_draw_calls": "lots de dessin au-delà de la référence × 1,05",
    "efficience_allocations": "objets alloués après l'échauffement (attendu : 0)",
    "efficience_temps": "temps par image au-delà de la référence × 1,15",
    "rendu_degrade": "un réglage ou un élément de rendu diffère de la référence",
}
RAISONS_EFFICIENCE = ("efficience_draw_calls", "efficience_allocations", "efficience_temps", "rendu_degrade")


def raison_efficience(verdict: dict[str, Any]) -> str | None:
    """Raison E d'un verdict refusé à l'étape mesure_efficience (première erreur catégorisée)."""
    if verdict.get("ok") or verdict.get("etape") != "mesure_efficience":
        return None
    for e in verdict.get("erreurs", []):
        if e.get("categorie") in RAISONS_EFFICIENCE:
            return e["categorie"]
    return None


@dataclass
class Reglages:
    repetitions: int = 3
    seuil_mutants: float = 0.5        # part minimale de mutants tués
    mutants_max: int = 8              # mutants évalués par tâche (tirage déterministe)
    seuil_fragments: float = 0.8      # Jaccard des fragments de réponse
    graine: int = 0

    @classmethod
    def depuis_config(cls, graine: int = 0, config: dict[str, Any] | None = None) -> "Reglages":
        config = cfg.charger_config() if config is None else config
        p = config.get("portillon", {})
        return cls(repetitions=int(p.get("repetitions", 3)), seuil_mutants=float(p.get("seuil_mutants", 0.5)),
                   mutants_max=int(p.get("mutants_max", 8)), seuil_fragments=float(p.get("seuil_fragments", 0.8)),
                   graine=graine)


@dataclass
class Decision:
    id: str
    competence: str
    acceptee: bool
    raison: str | None = None
    detail: str = ""
    mesures: dict[str, Any] = field(default_factory=dict)

    def ligne(self) -> dict[str, Any]:
        return {"id": self.id, "competence": self.competence, "acceptee": self.acceptee, "raison": self.raison,
                "detail": self.detail, **self.mesures}


def _resume(v: dict[str, Any]) -> str:
    return f"{'PASS' if v['ok'] else 'FAIL'}@{v['etape']} {v['tests']['passes']}/{v['tests']['total']}"


def _efficience(v: dict[str, Any]) -> dict[str, Any]:
    """Les trois sous-critères E et le rendu, en bref, pour le journal du portillon."""
    m = v["metriques"]
    r: dict[str, Any] = {"raison": raison_efficience(v)}
    if "draw_calls" in m:
        r["lots"] = [m["draw_calls"]["valeur"], m["draw_calls"]["reference"]]
    if "allocations_actives_apres_warmup" in m:
        r["allocations"] = m["allocations_actives_apres_warmup"]["delta_objets"]
    if "temps_cpu_relatif" in m:
        r["temps_ratio"] = m["temps_cpu_relatif"]["ratio"]
    if "rendu" in m:
        r["rendu_intact"] = m["rendu"]["ok"]
    return r


def evaluer(dossier: Path, reglages: Reglages) -> Decision:
    """Règles 1 à 3. Les verdicts passent par le cache (une clé par répétition)."""
    dossier = Path(dossier)
    try:
        tache = lire_tache(dossier)
    except (ValueError, OSError) as e:
        return Decision(dossier.name, "?", False, "format_invalide", str(e))
    d = Decision(tache["id"], tache["competence"], False)
    if tache["empreinte"] != calculer_empreinte(dossier, tache):
        d.raison, d.detail = "format_invalide", "empreinte fausse"
        return d
    if not any((dossier / "tests_caches").glob("test_*.gd")):
        d.raison, d.detail = "format_invalide", "aucun test caché"
        return d

    for version, attendu in (("depart", False), ("reference", True)):
        verdicts = []
        for rep in range(1, reglages.repetitions + 1):
            v = juger_tache(dossier, version, repetition=rep)
            verdicts.append(v)
            if v["ok"] != attendu:
                break
        d.mesures[version] = [_resume(v) for v in verdicts]
        d.mesures[f"{version}_cache"] = sum(bool(v.get("depuis_cache")) for v in verdicts)
        if "metriques" in verdicts[-1]:
            d.mesures[f"{version}_efficience"] = _efficience(verdicts[-1])
        if any(v["ok"] != attendu for v in verdicts):
            if len(verdicts) > 1:
                d.raison = "instable"
            elif version == "depart":
                d.raison = "depart_pas_rouge"
            else:
                d.raison = raison_efficience(verdicts[-1]) or "reference_pas_verte"
            d.detail = f"{version} : {', '.join(d.mesures[version])}"
            if verdicts[-1]["erreurs"]:
                d.detail += " — " + verdicts[-1]["erreurs"][0]["message"][:200]
            return d
        comparables = {(v["ok"], v["etape"], tuple(v["tests"]["echecs"]), v["tests"]["total"]) for v in verdicts}
        if len(comparables) > 1:
            d.raison, d.detail = "instable", f"{version} : {', '.join(d.mesures[version])}"
            return d

    score = score_mutation_tache(dossier, reglages.mutants_max, reglages.graine)
    d.mesures["mutants"] = {"tues": score["tues"], "total": score["total"], "score": score["score"]}
    if score["total"] and score["score"] < reglages.seuil_mutants:
        d.raison = "score_mutation_insuffisant"
        d.detail = f"{score['tues']}/{score['total']} mutants tués (< {reglages.seuil_mutants:.0%}) ; survivants : " \
                   + ", ".join(score["survivants"][:3])
        return d
    d.acceptee = True
    if not score["total"]:
        d.detail = "aucun mutant applicable à la zone de la réponse (critère sans objet)"
    return d
