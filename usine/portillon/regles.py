"""Règles d'acceptation d'une tâche candidate (sans LLM).

Une tâche est acceptée si :
  1. son format est valide (champs, empreinte, au moins un test caché) ;
  2. le départ est rouge et la référence verte, N fois sur N (N = 3 par défaut) ;
  3. ses tests cachés tuent au moins X % des mutants de la référence (X configurable),
     les mutants étant pris dans la zone que la référence change (mutants.py) ;
  4. elle n'est pas un doublon d'un jeu gelé (empreinte ou fragments) — vérifié par chaine.py.

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
}


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
        if any(v["ok"] != attendu for v in verdicts):
            if len(verdicts) > 1:
                d.raison = "instable"
            else:
                d.raison = "depart_pas_rouge" if version == "depart" else "reference_pas_verte"
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
