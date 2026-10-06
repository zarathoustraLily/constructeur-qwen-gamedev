"""Résultats simulés, pour éprouver le rapport et la règle de victoire dans le cloud (sans Qwen).

Chaque compétence du scénario reçoit n tâches fictives ; pour une configuration, k d'entre elles
réussissent (tirage déterministe par la graine). Le scénario par défaut couvre les verdicts :
victoire, égalité (chevauchement, frontière non atteinte, frontière non mesurée), défaite, et des
compétences non mesurées.
"""

from __future__ import annotations

import random
from typing import Any

# compétence → configuration → réussites sur N_DEFAUT tâches
SCENARIO_DEFAUT: dict[str, dict[str, int]] = {
    "D1": {"base": 20, "base_rag": 24, "lora": 35, "lora_rag": 40, "frontiere": 30, "frontiere_rag": 36},
    "F1": {"base": 10, "base_rag": 12, "lora": 30, "lora_rag": 33, "frontiere": 40, "frontiere_rag": 42},
    "K1": {"base": 30, "base_rag": 32, "lora": 33, "lora_rag": 35, "frontiere": 38, "frontiere_rag": 40},
    "S1": {"base": 25, "base_rag": 30, "lora": 40, "lora_rag": 44},
    "S2": {"base": 30, "base_rag": 35, "lora": 15, "lora_rag": 18, "frontiere": 41, "frontiere_rag": 44},
    "K2": {"base": 12, "base_rag": 14, "lora": 20, "lora_rag": 22},
    "K3": {"base": 18, "base_rag": 20, "lora": 31, "lora_rag": 34},
    "E": {"base": 5, "base_rag": 6, "lora": 9, "lora_rag": 10},
}
N_DEFAUT = 50


def simuler(scenario: dict[str, dict[str, int]] | None = None, n: int = N_DEFAUT, graine: int = 1,
            tour: str = "t0") -> list[dict[str, Any]]:
    scenario = SCENARIO_DEFAUT if scenario is None else scenario
    rng = random.Random(graine)
    lignes = []
    for comp in sorted(scenario):
        ids = [f"sim_{comp.lower()}_{i:03d}" for i in range(n)]
        for conf in sorted(scenario[comp]):
            k = scenario[comp][conf]
            if not 0 <= k <= n:
                raise ValueError(f"{comp}/{conf} : {k} réussites sur {n}")
            reussies = set(rng.sample(ids, k))
            for tid in ids:
                ok = tid in reussies
                lignes.append({"tour": tour, "configuration": conf, "competence": comp, "tache_id": tid,
                               "empreinte": "simulee", "ok": ok, "etape": "run_tests" if ok else "simulee",
                               "categorie": None if ok else "test_failure", "message": "", "tests": None,
                               "duree_appel_s": 0.0, "duree_juge_s": 0.0, "jetons_entree": 0, "jetons_sortie": 0,
                               "fin": "stop", "modele": "simulation", "reponse": ""})
    return lignes
