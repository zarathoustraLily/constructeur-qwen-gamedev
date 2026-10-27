"""Famille « lire une sortie de Godot » (B4) : verdicts, erreur à traiter d'abord, lignes du moteur."""

from usine.paires import lecture

ANALYSE = """SCRIPT ERROR: Parse Error: Function "_bouger_vite()" not found in base self.
   at: GDScript::reload (res://a.gd:12)
ERROR: Failed to load script "res://a.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)"""

RENDU = """WARNING: SDFGI is only available when using the Forward+ renderer.
   at: environment_set_sdfgi (servers/rendering/storage/environment_storage.cpp:822)
SHADER ERROR: Invalid arguments to operator '*': 'vec2, int'.
   at: (null) (res://s.gdshader:54)
ERROR: Shader compilation failed.
   at: set_code (drivers/gles3/storage/material_storage.cpp:3119)"""

TEST_OK = """Run Test Suite: res://7_tests/test_a.gd
  res://7_tests/test_a.gd > test_x STARTED
ERROR: Parameter "material" is null.
   at: material_get_instance_shader_parameters (servers/rendering/dummy/storage/material_storage.cpp:264)
  res://7_tests/test_a.gd > test_x PASSED 4ms
Overall Summary: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |"""


def test_un_echec_d_analyse_donne_ligne_et_categorie():
    r = lecture.reponse_echec("analyse", ANALYSE, 1, "a.gd", 12, "appel")
    assert r.startswith("**Verdict.** Échec") and "`res://a.gd`, ligne 12, catégorie `parse_error`" in r
    assert "Failed to load script" in r and r.endswith("relancer la même commande.")
    assert lecture.reponse_echec("analyse", ANALYSE, 1, "a.gd", 13, "appel") is None  # pas la ligne connue


def test_un_shader_qui_echoue_avec_le_code_0_est_un_echec():
    r = lecture.reponse_echec("rendu", RENDU, 0, "s.gdshader", 54, "shader_litteral")
    assert "même si le code de sortie est 0" in r and "« at: »" in r and "Forward+" in r


def test_une_reussite_dit_de_ne_rien_retoucher_et_explique_la_ligne_du_moteur():
    r = lecture.reponse_reussite("test", TEST_OK, 0)
    assert r.startswith("**Verdict.** Réussite : 1 cas") and "servers/rendering/dummy/" in r
    assert r.endswith(lecture.SUITE_REUSSITE)
    assert lecture.reponse_reussite("test", TEST_OK, 1) is None
    assert lecture.reponse_reussite("analyse", "", 0).startswith("**Verdict.** Réussite")
    assert lecture.reponse_reussite("analyse", ANALYSE, 0) is None


def test_une_paire_source_sans_code_ne_donne_rien():
    source = {"sujet": "gameplay", "preuve": {"sortie": ANALYSE, "sortie_apres": "", "commande": "godot", "fichier": "a.gd",
                                             "ligne": 12, "genre": "appel", "etape": "kart-003"}}
    assert lecture.paires_de(source, "compilation") == []


SCENE = """ERROR: Node not found: "Panel/Throttle" (relative to "/root/Affichage").
   at: get_node (scene/main/node.cpp:1975)
   GDScript backtrace (most recent call first):
       [0] @implicit_ready (res://ui/affichage.gd:3)"""


def test_une_scene_qui_se_lance_avec_une_erreur_est_un_echec():
    r = lecture.reponse_echec("scene", SCENE, 0, "ui/affichage.gd", 3, "chemin_noeud")
    assert r.startswith("**Verdict.** Échec, malgré le code de sortie 0") and "catégorie `invalid_node_path`" in r
    assert "pile d'appels de GDScript" in r
    assert lecture.reponse_reussite("scene", SCENE, 0) is None
    assert lecture.reponse_reussite("scene", "", 0).startswith("**Verdict.** Réussite : la scène se lance")
