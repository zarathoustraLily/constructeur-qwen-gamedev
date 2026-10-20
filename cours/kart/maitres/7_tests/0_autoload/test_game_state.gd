extends GdUnitTestSuite
## Règles des variables générales : leurs valeurs de départ, et leur lien avec les paramètres
## globaux de shader déclarés dans project.godot.
## Sans fenêtre, le moteur ne garde pas la valeur des paramètres globaux (RenderingServer renvoie
## null) : leur arrivée dans les shaders se vérifie à l'écran, pas ici.

const GAME_STATE := "res://0_autoload/game_state.gd"
#@ 6-10
const PARTAGEES: Array[StringName] = [&"player_position", &"wind_direction", &"wind_strength"]
#@ 11+
const PARTAGEES: Array[StringName] = [&"player_position", &"rain_intensity", &"rain_wetness", &"wind_direction", &"wind_strength"]
#@ all


func _etat_neuf() -> Node:
	return auto_free(load(GAME_STATE).new())


func _valeur_du_projet(nom: String) -> Variant:
	return ProjectSettings.get_setting("shader_globals/" + nom)["value"]


func test_chaque_variable_partagee_a_son_parametre_global() -> void:
	var declares := RenderingServer.global_shader_parameter_get_list()
	for nom: StringName in PARTAGEES:
		assert_bool(nom in declares).override_failure_message("paramètre global non déclaré : " + nom).is_true()
		assert_bool(nom in GameState).override_failure_message("GameState n'a pas de variable " + nom).is_true()
#@ 6-10


func test_le_joueur_part_de_zero() -> void:
	assert_vector(_etat_neuf().player_position).is_equal(Vector3.ZERO)
#@ 11+


func test_le_joueur_et_la_pluie_partent_de_zero() -> void:
	var etat := _etat_neuf()
	assert_vector(etat.player_position).is_equal(Vector3.ZERO)
	assert_float(etat.rain_intensity).is_equal(0.0)
	assert_float(etat.rain_wetness).is_equal(0.0)
#@ all


func test_le_vent_part_des_valeurs_du_projet() -> void:
	var etat := _etat_neuf()
	assert_vector(etat.wind_direction).is_equal(_valeur_du_projet("wind_direction"))
	assert_float(etat.wind_strength).is_equal(_valeur_du_projet("wind_strength"))


func test_un_reglage_absent_prend_la_valeur_par_defaut() -> void:
	assert_float(_etat_neuf()._reglage("reglage_absent", 3.5)).is_equal(3.5)


func test_une_valeur_ecrite_se_relit() -> void:
	var etat := _etat_neuf()
	etat.player_position = Vector3(1, 2, 3)
#@ 11+
	etat.rain_intensity = 0.4
	etat.rain_wetness = 0.25
#@ all
	etat.wind_direction = Vector3(1, 0, 0)
	etat.wind_strength = 5.0
	assert_vector(etat.player_position).is_equal(Vector3(1, 2, 3))
#@ 11+
	assert_float(etat.rain_intensity).is_equal(0.4)
	assert_float(etat.rain_wetness).is_equal(0.25)
#@ all
	assert_vector(etat.wind_direction).is_equal(Vector3(1, 0, 0))
	assert_float(etat.wind_strength).is_equal(5.0)
