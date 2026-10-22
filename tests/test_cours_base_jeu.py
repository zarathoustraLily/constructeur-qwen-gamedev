"""Base d'entraînement des cours de jeu (usine/cours/base/profil.py) : ce qui se décide sans lancer Godot."""

from usine.cours.base import chemins, mutations, profil

GDUNIT = """Run Test Suite: res://7_tests/1_core/upgrades/test_upgrade.gd
  res://7_tests/1_core/upgrades/test_upgrade.gd > test_elle_augmente_la_propriete STARTED
  res://7_tests/1_core/upgrades/test_upgrade.gd > test_elle_augmente_la_propriete PASSED 5ms
  res://7_tests/1_core/upgrades/test_upgrade.gd > test_la_sante_monte STARTED
  res://7_tests/1_core/upgrades/test_upgrade.gd > test_la_sante_monte FAILED 6ms
Overall Summary: 2 test cases | 0 errors | 1 failures | 0 flaky | 0 skipped | 0 orphans |
Exit code: 100"""


def test_resume_et_cas_de_gdunit():
    assert profil.resume_gdunit(GDUNIT) == (2, 0, 1)
    assert profil.cas_passes(GDUNIT) == ["7_tests/1_core/upgrades/test_upgrade.gd > test_elle_augmente_la_propriete"]
    assert not profil.test_reussi(0, GDUNIT)
    assert profil.test_reussi(0, GDUNIT.replace("1 failures", "0 failures"))
    assert not profil.test_reussi(0, GDUNIT.replace("1 failures", "0 failures") + "\nSCRIPT ERROR: x")


def test_les_suites_de_l_etape_seulement():
    fichiers = {"7_tests/a/test_a.gd": "extends GdUnitTestSuite\n", "7_tests/a/temoin.gd": "extends Node\n",
                "7_tests/b/test_b.gd": "extends GdUnitTestSuite\n", "3_entities/x.gd": "extends Node\n"}
    assert profil.suites(fichiers) == ["7_tests/a/test_a.gd", "7_tests/b/test_b.gd"]
    assert profil.suites(fichiers, {"7_tests/b/test_b.gd", "3_entities/x.gd"}) == ["7_tests/b/test_b.gd"]
    args = profil.arguments_gdunit(["res://7_tests/b/test_b.gd"])
    assert args[-4:] == ["-a", "res://7_tests/b/test_b.gd", "++", "cadence_fixe"] and "-d" not in args


def test_erreurs_du_moteur_sans_lien_avec_le_projet():
    texte = ("It was recognized that GdUnit4 is running in a test environment, therefore the GdUnit4 plugin will not be executed!\n"
             'ERROR: Parameter "material" is null.\n'
             "   at: material_get_instance_shader_parameters (servers/rendering/dummy/storage/material_storage.cpp:264)\n"
             "WARNING: SDFGI is only available when using the Forward+ renderer.\n"
             "   at: environment_set_sdfgi (servers/rendering/storage/environment_storage.cpp:822)")
    assert profil.erreurs_projet(texte) == []
    assert "SDFGI" in profil.note_rendu(texte)
    faute = texte + "\nSHADER ERROR: Invalid arguments to operator '+': 'float, int'.\n   at: (null) (res://s.gdshader:16)"
    assert profil.erreurs_projet(faute) == ["SHADER ERROR: Invalid arguments to operator '+': 'float, int'."]
    assert not profil.rendu_propre(0, faute)


def test_un_script_qui_emploie_un_autoload_n_est_pas_analyse_seul(monkeypatch):
    monkeypatch.setattr(profil, "jeu", lambda: True)
    fichiers = {"project.godot": "[autoload]\n\nGameFlow=\"*res://0_autoload/game_flow.tscn\"\n\n[debug]\n",
                "a.gd": "extends Node\nfunc f() -> void:\n\tGameFlow.start(null)\n",
                "b.gd": "extends Node\n# GameFlow cité en commentaire seulement\n"}
    seuls, autres = profil.analysables(["a.gd", "b.gd"], fichiers)
    assert seuls == ["b.gd"] and autres == {"a.gd": ["GameFlow"]}
    assert "Identifier not found" in profil.phrase_autoloads(autres)


def test_la_scene_qui_charge_le_shader():
    fichiers = {"project.godot": 'run/main_scene="res://boot.tscn"\n',
                "boot.tscn": '[ext_resource type="Resource" path="res://sequence.tres" id="1"]\n',
                "sequence.tres": '[ext_resource type="PackedScene" path="res://shop.tscn" id="1"]\n',
                "shop.tscn": '[ext_resource type="Shader" path="res://fond.gdshader" id="1"]\n',
                "pause.tscn": '[ext_resource type="Shader" path="res://flou.gdshader" id="1"]\n'}
    assert profil.scene_de_rendu(fichiers, ["fond.gdshader"]) is None          # la scène principale le charge
    assert profil.scene_de_rendu(fichiers, ["flou.gdshader"]) == "res://pause.tscn"
    assert "--position" in profil.arguments_rendu(None) and profil.arguments_rendu("res://pause.tscn")[-1] == "res://pause.tscn"


def test_un_gros_fichier_est_donne_pas_enseigne():
    assert profil.raisonnable(None, "[gd_scene]\n" + "\n".join(f"[node name=\"N{i}\"]" for i in range(50)))
    assert not profil.raisonnable(None, "cells = PackedInt32Array(" + "0, " * 600 + "0)\n")
    assert not profil.raisonnable("", "x\n" * 13000)


def test_declarations_parametres_et_retours_sans_type():
    code = ("extends Node\n"
            "var vitesse := 3.0\n"
            "var cible: Node3D = null\n"
            "func aller(direction: Vector3, delta: float) -> void:\n"
            "\tpass\n")
    cands = mutations.candidates("x.gd", code, {2, 3, 4})
    fautes = {(c.genre, c.apres) for c in cands}
    assert ("non_type", "var vitesse = 3.0") in fautes and ("non_type", "var cible = null") in fautes
    assert ("retour", "func aller(direction: Vector3, delta: float):") in fautes
    assert ("parametre", "func aller(direction, delta: float) -> void:") in fautes
    assert any(g == "godot3_nom" and "Spatial" in a for g, a in fautes)


def test_float_d_un_shader_ecrit_int():
    code = "shader_type spatial;\nuniform float force = 0.5;\nvoid fragment() {\n\tfloat t = TIME * 0.2;\n}\n"
    cands = mutations.candidates("s.gdshader", code, {2, 4})
    types = [c for c in cands if c.genre == "shader_type"]
    assert [c.apres for c in types] == ["uniform int force = 0.5;", "\tint t = TIME * 0.2;"]


def test_le_cours_de_jeu_se_configure():
    ch = chemins.configurer(cours="roguelike", config={"opencode": {"dossier_roguelike": "D:\\GODOT\\x\\003_Roguelike"}})
    try:
        assert ch.jeu and ch.nom_cours == "roguelike" and ch.dossier_windows.endswith("003_Roguelike")
        assert ch.base.parts[-3:] == ("cours", "roguelike", "base")
    finally:
        chemins.configurer()


def test_une_erreur_du_jeu_pendant_les_tests_est_un_echec():
    attendue = ("ERROR: GameFlow.start : séquence vide\n   at: push_error (core/variant/variant_utility.cpp:1023)\n"
                "       [2] _execute (res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd:17)\n")
    imprevue = ("ERROR: Index p_bus = -1 is out of bounds.\n   at: set_bus_volume_db (servers/audio_server.cpp:1)\n"
                "       [0] _ready (res://3_entities/player/player_view.gd:12)\n")
    resume = "Overall Summary: 3 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |\n"
    assert profil.test_reussi(0, attendue + resume)
    assert profil.erreurs_inattendues(imprevue + resume) == ["ERROR: Index p_bus = -1 is out of bounds."]
    assert not profil.test_reussi(0, attendue + imprevue + resume)


def test_un_avertissement_attendu_par_une_suite_n_est_pas_un_echec():
    suites = {"7_tests/a/test_a.gd": 'await assert_error(func() -> void: f()).is_push_warning("Poissons : aucune eau")\n'}
    sortie = ("WARNING: Poissons : aucune eau\n   at: push_warning (core/variant/variant_utility.cpp:1033)\n"
              "       [0] _spawn (res://3_entities/decor/fish/fish_school_view.gd:101)\n"
              "Overall Summary: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |\n")
    attendus = profil.messages_attendus(suites)
    assert attendus == {"WARNING: Poissons : aucune eau"}
    assert profil.test_reussi(0, sortie, attendus)
    assert not profil.test_reussi(0, sortie)
    assert "-rc" in profil.arguments_gdunit([]) and profil.arguments_gdunit([])[profil.arguments_gdunit([]).index("-rc") + 1] == "1"
