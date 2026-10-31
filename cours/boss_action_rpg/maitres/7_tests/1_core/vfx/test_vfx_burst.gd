extends GdUnitTestSuite
## Règles d'un effet bref : au repos, il est caché et sa lumière éteinte ; `play` le montre, relance toutes ses particules
## et allume sa lueur et sa lumière ; elles baissent, et sont éteintes au bout de `duration` ; il reste visible tant que
## ses particules vivent, puis se cache ; rejouer un effet en cours le remet à neuf ; sans droit à la lumière, elle reste
## éteinte, et le reste de l'effet joue ; les effets du jeu sont en réserve : aucun ne garde son AnimationPlayer.

const MUZZLE := preload("res://6_assets/VFX/combat/muzzle_flash.tscn")
const IMPACT := preload("res://6_assets/VFX/combat/shot_impact.tscn")
const DT: float = 1.0 / 60.0


func _burst(scene: PackedScene) -> VfxBurst:
	var burst: VfxBurst = auto_free(scene.instantiate()) as VfxBurst
	add_child(burst)
	return burst


func _lumiere(burst: VfxBurst) -> OmniLight3D:
	return burst.get_node("Light") as OmniLight3D


func _particules(burst: VfxBurst) -> Array[GPUParticles3D]:
	var liste: Array[GPUParticles3D] = []
	for child: Node in burst.get_children():
		if child is GPUParticles3D:
			liste.append(child as GPUParticles3D)
	return liste


func test_au_repos_il_est_cache_et_sa_lumiere_eteinte() -> void:
	var burst: VfxBurst = _burst(MUZZLE)
	assert_bool(burst.visible).is_false()
	assert_bool(_lumiere(burst).visible).is_false()
	assert_bool(burst.is_processing()).is_false()
	for particles: GPUParticles3D in _particules(burst):
		assert_bool(particles.emitting).is_false()
		assert_bool(particles.one_shot).is_true()


func test_jouer_le_montre_relance_ses_particules_et_allume_sa_lumiere() -> void:
	var burst: VfxBurst = _burst(MUZZLE)
	burst.play()
	assert_bool(burst.visible).is_true()
	assert_int(_particules(burst).size()).is_equal(3)
	for particles: GPUParticles3D in _particules(burst):
		assert_bool(particles.emitting).is_true()
	assert_bool(_lumiere(burst).visible).is_true()
	assert_float(_lumiere(burst).light_energy).is_equal(burst.light_energy)
	assert_bool((burst.get_node("Glow") as Node3D).visible).is_true()


func test_la_lueur_et_la_lumiere_baissent_et_s_eteignent_au_bout_de_sa_duree() -> void:
	var burst: VfxBurst = _burst(MUZZLE)
	burst.play()
	burst.update(burst.duration * 0.5)
	assert_float(burst.flare).is_equal_approx(0.5, 0.001)
	assert_float(_lumiere(burst).light_energy).is_equal_approx(burst.light_energy * 0.25, 0.001)
	assert_float((burst.get_node("Glow") as Node3D).scale.x).is_equal_approx(0.5, 0.001)
	burst.update(burst.duration * 0.5)
	assert_float(burst.flare).is_equal(0.0)
	assert_bool(_lumiere(burst).visible).is_false()
	assert_bool((burst.get_node("Glow") as Node3D).visible).is_false()


func test_il_reste_visible_tant_que_ses_particules_vivent_puis_se_cache() -> void:
	var burst: VfxBurst = _burst(IMPACT)
	burst.play()
	var plus_longue: float = 0.0
	for particles: GPUParticles3D in _particules(burst):
		plus_longue = maxf(plus_longue, particles.lifetime)
	assert_float(plus_longue).is_greater(burst.duration)
	burst.update(burst.duration)
	assert_bool(burst.visible).is_true()
	burst.update(plus_longue - burst.duration)
	assert_bool(burst.visible).is_false()
	assert_bool(burst.is_processing()).is_false()


func test_rejouer_un_effet_en_cours_le_remet_a_neuf() -> void:
	var burst: VfxBurst = _burst(MUZZLE)
	burst.play()
	burst.update(burst.duration * 0.8)
	burst.play()
	assert_float(burst.flare).is_equal(1.0)
	assert_float(_lumiere(burst).light_energy).is_equal(burst.light_energy)


func test_sans_droit_a_la_lumiere_elle_reste_eteinte_et_le_reste_joue() -> void:
	var burst: VfxBurst = _burst(MUZZLE)
	burst.light_allowed = false
	burst.play()
	assert_bool(_lumiere(burst).visible).is_false()
	assert_bool(burst.visible).is_true()
	assert_bool(_particules(burst)[0].emitting).is_true()


func test_il_entre_dans_le_groupe_des_effets_sans_animationplayer() -> void:
	for scene: PackedScene in [MUZZLE, IMPACT]:
		var burst: VfxBurst = _burst(scene)
		assert_bool(burst.is_in_group(VfxBurst.GROUP)).is_true()
		assert_array(burst.find_children("*", "AnimationPlayer", true, false)).is_empty()
		assert_array(burst.find_children("*", "AudioStreamPlayer3D", true, false)).is_empty()
