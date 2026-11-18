extends GdUnitTestSuite
## Un modèle montré joue ses animations : les boucles de l'accompagnement s'appliquent, la lecture avance d'autant
## qu'on veut, un clip inconnu est refusé. Le coffre s'ouvre, puis « ferme » le remet fermé : sa pose tenue a gardé sa
## piste. Retirer le modèle le libère.
#@ 3+
## Changer d'angle en cours de lecture passe à la variante la plus proche, au même instant.
#@ all

const HERO: String = "res://6_assets/exemple/heros/heros.glb"
const CHEST: String = "res://6_assets/exemple/props/coffre.glb"


func _entry(path: String) -> AssetEntry:
	var entry: AssetEntry = AssetEntry.new()
	entry.path = path
	return entry


func _subject(path: String) -> ModelView:
	var subject: ModelView = auto_free(ModelView.new())
	subject.manual = true
	add_child(subject)
	assert_bool(subject.show_model(ModelLoader.load_model(path), AssetSidecar.load_for(_entry(path)))).is_true()
	return subject


func test_les_boucles_de_l_accompagnement_s_appliquent() -> void:
	var subject: ModelView = _subject(HERO)
	assert_int(subject.model.player.get_animation("course").loop_mode).is_equal(Animation.LOOP_LINEAR)
	assert_int(subject.model.player.get_animation("attaque").loop_mode).is_equal(Animation.LOOP_NONE)


func test_la_lecture_avance_d_autant_qu_on_veut() -> void:
	var subject: ModelView = _subject(HERO)
	assert_bool(subject.play("pause")).is_true()
	subject.advance(0.5)
	assert_str(subject.current_clip()).is_equal("pause")
	assert_float(subject.position_s()).is_equal_approx(0.5, 0.001)


func test_un_clip_inconnu_est_refuse() -> void:
	var subject: ModelView = _subject(HERO)
	assert_bool(subject.play("voler")).is_false()
	assert_str(subject.current_clip()).is_empty()


func test_le_coffre_s_ouvre_puis_ferme_le_referme() -> void:
	var subject: ModelView = _subject(CHEST)
	subject.play("ouverture")
	subject.advance(0.7)
	assert_float(rad_to_deg(subject.part("couvercle").rotation.x)).is_equal_approx(-105.0, 0.5)
	subject.play("ferme")
	subject.advance(0.1)
	assert_float(rad_to_deg(subject.part("couvercle").rotation.x)).is_equal_approx(0.0, 0.5)


func test_retirer_le_modele_le_libere() -> void:
	var subject: ModelView = _subject(HERO)
	subject.clear()
	assert_int(subject.get_child_count()).is_equal(0)
	assert_array(subject.clips()).is_empty()
#@ 3+


func test_changer_d_angle_passe_a_la_variante_au_meme_instant() -> void:
	var subject: ModelView = _subject(HERO)
	assert_bool(subject.play_base("salut")).is_true()
	assert_str(subject.current_clip()).is_equal("salut_angle_0")
	subject.advance(0.3)
	subject.set_view_angle(100.0)
	assert_str(subject.current_clip()).is_equal("salut_angle_90")
	assert_str(subject.current_base()).is_equal("salut")
	assert_float(subject.position_s()).is_equal_approx(0.3, 0.001)
#@ all
