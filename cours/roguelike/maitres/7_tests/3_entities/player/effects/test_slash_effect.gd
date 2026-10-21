extends GdUnitTestSuite
## Règles de l'effet de lame : il n'est visible que pendant sa forme de coup, et son effacement suit celui que
## l'animation écrit dans l'emplacement de l'arme.

const ANIMATED_PLAYER := preload("res://3_entities/player/animated_player.tscn")

var _model: Node3D
var _slot: WeaponSlot
var _effect: MeshInstance3D


func before_test() -> void:
	_model = auto_free(ANIMATED_PLAYER.instantiate())
	add_child(_model)
	_slot = _model.get_node("Rig_Medium/Skeleton3D/WeaponSlot") as WeaponSlot
	_effect = _slot.get_node("LazerSword/SlashVFX") as MeshInstance3D
	# L'arbre d'animation ne doit pas réécrire l'emplacement pendant le test.
	(_model.get_node("AnimationTree") as AnimationTree).active = false


func test_il_ne_se_voit_que_pendant_la_taille() -> void:
	_slot.attack_mode = WeaponSlot.Mode.STAB
	await get_tree().process_frame
	assert_bool(_effect.visible).is_false()
	_slot.attack_mode = WeaponSlot.Mode.SLASH
	await get_tree().process_frame
	assert_bool(_effect.visible).is_true()


func test_son_effacement_suit_l_emplacement_de_l_arme() -> void:
	_slot.vfx_threshold = 0.25
	await get_tree().process_frame
	var material := _effect.material_override as ShaderMaterial
	assert_float(material.get_shader_parameter(&"threshold") as float).is_equal_approx(0.25, 0.0001)
