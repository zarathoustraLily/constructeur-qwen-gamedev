"""Famille « réaliser un point de l'étape » (D1) : faute d'analyse hors des tests, état posé puis remis."""

from __future__ import annotations

from types import SimpleNamespace

from usine.paires import points


def test_une_faute_d_analyse_dans_un_test_ne_compte_pas():
	dans_le_jeu = ("SCRIPT ERROR: Parse Error: Identifier \"Rock\" not declared in the current scope.\n"
	               "   at: GDScript::reload (res://3_entities/decor/decor.gd:12)")
	dans_un_test = ("SCRIPT ERROR: Parse Error: Could not find type \"Rock\" in the current scope.\n"
	                "   at: GDScript::reload (res://7_tests/3_entities/decor/test_decor.gd:8)")
	assert points.faute_d_analyse(dans_le_jeu)
	assert not points.faute_d_analyse(dans_un_test)
	assert not points.faute_d_analyse("FAILED test_rocher_sur_la_couche_terrain")


def test_poser_retire_les_fichiers_absents_puis_remettre_les_rend(tmp_path):
	apres = {"a.gd": "extends Node\n", "b/c.tscn": "[gd_scene format=3]\n", "notes.md": "texte\n"}
	for rel, t in apres.items():
		(tmp_path / rel).parent.mkdir(parents=True, exist_ok=True)
		(tmp_path / rel).write_text(t, encoding="utf-8")
	projet = SimpleNamespace(chemin=str(tmp_path), apres=apres, code={"a.gd": apres["a.gd"]})
	points.poser(projet, {"a.gd": "extends Node2D\n", "notes.md": "texte\n"})
	assert (tmp_path / "a.gd").read_text(encoding="utf-8") == "extends Node2D\n"
	assert not (tmp_path / "b" / "c.tscn").exists()
	points.remettre(projet)
	assert (tmp_path / "a.gd").read_text(encoding="utf-8") == "extends Node\n"
	assert (tmp_path / "b" / "c.tscn").read_text(encoding="utf-8") == "[gd_scene format=3]\n"
