extends GdUnitTestSuite
## Règles de la scène principale : au départ, le menu principal est ouvert et les options cachées ; Options
## ouvre les options sur les volumes actuels ; Retour revient au menu ; un curseur règle le service audio.
#@ 2+
## Commandes ouvre le menu des commandes, et le fermer revient au menu principal.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func after_test() -> void:
	AudioManager.set_volume(AudioManager.MUSIC, 1.0)
	AudioManager.set_volume(AudioManager.SFX, 1.0)


func _main() -> Node:
	var main: Node = auto_free(MAIN.instantiate())
	add_child(main)
	return main


func test_au_depart_le_menu_principal_est_ouvert() -> void:
	var main: Node = _main()
	assert_bool((main.get_node("MainMenu") as Control).visible).is_true()
	assert_bool((main.get_node("OptionsMenu") as Control).visible).is_false()


func test_options_ouvre_les_options_sur_les_volumes_actuels() -> void:
	AudioManager.set_volume(AudioManager.MUSIC, 0.6)
	var main: Node = _main()
	(main.get_node("MainMenu") as MainMenu).options_requested.emit()
	assert_bool((main.get_node("MainMenu") as Control).visible).is_false()
	assert_bool((main.get_node("OptionsMenu") as Control).visible).is_true()
	var slider: HSlider = main.get_node("OptionsMenu/Center/Rows/Music/Slider") as HSlider
	assert_float(slider.value).is_equal_approx(0.6, 0.001)


func test_retour_revient_au_menu() -> void:
	var main: Node = _main()
	(main.get_node("MainMenu") as MainMenu).options_requested.emit()
	(main.get_node("OptionsMenu") as OptionsMenu).closed.emit()
	assert_bool((main.get_node("MainMenu") as Control).visible).is_true()
	assert_bool((main.get_node("OptionsMenu") as Control).visible).is_false()


func test_un_curseur_regle_le_service_audio() -> void:
	var main: Node = _main()
	(main.get_node("OptionsMenu/Center/Rows/Sfx/Slider") as HSlider).value = 0.5
	assert_float(AudioManager.volume(AudioManager.SFX)).is_equal_approx(0.5, 0.001)
#@ 2+


func test_commandes_ouvre_le_menu_des_commandes_puis_revient() -> void:
	var main: Node = _main()
	(main.get_node("MainMenu") as MainMenu).controls_requested.emit()
	assert_bool((main.get_node("RemapMenu") as Control).visible).is_true()
	assert_bool((main.get_node("MainMenu") as Control).visible).is_false()
	(main.get_node("RemapMenu") as RemapMenu).closed.emit()
	assert_bool((main.get_node("MainMenu") as Control).visible).is_true()
	assert_bool((main.get_node("RemapMenu") as Control).visible).is_false()
#@ all
