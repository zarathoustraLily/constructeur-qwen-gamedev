extends GdUnitTestSuite
## Règles de l'écran de chute : caché et transparent au départ ; montré, il affiche son mot et apparaît en fondu, opaque
## au bout de son temps ; un fondu nul l'affiche d'un coup.

const DEFEAT := preload("res://4_ui/overlays/defeat_screen/defeat_screen.tscn")


func _defeat() -> DefeatScreen:
	var defeat: DefeatScreen = auto_free(DEFEAT.instantiate()) as DefeatScreen
	defeat.fade_time = 1.0
	add_child(defeat)
	return defeat


func test_cache_et_transparent_au_depart() -> void:
	var defeat: DefeatScreen = _defeat()
	assert_bool(defeat.visible).is_false()
	assert_float(defeat.modulate.a).is_equal(0.0)


func test_montre_il_affiche_son_mot_en_fondu() -> void:
	var defeat: DefeatScreen = _defeat()
	defeat.show_defeat("TERRASSÉ")
	assert_bool(defeat.visible).is_true()
	assert_str(defeat.shown_text()).is_equal("TERRASSÉ")
	defeat.advance(0.5)
	assert_float(defeat.modulate.a).is_equal_approx(0.5, 0.0001)
	defeat.advance(1.0)
	assert_float(defeat.modulate.a).is_equal(1.0)


func test_un_fondu_nul_l_affiche_d_un_coup() -> void:
	var defeat: DefeatScreen = _defeat()
	defeat.fade_time = 0.0
	defeat.show_defeat("TERRASSÉ")
	defeat.advance(0.016)
	assert_float(defeat.modulate.a).is_equal(1.0)
