"""Retour des outils : écriture sans effet, vocabulaire d'un script, fiches des erreurs."""

import json
import shutil

import pytest

from usine import config as cfg
from usine.retour import Ecritures, IndexProjet, fiches_pour_erreurs, formater_rapport, verifier_script
from usine.retour.verification import nettoyer
from usine.vocab.construire import charger
from usine.vocab.requete import Vocabulaire


def _m(nom, args=(), retour=None, **kw):
    return {"name": nom, "arguments": [dict(a) for a in args],
            **({"return_value": {"type": retour}} if retour else {}), **kw}


API = {
    "header": {"version_major": 4, "version_minor": 7, "version_patch": 2},
    "classes": [
        {"name": "Object", "inherits": None, "api_type": "core", "methods": [_m("get_class", retour="String")]},
        {"name": "Node", "inherits": "Object", "api_type": "core", "methods": [
            _m("add_child", [{"name": "node", "type": "Node"}])],
         "properties": [{"name": "name", "type": "StringName"}]},
        {"name": "Node3D", "inherits": "Node", "api_type": "core",
         "properties": [{"name": "position", "type": "Vector3"}]},
        {"name": "Node2D", "inherits": "Node", "api_type": "core",
         "properties": [{"name": "rotation", "type": "float"}]},
        {"name": "MeshInstance3D", "inherits": "Node3D", "api_type": "core", "methods": [
            _m("set_surface_override_material", [{"name": "surface", "type": "int"},
                                                 {"name": "material", "type": "Material"}])]},
        {"name": "CharacterBody3D", "inherits": "Node3D", "api_type": "core",
         "methods": [_m("move_and_slide", retour="bool")]},
        {"name": "PrismMesh", "inherits": "Object", "api_type": "core", "is_instantiable": True,
         "properties": [{"name": "left_to_right", "type": "float"}]},
        {"name": "Input", "inherits": "Object", "api_type": "core", "methods": [
            _m("is_action_pressed", [{"name": "action", "type": "StringName"},
                                     {"name": "exact_match", "type": "bool", "default_value": "false"}], "bool")]},
    ],
    "builtin_classes": [
        {"name": "Array", "methods": [{"name": "append", "arguments": [{"name": "value", "type": "Variant"}]}]},
        {"name": "Dictionary", "methods": [{"name": "keys", "return_type": "Array"}]},
        {"name": "int"}, {"name": "float"}, {"name": "bool"},
    ],
}

SCRIPT = '''extends CharacterBody3D

var m: MeshInstance3D
var donnees: Dictionary
@onready var corps := $Corps as Node3D

func _ready() -> void:
	move_and_slide()
	m.set_surface_overide_material(0, null)
	var p := PrismMesh.new()
	p.left_to_rightx = 0.5
	Input.is_action_presed("a")
	Input.is_action_pressed("a", false, 3)
	var x: Foobar = null
	print(donnees.cle, "m.texte_dans_une_chaine()")  # m.commentaire()
	m.set_surface_override_material(0, null)
	corps.position = Vector3.ZERO
'''


@pytest.fixture()
def vocab(tmp_path):
    return Vocabulaire(charger(API, tmp_path / "v.sqlite"))


def test_ecriture_sans_effet_le_dit(tmp_path):
    e = Ecritures()
    f = tmp_path / "a.gd"
    assert e.ecrire(f, "res://a.gd", "x") == (True, "écrit : res://a.gd (1 caractères)")
    change, msg = e.ecrire(f, "res://a.gd", "x")
    assert not change and msg.startswith("aucun changement : ce contenu est déjà celui de res://a.gd")
    change, msg = e.ecrire(f, "res://a.gd", "x")
    assert "(2 écritures identiques d'affilée)" in msg
    assert e.ecrire(f, "res://a.gd", "y")[0] and f.read_text() == "y"
    assert "d'affilée" not in e.ecrire(f, "res://a.gd", "y")[1]


def test_nettoyer_garde_les_lignes():
    texte = 'a = "x.y()" # m.z()\nb = """\nm.w()\n"""\nc.d()\n'
    propre = nettoyer(texte)
    assert propre.count("\n") == texte.count("\n")
    assert "m.z" not in propre and "m.w" not in propre and "x.y" not in propre and "c.d()" in propre


def test_verifier_script(vocab):
    r = verifier_script(SCRIPT, "res://a.gd", vocab)
    par_ligne = {p["ligne"]: p["message"] for p in r["problemes"]}
    assert sorted(par_ligne) == [9, 11, 12, 13, 14]
    assert "MeshInstance3D n'a aucun membre set_surface_overide_material" in par_ligne[9]
    assert "MeshInstance3D.set_surface_override_material(surface: int, material: Material)" in par_ligne[9]
    assert "PrismMesh.left_to_right: float" in par_ligne[11]
    assert "Input.is_action_pressed(action: StringName, exact_match: bool = false) -> bool" in par_ligne[12]
    assert "attend 1 à 2 argument(s), l'appel en passe 3" in par_ligne[13]
    assert "type inconnu : Foobar" in par_ligne[14]
    assert "MeshInstance3D.set_surface_override_material(surface: int, material: Material)" in r["signatures"]
    assert "Node3D.position: Vector3" in r["signatures"]
    texte = formater_rapport(r, "res://a.gd", vocab.version())
    assert texte.startswith("Vocabulaire Godot 4.7.2 dans res://a.gd : 5 problème(s).") and "✗ ligne 9" in texte


def test_pas_de_faux_positif_sur_l_acces_dynamique(vocab):
    projet = IndexProjet()
    projet.ajouter("res://ennemi.gd", "class_name Ennemi\nextends Node3D\n\n@export var vie := 3\nfunc toucher() -> void:\n\tpass\n")
    projet.ajouter("res://boss.gd", "extends Ennemi\n\nfunc bouclier() -> void:\n\tpass\n")
    script = ("extends Node\n\nvar n: Node\nvar e: Ennemi\n\nfunc f(x: Node) -> void:\n"
              "\tn.toucher()\n"          # déclaré par un script du projet : l'objet peut le porter
              "\tx.position = Vector3()\n"  # propriété d'une classe dérivée (Node3D)
              "\te.vie -= 1\n\te.bouclier()\n"  # membre de la classe, puis d'un script dérivé
              "\te.inexistant()\n"
              "\tvar l: Array = []\n\tl.append([1, 2])\n")
    r = verifier_script(script, "res://j.gd", vocab, projet)
    assert [(p["ligne"], p["message"].split(" (")[0]) for p in r["problemes"]] == [
        (11, "Ennemi n'a aucun membre inexistant")]


def test_fiches_pour_erreurs(vocab, tmp_path):
    (tmp_path / "project.godot").write_text("")
    (tmp_path / "a.gd").write_text(SCRIPT, encoding="utf-8")
    erreurs = [
        {"fichier": "res://a.gd", "ligne": 8, "message": 'Parse Error: Function "move_and_slidex()" not found in base self.'},
        {"fichier": "res://a.gd", "ligne": 12,
         "message": 'Parse Error: Static function "is_action_presed()" not found in base "GDScriptNativeClass".'},
        {"fichier": "res://a.gd", "ligne": 16, "message": "Attempt to call function on a null instance."},
    ]
    doc = {"CharacterBody3D.move_and_slide": "Déplace le corps en glissant."}.get
    fiches = fiches_pour_erreurs(erreurs, tmp_path, vocab, doc=doc)
    assert [f["pour"] for f in fiches] == ["res://a.gd:8", "res://a.gd:12", "res://a.gd:16"]
    assert "move_and_slidex n'existe pas dans CharacterBody3D" in fiches[0]["fiche"]
    assert "CharacterBody3D.move_and_slide() -> bool" in fiches[0]["fiche"]
    assert fiches[0]["fiche"].endswith("Doc : Déplace le corps en glissant.")
    assert "Input.is_action_pressed(" in fiches[1]["fiche"]
    assert fiches[2]["fiche"].startswith("MeshInstance3D.set_surface_override_material(surface: int, material: Material)")


# ------------------------------------------------------------------ branchements (vrai vocabulaire)

@pytest.mark.godot
def test_agent_write_file_rend_le_retour(tmp_path):
    from usine.rft import agent
    projet = tmp_path / "p"
    shutil.copytree(cfg.RACINE / "godot" / "reference", projet, ignore=shutil.ignore_patterns("addons", ".godot"))
    boite = agent.Boite(projet)
    code = "extends Node3D\n\nfunc _ready() -> void:\n\tvar m := MeshInstance3D.new()\n\tm.set_surface_overide_material(0, null)\n"
    premier = boite.appeler("write_file", {"chemin": "res://scripts/neuf.gd", "contenu": code})
    assert premier.startswith("écrit : res://scripts/neuf.gd")
    assert "✗ ligne 5 : MeshInstance3D n'a aucun membre set_surface_overide_material" in premier
    assert "set_surface_override_material(surface: int, material: Material)" in premier
    second = boite.appeler("write_file", {"chemin": "res://scripts/neuf.gd", "contenu": code})
    assert second.startswith("aucun changement") and "Vocabulaire" not in second


@pytest.mark.godot
def test_check_script_joint_vocabulaire_et_fiches(tmp_path):
    from mcp_serveur.outils import Outils
    projet = tmp_path / "p"
    shutil.copytree(cfg.RACINE / "godot" / "reference", projet, ignore=shutil.ignore_patterns(".godot"))
    (projet / "scripts" / "neuf.gd").write_text(
        "extends CharacterBody3D\n\nfunc _ready() -> void:\n\tmove_and_slidex()\n", encoding="utf-8")
    v = json.loads(Outils(projet, index_docs=tmp_path / "absent.sqlite").check_script("res://scripts/neuf.gd"))
    assert not v["ok"]
    assert v["fiches"][0]["pour"] == "res://scripts/neuf.gd:4"
    assert "CharacterBody3D.move_and_slide() -> bool" in v["fiches"][0]["fiche"]
    assert v["vocabulaire"].startswith("Vocabulaire Godot 4.7.2 dans res://scripts/neuf.gd")
