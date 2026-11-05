extends GdUnitTestSuite
## Les animations : les sept définitions se chargent et sont valides, clips vérifiés sur leur modèle ; le modèle propose
## ses six clips ; un clip absent du modèle, un état sans clip, une vitesse nulle ou un modèle manquant sont signalés.


func _animations() -> Array[AnimationDef]:
	var found: Array[AnimationDef] = []
	found.assign(DefinitionFolder.new().load_all("res://5_data/animations", AnimationDef))
	return found


func _brute() -> AnimationDef:
	return ResourceLoader.load("res://5_data/animations/brute.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as AnimationDef


func test_les_sept_animations_sont_valides_sur_leur_modele() -> void:
	var found: Array[AnimationDef] = _animations()
	assert_int(found.size()).is_equal(7)
	for definition: AnimationDef in found:
		assert_array(definition.validate()).is_empty()


func test_le_modele_propose_ses_six_clips() -> void:
	assert_array(Array(_brute().model_clips())).contains_exactly_in_any_order(["repos", "course", "attaque", "touche",
			"mort", "apparition"])


func test_un_clip_absent_du_modele_est_signale() -> void:
	var definition: AnimationDef = _brute()
	definition.clips[&"attack"] = &"danse"
	assert_array(definition.validate()).is_equal(["animation brute : clip danse absent du modèle (attack)"])


func test_un_etat_sans_clip_et_une_vitesse_nulle_sont_signales() -> void:
	var definition: AnimationDef = _brute()
	definition.clips.erase(&"hit")
	definition.speeds[&"move"] = 0.0
	assert_array(definition.validate()).contains_exactly(["animation brute : vitesse de move positive requise",
			"animation brute : état hit sans clip"])


func test_un_modele_manquant_est_signale() -> void:
	var definition: AnimationDef = _brute()
	definition.model = null
	assert_array(definition.validate()).contains(["animation brute : modèle requis"])
