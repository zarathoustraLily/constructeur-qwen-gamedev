"""Outil voir_editeur : plugin seul actif dans la copie, éditeur en fenêtre unique, vraie capture de l'éditeur."""

import sys

import pytest

from usine.paires import camera
from usine.retour import editeur


def test_le_plugin_est_seul_actif_dans_la_copie(tmp_path):
    (tmp_path / "project.godot").write_text(
        'config_version=5\n\n[editor_plugins]\n\nenabled=PackedStringArray("res://addons/godot_ai/plugin.cfg")\n\n'
        '[rendering]\n\nx=1\n', encoding="utf-8")
    editeur._poser(tmp_path)
    texte = (tmp_path / "project.godot").read_text(encoding="utf-8")
    assert "godot_ai" not in texte  # ses ports sont déjà pris par l'éditeur de laurent
    assert 'enabled=PackedStringArray("res://addons/usine_editeur/plugin.cfg")' in texte and "[rendering]" in texte
    assert (tmp_path / "addons/usine_editeur/editeur_plugin.gd").is_file()


def test_reglages_en_fenetre_unique(tmp_path):
    editeur._fenetre_unique(tmp_path)  # fichier absent : créé
    reglages = next(tmp_path.glob("editor_settings-*.tres"))
    reglages.write_text(reglages.read_text(encoding="utf-8").replace("= true", "= false"), encoding="utf-8")
    editeur._fenetre_unique(tmp_path)  # fichier présent : corrigé, sans doublon
    texte = reglages.read_text(encoding="utf-8")
    assert texte.count("interface/editor/display/single_window_mode = true") == 1
    assert texte.count("interface/multi_window/enable = false") == 1


@pytest.mark.godot
@pytest.mark.skipif(sys.platform != "win32", reason="lancement réduit : Windows seulement")
def test_godot_l_editeur_montre_le_pivot_sans_rotation(tmp_path):
    n = camera.niveau(2)
    sain = camera.scene(n)
    defaut = next(d for d in camera.DEFAUTS if d.nom == "inclinaison_absente")
    correct, faux = defaut.editer(n, sain)
    projet = tmp_path / "projet"
    projet.mkdir()
    (projet / "niveau.tscn").write_text(sain.replace(correct, faux), encoding="utf-8")
    (projet / "project.godot").write_text('config_version=5\n\n[application]\n\nconfig/name="Niveau"\n',
                                          encoding="utf-8")
    r = editeur.voir_editeur(projet, "res://niveau.tscn", "Joueur/Pivot", "rotation", sortie=tmp_path / "sortie")
    assert r["ok"], r
    d = r["donnees"]
    assert d["fenetre"] == [1920, 1080] and r["image"]
    assert [l["chemin"] for l in d["arbre"] if l["selectionne"]] == ["Joueur/Pivot"]
    rotation = next(p for p in d["inspecteur"]["proprietes"] if p["propriete"] == "rotation")
    assert rotation["entiere"] and rotation["affiche"][0].startswith("x 0")
    assert d["zones"]["scene"]["visible"] and d["zones"]["inspecteur"]["visible"]
    assert not next(v for v in d["vue_3d"]["noeuds"] if v["chemin"] == "Joueur/Pivot/Camera3D")["dans_la_vue"]
