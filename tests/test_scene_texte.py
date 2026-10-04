"""Format texte Godot : valeurs et document sans perte (sans Godot)."""

from pathlib import Path

import pytest

from usine.scene.texte import ecrire_valeur, lire_document, lire_valeur_texte, references, remplacer_references

RACINE = Path(__file__).resolve().parent.parent
SCENES = sorted((RACINE / "godot" / "reference" / "scenes").glob("*.tscn")) + [Path(__file__).parent / "donnees" / "sonde_godot472.tscn"]

LITTERAUX = [
    "6.0", "0.15", "1e-05", "-3", "true", "false", "null", '"Vie : 0/0"', '"a \\"b\\" \\\\ c"', '"deux\nlignes"',
    "Vector2(320, 180)", "Vector2(320.5, 1e+20)", "Vector2i(3, 4)", "Color(1, 0.5, 0.25, 1)",
    "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 2, 3)", "PackedVector2Array(0, 0, 10.25, 3)",
    'PackedStringArray("a", "b")', '&"nom"', 'NodePath("A/B")', 'ExtResource("1_abc")', 'SubResource("Box_x")',
    '[1, 2.5, "x"]', "[]", "{}", '{\n"a": 1,\n"b": [1, 2.5, "x"]\n}', 'Array[String](["vie", "pieces"])',
    'Dictionary[String, int]({\n"a": 1\n})', "inf", "-inf", "nan",
]


@pytest.mark.parametrize("texte", LITTERAUX)
def test_valeur_aller_retour(texte):
    assert ecrire_valeur(lire_valeur_texte(texte)) == texte


def test_codage_json():
    assert lire_valeur_texte("Vector2(320, 180)") == {"Vector2": [320, 180]}
    assert lire_valeur_texte("6.0") == 6.0 and isinstance(lire_valeur_texte("6.0"), float)
    assert lire_valeur_texte("6") == 6 and isinstance(lire_valeur_texte("6"), int)
    assert lire_valeur_texte('{\n"a": 1\n}') == {"Dictionary": [["a", 1]]}
    assert ecrire_valeur({"Vector2": [320.0, 180.0]}) == "Vector2(320, 180)"
    assert ecrire_valeur(6) == "6" and ecrire_valeur(6.0) == "6.0"


def test_repli_texte_brut():
    v = lire_valeur_texte('Object(Node,"a":1)')
    assert v == {"godot": 'Object(Node,"a":1)'}
    assert ecrire_valeur(v) == 'Object(Node,"a":1)'


def test_references():
    v = {"Dictionary": [["k", {"SubResource": "a"}], ["l", [{"ExtResource": "1_x"}, {"SubResource": "b"}]]]}
    assert references(v, "SubResource") == ["a", "b"]
    assert references(remplacer_references(v, "SubResource", {"a": "z"}), "SubResource") == ["z", "b"]


@pytest.mark.parametrize("scene", SCENES, ids=lambda p: p.name)
def test_document_sans_perte(scene):
    texte = scene.read_text(encoding="utf-8")
    assert lire_document(texte).texte() == texte


def test_document_crlf_sans_perte():
    texte = (RACINE / "godot" / "reference" / "scenes" / "hud.tscn").read_text(encoding="utf-8").replace("\n", "\r\n")
    doc = lire_document(texte)
    assert doc.texte() == texte
    assert doc.fin_ligne() == "\r\n"
    noeud = doc.de_balise("node")[1]
    noeud.definir_propriete("visible", "false", fin_ligne=doc.fin_ligne())
    assert "visible = false\r\n" in doc.texte() and "\n" not in doc.texte().replace("\r\n", "")


def test_valeur_multiligne_dans_le_corps():
    doc = lire_document('[node name="A" type="Label"]\ntext = "un\n[pas une section]"\nvisible = false\n')
    assert [e.cle for e in doc.sections[0].proprietes()] == ["text", "visible"]
    assert doc.sections[0].propriete("text").valeur == "un\n[pas une section]"
