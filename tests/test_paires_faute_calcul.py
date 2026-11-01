"""La famille « une valeur fausse → la ligne de calcul » : les fautes posées et la lecture des sorties, sans Godot."""

from usine.paires import faute_calcul as fc

GD = """class_name Demo extends RefCounted


## Double la moyenne de deux cases.
static func moyenne(field: Champ, x: int) -> float:
	var somme: float = field.at(x - 1) + field.at(x + 1)
	field.vider()
	return 0.5 * somme
"""

GLSL = """#[compute]
#version 450

layout(local_size_x = 8) in;

// La case d'à côté.
float voisine(int x) {
	return imageLoad(source, ivec2(x + 1, 0)).r;
}

// Une invocation par case.
void main() {
	imageStore(target, ivec2(0), vec4(voisine(0)));
}
"""

SORTIE = """Run Test Suite: res://7_tests/test_demo.gd
  res://7_tests/test_demo.gd > test_a STARTED
  res://7_tests/test_demo.gd > test_a FAILED 3ms
  Report:
  Expecting:
 0.285737
 in range between
 17.990000 <> 18.010000\tat 'test_a' in res://7_tests/test_demo.gd:28
Statistics: 1 test cases | 0 errors | 1 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 29ms
"""


def genres(fautes, ligne):
    return {f.genre for f in fautes if f.ligne == ligne}


def test_les_fautes_ne_touchent_que_le_corps_des_fonctions():
    fautes = fc.fautes("1_core/demo.gd", GD)
    assert {f.ligne for f in fautes} == {6, 7, 8}
    assert {"signe", "decalage"} <= genres(fautes, 6)
    assert "facteur" in genres(fautes, 8)


def test_une_faute_ne_change_qu_un_endroit():
    fautes = [f for f in fc.fautes("1_core/demo.gd", GD) if f.genre == "signe"]
    assert [f.fautif.strip() for f in fautes] == ["var somme: float = field.at(x - 1) - field.at(x + 1)"]
    assert (fautes[0].de, fautes[0].vers) == ("+", "-")
    assert fautes[0].texte == GD.replace(") + field", ") - field")


def test_oublier_un_appel_retire_sa_ligne():
    faute = next(f for f in fc.fautes("1_core/demo.gd", GD) if f.genre == "oubli")
    assert "field.vider()" not in faute.texte and len(faute.texte.split("\n")) == len(GD.split("\n")) - 1
    assert faute.juste.endswith("field.vider()") and faute.fautif.strip().startswith("var somme")


def test_un_shader_a_ses_fautes_et_ses_fonctions():
    fautes = fc.fautes("1_core/shaders/demo.glsl", GLSL)
    assert "decalage" in genres(fautes, 8)
    assert "oubli" in genres(fautes, 13)
    nom, contrat, code = fc.fonction_de("1_core/shaders/demo.glsl", GLSL, 13)
    assert nom == "main" and contrat == ["Une invocation par case."] and code.startswith("// Une invocation")


def test_la_fonction_d_une_ligne_et_son_contrat():
    nom, contrat, code = fc.fonction_de("1_core/demo.gd", GD, 8)
    assert nom == "moyenne" and contrat == ["Double la moyenne de deux cases."]
    assert code.startswith("## Double") and code.endswith("return 0.5 * somme")
    assert fc.fonction_de("1_core/demo.gd", GD, 1) is None


def test_le_reproche_d_un_cas_est_lu_tel_quel():
    assert fc.reproche(SORTIE, "test_a") == ("Expecting: 0.285737 in range between 17.990000 <> 18.010000",
                                            "res://7_tests/test_demo.gd:28")
    assert fc.reproche(SORTIE, "test_b") is None


def test_un_shader_est_juge_par_les_suites_de_ce_qui_le_charge(monkeypatch):
    apres = {"1_core/gpu/passe.gd": 'const S := "res://1_core/gpu/shaders/demo.glsl"\n',
             "1_core/gpu/shaders/demo.glsl": GLSL,
             "7_tests/1_core/gpu/test_autre.gd": 'extends GdUnitTestSuite\nconst S := "res://1_core/gpu/shaders/demo.glsl"\n'}
    from usine.paires import execution
    monkeypatch.setattr(execution, "suites_pour", lambda _a, rel: ["7_tests/1_core/gpu/test_passe.gd"] if rel.endswith("passe.gd") else [])
    assert fc.suites_de(apres, "1_core/gpu/shaders/demo.glsl") == ["7_tests/1_core/gpu/test_passe.gd", "7_tests/1_core/gpu/test_autre.gd"]
