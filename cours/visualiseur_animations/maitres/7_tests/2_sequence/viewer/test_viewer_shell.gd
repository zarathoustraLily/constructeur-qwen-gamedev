extends GdUnitTestSuite
## La coquille du visualiseur s'ouvre : elle lit les réglages du projet, liste les assets d'exemple par catégorie et dit
## combien elle en a trouvé ; un dossier introuvable est dit dans la barre d'état.
#@ 2+
## Choisir un asset le montre et liste ses animations ; sa première est « pause » ; choisir une animation la joue ; un
## fichier absent est dit dans la barre d'état, sans rien montrer.
#@ 3+
## La caméra cadre l'asset choisi ; la vue du jeu se prend et se quitte ; un clip fait pour plusieurs angles tient une
## seule ligne, et passe à la variante de l'angle de la caméra quand on tourne.
#@ all

const SHELL: PackedScene = preload("res://2_sequence/viewer/viewer_shell.tscn")
const ROOT: String = "user://test_coquille"


func after_test() -> void:
	if DirAccess.dir_exists_absolute(ROOT):
		for file: String in DirAccess.get_files_at(ROOT):
			DirAccess.remove_absolute(ROOT.path_join(file))
		DirAccess.remove_absolute(ROOT)


func _shell(config: String = ViewerShell.CONFIG_PATH) -> ViewerShell:
	var shell: ViewerShell = auto_free(SHELL.instantiate())
	shell.config_path = config
#@ 2+
	shell.manual = true
#@ all
	add_child(shell)
	return shell


func _config(text: String) -> String:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var path: String = ROOT.path_join("config.json")
	var out: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	out.store_string(text)
	out.close()
	return path


func test_la_coquille_liste_les_assets_par_categorie() -> void:
	var shell: ViewerShell = _shell()
	assert_str(shell.status()).is_equal("5 assets")
	assert_array(shell.asset_list().lines()).is_equal(["Héros (1)", "  heros · 3D", "Ennemis (1)", "  golem · 3D",
			"Props (1)", "  coffre · 3D", "Effets (2)", "  etincelle · 2D", "  flamme · 2D"])


func test_un_dossier_introuvable_est_dit_dans_la_barre_d_etat() -> void:
	var shell: ViewerShell = _shell(_config(
			"{\"sources\": [{\"dossier\": \"user://nulle_part\", \"categorie\": \"boss\"}]}"))
	assert_str(shell.status()).is_equal("0 asset · 1 problème : dossier introuvable : user://nulle_part")
	assert_int(shell.asset_list().entry_count()).is_equal(0)
#@ 2+


func test_choisir_un_asset_le_montre_et_liste_ses_animations() -> void:
	var shell: ViewerShell = _shell()
	assert_bool(shell.choose_asset("heros/heros")).is_true()
	assert_object(shell.stage().subject()).is_instanceof(ModelView)
	assert_str(shell.stage().subject().current_clip()).is_equal("pause")
#@ 2
	assert_str(shell.status()).is_equal("heros/heros · 11 animations · pause")
	assert_int(shell.clip_list().item_count).is_equal(11)
#@ 2+


func test_choisir_une_animation_la_joue() -> void:
	var shell: ViewerShell = _shell()
	shell.choose_asset("heros/heros")
	assert_bool(shell.clip_list().choose("course")).is_true()
	assert_str(shell.stage().subject().current_clip()).is_equal("course")
	assert_bool(shell.play_clip("voler")).is_false()


func test_une_animation_2d_se_montre() -> void:
	var shell: ViewerShell = _shell()
	shell.choose_asset("effet/flamme/flamme")
	assert_object(shell.stage().subject()).is_instanceof(SpriteView)
	assert_str(shell.status()).starts_with("effet/flamme/flamme · 1 animation · flamme")


func test_un_fichier_absent_est_dit_sans_rien_montrer() -> void:
	var shell: ViewerShell = _shell()
	var entry: AssetEntry = AssetEntry.new()
	entry.id = "heros/absent"
	entry.path = "user://absent.glb"
	shell.show_asset(entry)
	assert_object(shell.stage().subject()).is_null()
	assert_str(shell.status()).is_equal("heros/absent : fichier introuvable : user://absent.glb")
#@ 3+


func test_la_camera_cadre_l_asset_et_la_vue_libre_est_dite() -> void:
	var shell: ViewerShell = _shell()
	shell.choose_asset("heros/heros")
	assert_str(shell.status()).is_equal("heros/heros · 11 animations · pause · angle 0° · vue libre")
	var camera: Camera3D = shell.stage().camera()
	assert_float(camera.transform.origin.distance_to(shell.orbit().rig.target)).is_equal_approx(
			shell.orbit().rig.distance, 0.001)
	assert_float(shell.orbit().rig.target.y).is_equal_approx(0.96, 0.01)


func test_un_clip_a_plusieurs_angles_tient_une_seule_ligne() -> void:
	var shell: ViewerShell = _shell()
	shell.choose_asset("heros/heros")
	assert_array(shell.clip_list().labels()).is_equal(["attaque", "coup_recu", "course", "dash", "debut_course",
			"fin_course", "pause", "salut · 4 angles"])


func test_la_vue_du_jeu_se_prend_et_se_quitte_en_tournant() -> void:
	var shell: ViewerShell = _shell()
	shell.choose_asset("heros/heros")
	shell.orbit().toggle_game_view()
	assert_int(shell.stage().camera().projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	assert_str(shell.status()).ends_with("angle 45° · vue du jeu")
	assert_bool(shell.play_clip("salut")).is_true()
	assert_str(shell.stage().subject().current_clip()).is_equal("salut_angle_0")
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.relative = Vector2(-150, 0)
	assert_bool(shell.orbit().handle(drag)).is_true()
	assert_int(shell.stage().camera().projection).is_equal(Camera3D.PROJECTION_PERSPECTIVE)
	assert_str(shell.stage().subject().current_clip()).is_equal("salut_angle_90")
	assert_str(shell.status()).ends_with("salut_angle_90 · angle 105° · vue libre")
#@ all
