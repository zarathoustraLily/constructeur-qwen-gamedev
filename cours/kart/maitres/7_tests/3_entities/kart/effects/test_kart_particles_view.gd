extends GdUnitTestSuite
## Règles des particules du kart : la glissade fume, les étincelles s'allument bleues puis orange, le turbo
## crache ses flammes puis s'éteint, une figure lance sa gerbe d'étincelles et le tour du modèle. Elles suivent
## les signaux du kart.

const KART := preload("res://3_entities/kart/kart.tscn")

var _kart: Kart
var _view: KartParticlesView


func before_test() -> void:
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	add_child(_kart)
	_view = _kart.get_node("KartParticles") as KartParticlesView


func _emitting(parent: Node3D) -> bool:
	for particles: Node in parent.find_children("*", "GPUParticles3D", true, false):
		if not (particles as GPUParticles3D).emitting:
			return false
	return true


func test_au_depart_tout_est_eteint() -> void:
	assert_bool((_view.sliding_particles.get_child(0) as GPUParticles3D).emitting).is_false()
	assert_bool(_view.drift_sparks.visible).is_false()
	assert_bool((_view.boost_particles.get_child(0) as GPUParticles3D).emitting).is_false()


func test_la_glissade_fume() -> void:
	_kart.drift_stage_changed.emit(Kart.DriftStage.SLIDING)
	assert_bool(_emitting(_view.sliding_particles)).is_true()
	assert_bool(_view.drift_sparks.visible).is_false()


func test_les_etincelles_sont_bleues_puis_orange() -> void:
	_kart.drift_stage_changed.emit(Kart.DriftStage.SPARKS)
	assert_bool(_view.drift_sparks.visible).is_true()
	assert_that(_view.sparks_material.emission).is_equal(_view.sparks_color)
	_kart.drift_stage_changed.emit(Kart.DriftStage.HOT_SPARKS)
	assert_that(_view.sparks_material.emission).is_equal(_view.hot_sparks_color)
	_kart.drift_stage_changed.emit(Kart.DriftStage.NONE)
	assert_bool(_view.drift_sparks.visible).is_false()


func test_le_turbo_crache_ses_flammes_puis_s_eteint() -> void:
	_kart.boost_changed.emit(true)
	assert_bool(_emitting(_view.boost_particles)).is_true()
	_kart.boost_changed.emit(false)
	assert_bool((_view.boost_particles.get_child(0) as GPUParticles3D).emitting).is_false()


func test_une_figure_lance_sa_gerbe_et_son_tour() -> void:
	_kart.tricked.emit()
	assert_bool(_view.trick_sparks.emitting).is_true()
	var player := _kart.get_node("Visual/Kart/AnimationPlayer") as AnimationPlayer
	assert_bool(player.is_playing()).is_true()
	assert_str(str(player.current_animation)).is_equal("trick")
