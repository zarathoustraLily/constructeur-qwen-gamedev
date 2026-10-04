"""Générateurs et portillon avec le moteur : une proposition inventée passe le portillon."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from usine.generateurs.invention import materialiser
from usine.generateurs.mutants import score_mutation_tache
from usine.portillon.regles import Reglages, evaluer

DONNEES = Path(__file__).parent / "donnees"


@pytest.mark.godot
def test_invention_exemple_passe_le_portillon(tmp_path):
    proposition = json.loads((DONNEES / "invention_exemple.json").read_text(encoding="utf-8"))
    dossier = materialiser(proposition, tmp_path)
    decision = evaluer(dossier, Reglages(repetitions=1, mutants_max=2))
    assert decision.acceptee, decision.ligne()
    assert decision.mesures["depart"][0].startswith("FAIL@run_tests")
    assert decision.mesures["reference"] == ["PASS@run_tests 3/3"]
    assert decision.mesures["mutants"]["total"] >= 1
    # Les verdicts sont en cache : le second calcul du score ne relance pas Godot et donne le même résultat.
    assert score_mutation_tache(dossier, 2) == score_mutation_tache(dossier, 2)
