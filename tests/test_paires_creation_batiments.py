"""Création tirée des bâtiments procéduraux (usine/paires/maillage.py, morceaux.py, shader_fonction.py) : ce qui se
décide sans lancer Godot."""

from usine.paires import maillage
from usine.paires import shader_fonction as sf

SHADER = """shader_type spatial;

uniform float largeur : hint_range(0.0, 1.0) = 0.5;
const float PAS = 2.0;

// Bande adoucie de demi-largeur w.
// Une ligne plus fine que le pixel s'atténue.
float bande(float d, float w) {
	return 1.0 - smoothstep(w - PAS, w, abs(d)) * largeur;
}

vec3 sans_doc(vec3 c) {
	return c;
}

void fragment() {
	ALBEDO = vec3(bande(UV.x, 0.1));
}
"""


def test_les_fonctions_de_shader_et_leur_commentaire():
    fs = {f.nom: f for f in sf.fonctions(SHADER)}
    assert set(fs) == {"bande", "sans_doc", "fragment"}
    lignes = SHADER.split("\n")
    assert lignes[fs["bande"].doc] == "// Bande adoucie de demi-largeur w."
    assert fs["sans_doc"].doc == fs["sans_doc"].ligne
    assert [f.nom for f in sf.candidates(SHADER)] == ["bande"]


def test_le_corps_vide_rend_la_valeur_nulle_du_type():
    assert [sf.defaut(t) for t in ("float", "int", "uint", "bool", "vec3", "ivec2", "bvec4", "uvec2", "mat3")] == [
        "0.0", "0", "0u", "false", "vec3(0.0)", "ivec2(0)", "bvec4(false)", "uvec2(0u)", "mat3(1.0)"]
    f = sf.candidates(SHADER)[0]
    vide = sf.vider(SHADER, f)
    assert "float bande(float d, float w) {\n\treturn 0.0;\n}" in vide
    assert "smoothstep" not in vide and "ALBEDO" in vide


def test_le_contexte_montre_ce_que_la_fonction_emploie():
    f = sf.candidates(SHADER)[0]
    texte = sf.contexte("6_assets/Shader/Procedural/x.gdshader", f, {"6_assets/Shader/Procedural/x.gdshader": SHADER})
    assert "uniform float largeur" in texte and "const float PAS" in texte
    assert texte.rstrip().endswith("float bande(float d, float w) {\n" + sf.TROU + "\n}")
    assert "smoothstep" not in texte


def test_les_scenes_du_test_et_l_empreinte():
    test = 'const SCENES: PackedStringArray = [\n\t"res://a/b.tscn",\n\t"res://a/b_verre.tscn",\n]\n'
    assert maillage.scenes_du_test(test) == ["res://a/b.tscn", "res://a/b_verre.tscn"]
    assert maillage.scenes_du_test("extends SceneTree\n") == []
    sortie = "Godot Engine v4.7.2\nEMPREINTE res://a/b.tscn " + "0f" * 32 + "\n"
    assert maillage.EMPREINTE.findall(sortie) == [("res://a/b.tscn", "0f" * 32)]
