extends GdUnitTestSuite
## Un modèle glTF se charge à l'exécution avec son squelette et ses animations ; un modèle sans os (le coffre) n'a pas
## de squelette ; une pose tenue (le coffre fermé) garde sa piste ; le pavé du modèle a sa taille ; un fichier absent
## est une erreur, sans scène.

const HERO: String = "res://6_assets/exemple/heros/heros.glb"
const CHEST: String = "res://6_assets/exemple/props/coffre.glb"


func test_le_heros_se_charge_avec_son_squelette_et_ses_animations() -> void:
	var model: LoadedModel = ModelLoader.load_model(HERO)
	assert_str(model.error).is_empty()
	assert_int(model.skeleton.get_bone_count()).is_equal(12)
	assert_int(model.skeleton.find_bone("bassin")).is_greater_equal(0)
	assert_array(model.clips()).is_equal(["attaque", "coup_recu", "course", "dash", "debut_course", "fin_course",
			"pause", "salut_angle_0", "salut_angle_180", "salut_angle_270", "salut_angle_90"])
	model.free_scene()


func test_le_coffre_n_a_pas_de_squelette() -> void:
	var model: LoadedModel = ModelLoader.load_model(CHEST)
	assert_str(model.error).is_empty()
	assert_object(model.skeleton).is_null()
	assert_array(model.clips()).is_equal(["ferme", "fermeture", "ouvert", "ouverture"])
	model.free_scene()


func test_une_pose_tenue_garde_sa_piste() -> void:
	var model: LoadedModel = ModelLoader.load_model(CHEST)
	assert_int(model.player.get_animation("ferme").get_track_count()).is_equal(1)
	model.free_scene()


func test_le_pave_du_heros_a_sa_taille() -> void:
	var model: LoadedModel = ModelLoader.load_model(HERO)
	var box: AABB = model.bounds()
	assert_float(box.position.y).is_equal_approx(0.0, 0.001)
	assert_float(box.size.y).is_equal_approx(1.92, 0.01)
	model.free_scene()


func test_un_fichier_absent_est_une_erreur_sans_scene() -> void:
	var model: LoadedModel = ModelLoader.load_model("res://6_assets/exemple/absent.glb")
	assert_str(model.error).is_equal("fichier introuvable : res://6_assets/exemple/absent.glb")
	assert_object(model.root).is_null()
