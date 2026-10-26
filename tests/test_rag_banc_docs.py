"""Banc de recherche tiré de godot-docs-dataset : ancres, groupes, lecture du fichier, échantillon."""

import pytest

from usine.rag import banc_docs

CSV = (
    'instruction,input,output,category,source\n'
    '"Explain the `add_child` method of the Node class in Godot.","","x","classes",'
    '"classes/class_node.html#class-node-method-add-child"\n'
    '"Explain the `add_child` method of the Node class in Godot. (part 2/2)","","y","classes",'
    '"classes/class_node.html#class-node-method-add-child"\n'
    '"What is the Node class in Godot?","","z","classes","classes/class_node.html"\n'
    '"What does the Godot documentation say about ""Setup""?","","w","tutorials/2d",'
    '"tutorials/2d/2d_movement.html#setup"\n'
)


def test_make_id_comme_docutils():
    assert banc_docs.make_id("class_Node_method_add_child") == "class-node-method-add-child"
    assert banc_docs.make_id("What are licenses?") == "what-are-licenses"
    assert banc_docs.make_id("8-way movement") == "way-movement"  # docutils retire chiffres et tirets de tête
    assert banc_docs.make_id("Résumé  des   effets") == "resume-des-effets"


def test_groupes():
    assert banc_docs.groupe("classes/class_node.rst", "class-node-method-add-child") == "membre"
    assert banc_docs.groupe("classes/class_node.rst", "") == "classe"
    assert banc_docs.groupe("classes/class_node.rst", "methods") == "classe"
    assert banc_docs.groupe("tutorials/2d/2d_movement.rst", "setup") == "guide"


def test_lignes_dedoublonne_les_parties_et_verifie_l_empreinte(tmp_path):
    f = tmp_path / "jeu.csv"
    f.write_text(CSV, encoding="utf-8", newline="")
    with pytest.raises(ValueError):
        banc_docs.lignes(f)  # empreinte différente de celle du jeu téléchargé
    l = banc_docs.lignes(f, sha256=None)
    assert [(x["page"], x["ancre"], x["groupe"]) for x in l] == [
        ("classes/class_node.rst", "class-node-method-add-child", "membre"),
        ("classes/class_node.rst", "", "classe"),
        ("tutorials/2d/2d_movement.rst", "setup", "guide")]


def test_echantillon_stable_et_plafonne():
    liste = [{"page": f"p{i}.rst", "ancre": "", "groupe": "guide"} for i in range(50)]
    a = banc_docs.echantillon(liste, 10)
    assert len(a) == 10 and a == banc_docs.echantillon(list(reversed(liste)), 10)
    assert banc_docs.echantillon(liste, 0) == liste
