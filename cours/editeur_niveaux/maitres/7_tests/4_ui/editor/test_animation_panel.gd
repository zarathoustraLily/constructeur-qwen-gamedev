extends GdUnitTestSuite
## Le panneau des animations, sur une copie : il propose les clips du modèle ; changer le clip d'un état puis enregistrer
## écrit la définition ; un clip absent du modèle est signalé et l'enregistrement est refusé.

const ROOT: String = "user://test_animations"

var _panel: AnimationPanel


func before_test() -> void:
	_vider()
	DirAccess.make_dir_recursive_absolute(ROOT)
	DirAccess.copy_absolute("res://5_data/animations/brute.tres", ROOT.path_join("brute.tres"))
	_panel = auto_free(AnimationPanel.new())
	add_child(_panel)
	_panel.setup(ROOT)
	_panel.open_index(0)


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)


func test_le_panneau_propose_les_clips_du_modele() -> void:
	assert_int(_panel.offered_clips().size()).is_equal(6)
	assert_str(_panel.messages()).is_empty()


func test_changer_un_clip_puis_enregistrer_ecrit_la_definition() -> void:
	assert_bool(_panel.choose_clip(&"attack", &"touche")).is_true()
	assert_bool(_panel.save()).is_true()
	assert_str(_panel.messages()).is_equal("brute enregistré")
	var reread: AnimationDef = ResourceLoader.load(ROOT.path_join("brute.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_str(String(reread.clips[&"attack"])).is_equal("touche")


func test_un_clip_absent_du_modele_est_refuse_a_l_enregistrement() -> void:
	_panel.choose_clip(&"attack", &"danse")
	assert_str(_panel.messages()).contains("clip danse absent du modèle (attack)")
	assert_bool(_panel.save()).is_false()
