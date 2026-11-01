"""Une fenêtre de Godot prend la souris du poste : elle est refusée sans accord (usine/cours/base/godot.py)."""

from __future__ import annotations

import pytest

from usine.cours.base import godot


def test_un_rendu_dans_une_fenetre_est_refuse_sans_accord(monkeypatch):
    monkeypatch.setattr(godot, "prefixe_ecran", lambda: ([], None))
    monkeypatch.delenv("USINE_FENETRES", raising=False)
    with pytest.raises(godot.FenetreRefusee):
        godot.rendre_jeu(".")
    with pytest.raises(godot.FenetreRefusee):
        godot.rendre(".")


def test_un_ecran_virtuel_ne_gene_personne():
    godot._fenetre_permise(["xvfb-run"])
