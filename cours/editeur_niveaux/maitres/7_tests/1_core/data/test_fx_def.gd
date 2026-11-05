extends GdUnitTestSuite
## Les effets : les trois définitions du jeu se chargent et sont valides ; un débit nul est signalé ; un effet placé
## inconnu est signalé ; l'aperçu compte débit × durée de vie particules, borné, donne la même image au même instant,
## et une particule naît au centre, petite et opaque, puis s'éloigne en s'effaçant.


func _effects() -> Array[FxDef]:
	var effects: Array[FxDef] = []
	effects.assign(DefinitionFolder.new().load_all("res://5_data/effets", FxDef))
	return effects


func test_les_trois_effets_se_chargent_et_sont_valides() -> void:
	var effects: Array[FxDef] = _effects()
	assert_int(effects.size()).is_equal(3)
	for effect: FxDef in effects:
		assert_array(effect.validate()).is_empty()


func test_un_debit_nul_est_signale() -> void:
	var effect: FxDef = _effects()[0].duplicate() as FxDef
	effect.rate = 0.0
	assert_array(effect.validate()).is_equal(["effet %s : débit, durée de vie et taille positifs requis" % effect.id])


func test_un_effet_place_inconnu_est_signale() -> void:
	var room: RoomData = ResourceLoader.load("res://5_data/salles/pont.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_array(FxDef.placement_errors(room, _effects())).is_empty()
	var ids: PackedStringArray = room.effect_ids
	ids[0] = "arc_en_ciel"
	room.effect_ids = ids
	assert_array(FxDef.placement_errors(room, _effects())).is_equal(["effet 0 : effet inconnu arc_en_ciel"])


func test_l_apercu_compte_ses_particules_et_se_repete() -> void:
	var smoke: FxDef = _effects().filter(func(effect: FxDef) -> bool: return effect.id == &"fumee")[0]
	assert_int(EffectPreview.count(smoke)).is_equal(roundi(smoke.rate * smoke.lifetime_s))
	var first: Array[Dictionary] = EffectPreview.particles(smoke, Vector2(3, 4), 1.25)
	assert_array(EffectPreview.particles(smoke, Vector2(3, 4), 1.25)).is_equal(first)
	var dense: FxDef = smoke.duplicate() as FxDef
	dense.rate = 10000.0
	assert_int(EffectPreview.count(dense)).is_equal(EffectPreview.MAX_PARTICLES)


func test_une_particule_nait_au_centre_puis_s_eloigne_en_s_effacant() -> void:
	var sparks: FxDef = _effects().filter(func(effect: FxDef) -> bool: return effect.id == &"etincelles")[0]
	var born: Dictionary = EffectPreview.particles(sparks, Vector2.ZERO, 0.0)[0]
	assert_vector(born[&"position"]).is_equal(Vector2.ZERO)
	assert_float(born[&"alpha"]).is_equal(sparks.color.a)
	var later: Dictionary = EffectPreview.particles(sparks, Vector2.ZERO, sparks.lifetime_s * 0.5)[0]
	assert_float(Vector2(later[&"position"]).length()).is_greater(0.0)
	assert_float(later[&"alpha"]).is_less(born[&"alpha"])
	assert_float(later[&"radius"]).is_greater(born[&"radius"])
