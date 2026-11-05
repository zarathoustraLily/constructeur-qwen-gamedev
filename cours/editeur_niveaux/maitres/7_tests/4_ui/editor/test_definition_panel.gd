extends GdUnitTestSuite
## Le panneau des paramètres, sur une copie des ennemis : il liste les définitions de la famille ; il construit une ligne
## par champ de la définition ouverte ; un changement invalide le dit avant même d'enregistrer, et l'enregistrement est
## refusé ; un changement valide s'enregistre et le dit.

const ROOT: String = "user://test_parametres"

var _panel: DefinitionPanel


func before_test() -> void:
	_vider()
	DirAccess.make_dir_recursive_absolute(ROOT)
	for file: String in DirAccess.get_files_at("res://5_data/ennemis"):
		if file.get_extension() == "tres":
			DirAccess.copy_absolute("res://5_data/ennemis".path_join(file), ROOT.path_join(file))
	_panel = auto_free(DefinitionPanel.new())
	add_child(_panel)
	_panel.setup({"Ennemis": ROOT})


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)


func test_le_panneau_liste_et_ouvre_une_definition() -> void:
	_panel.open_index(0)
	assert_bool(_panel.editor().is_open()).is_true()
	assert_str(String(_panel.editor().id())).is_equal("bombe")


func test_un_changement_invalide_le_dit_et_ne_s_enregistre_pas() -> void:
	_panel.open_index(0)
	_panel.editor().set_value(&"weight", 0.0)
	assert_bool(_panel.save()).is_false()
	assert_str(_panel.messages()).starts_with("Enregistrement impossible : ennemi bombe : santé et poids positifs requis")


func test_un_changement_valide_s_enregistre() -> void:
	_panel.open_index(0)
	var saved: Array[String] = []
	_panel.definition_saved.connect(func(path: String) -> void: saved.append(path))
	_panel.editor().set_value(&"damage", 9.0)
	assert_bool(_panel.save()).is_true()
	assert_str(_panel.messages()).is_equal("bombe enregistré")
	assert_array(saved).is_equal([ROOT.path_join("bombe.tres")])
	var reread: EnemyDef = ResourceLoader.load(ROOT.path_join("bombe.tres"), "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_float(reread.damage).is_equal(9.0)
