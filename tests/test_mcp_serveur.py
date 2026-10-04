"""Serveur MCP : list_tools et chaque outil sur une copie de godot/reference, par un vrai client stdio."""

from __future__ import annotations

from pathlib import Path

import pytest

from mcp_serveur.outils import ErreurOutil, Outils
from mcp_serveur.preuve import preuve
from usine.portillon.exclusion import Exclusion
from usine.rag import index as rag

from tests.test_rag import CLASSE_RST

REFERENCE = Path(__file__).resolve().parent.parent / "godot" / "reference"


def test_chemins_hors_du_projet_refuses():
    o = Outils(REFERENCE)
    assert o.res("scenes/coin.tscn") == o.res("./scenes/coin.tscn") == "res://scenes/coin.tscn"
    for faux in ("../x.gd", "res://../../x.gd", "scenes/../../x.gd"):
        with pytest.raises(ErreurOutil):
            o.res(faux)


def test_vocab_lookup():
    o = Outils(REFERENCE)
    assert o.vocab_lookup("Area2D", "body_entered") == "signal [Area2D] body_entered(body: Node2D)"
    assert "move_and_slide() -> bool" in o.vocab_lookup("CharacterBody2D")
    assert o.vocab_lookup("Area2D", "invente").startswith("Area2D n'a aucun membre invente")
    assert o.vocab_lookup("Fantome2D").startswith("Classe inconnue")


@pytest.mark.godot
def test_preuve_mcp(tmp_path, capsys):
    docs = tmp_path / "docs" / "classes"
    docs.mkdir(parents=True)
    (docs / "class_characterbody2d.rst").write_text(CLASSE_RST, encoding="utf-8")
    rag.construire(tmp_path / "docs", tmp_path / "idx.sqlite", donnees=tmp_path, exclusion=Exclusion(None))
    code = preuve(REFERENCE, tmp_path / "idx.sqlite")
    sortie = capsys.readouterr().out
    assert code == 0, sortie
    assert "12/12 contrôles conformes" in sortie
