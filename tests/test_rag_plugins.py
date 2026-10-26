"""Plugins conseillés par le RAG (usine/rag/plugins.py) : ce qui se décide sans lancer Godot."""

from usine.rag import plugins


def test_le_manifeste_et_les_fiches_vont_ensemble():
    m = plugins.manifeste()
    assert m
    for ident, entree in m.items():
        assert {"nom", "depot", "version", "licence", "url", "fichier", "sha256", "addons"} <= set(entree), ident
        assert len(entree["sha256"]) == 64
        assert (plugins.DOSSIER / ident / "fiche.md").exists(), ident
        if entree.get("verification") != "editeur":  # un outil d'éditeur se vérifie sans exemple de jeu
            assert (plugins.DOSSIER / ident / "exemple" / "exemple.gd").exists(), ident


def test_la_sortie_de_godot_se_lit_ligne_par_ligne():
    bon = "Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\nEXEMPLE VERIFIE : ok\n"
    assert plugins.reussi(0, bon)
    assert not plugins.reussi(0, bon + "ERROR: Failed to retrieve non-existent singleton 'X'.\n")
    assert not plugins.reussi(0, bon + "WARNING: 2 ObjectDB instances were leaked at exit\n")
    assert not plugins.reussi(0, "rien\n")
    assert not plugins.reussi(1, bon)
    assert plugins.problemes("WARNING: V-Sync mode not supported\n") == []
    bruit = bon + "ERROR: Can't send message. No active debugger\n"
    assert not plugins.reussi(0, bruit)
    assert plugins.reussi(0, bruit, ["ERROR: Can't send message. No active debugger"])


def test_la_racine_de_la_scene_suit_l_exemple():
    assert plugins.type_racine("extends Node3D\n## doc\n") == "Node3D"
    assert plugins.type_racine("class_name A\nextends Control\n") == "Control"
    assert plugins.type_racine("## rien\n") == "Node"


def test_le_bloc_debug_est_celui_du_socle():
    bloc = plugins.bloc_debug()
    assert bloc.startswith("[debug]") and "untyped_declaration=2" in bloc
