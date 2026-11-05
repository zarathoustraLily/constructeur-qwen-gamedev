extends GdUnitTestSuite
## L'éditeur des définitions, sur une copie de la brute : ses champs sont ceux du script, sans `id` ; un entier vaut pour
## un nombre à virgule, un mauvais type ou un champ inconnu est refusé ; une définition invalide ne s'écrit pas et le
## fichier reste intact ; une définition valide s'écrit, et la ressource déjà chargée prend la nouvelle valeur ;
## l'annulation défait le dernier changement.

const ROOT: String = "user://test_definitions"
const PATH: String = "user://test_definitions/brute.tres"

var _editor: DefinitionEditor


func before_test() -> void:
	_vider()
	DirAccess.make_dir_recursive_absolute(ROOT)
	DirAccess.copy_absolute("res://5_data/ennemis/brute.tres", PATH)
	_editor = DefinitionEditor.new()
	assert_bool(_editor.open(PATH)).is_true()


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)


func _field_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for entry: Dictionary in _editor.fields():
		names.append(entry[&"name"])
	return names


func test_les_champs_sont_ceux_du_script_sans_id() -> void:
	var names: Array[StringName] = _field_names()
	assert_array(names).contains([&"max_health", &"role", &"color", &"weight"])
	assert_array(names).not_contains([&"id", &"resource_name", &"script"])
	assert_str(String(_editor.id())).is_equal("brute")


func test_les_types_sont_verifies() -> void:
	assert_bool(_editor.set_value(&"max_health", 250)).is_true()
	assert_float(_editor.value(&"max_health")).is_equal(250.0)
	assert_bool(_editor.set_value(&"max_health", "beaucoup")).is_false()
	assert_array(_editor.errors).is_equal(["max_health : float attendu"])
	assert_bool(_editor.set_value(&"id", "autre")).is_false()
	assert_array(_editor.errors).is_equal(["id : champ inconnu ou non modifiable"])


func test_une_definition_invalide_ne_s_ecrit_pas() -> void:
	var before_bytes: PackedByteArray = FileAccess.get_file_as_bytes(PATH)
	_editor.set_value(&"max_health", 0.0)
	assert_bool(_editor.save()).is_false()
	assert_array(_editor.errors).contains(["ennemi brute : santé et poids positifs requis"])
	assert_array(Array(FileAccess.get_file_as_bytes(PATH))).is_equal(Array(before_bytes))


func test_une_definition_valide_s_ecrit_et_le_projet_la_voit() -> void:
	var loaded: EnemyDef = ResourceLoader.load(PATH) as EnemyDef
	assert_float(loaded.max_health).is_equal(180.0)
	_editor.set_value(&"max_health", 260.0)
	assert_bool(_editor.save()).is_true()
	assert_float(loaded.max_health).is_equal(260.0)
	var reread: EnemyDef = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyDef
	assert_float(reread.max_health).is_equal(260.0)


func test_l_annulation_defait_le_dernier_changement() -> void:
	_editor.set_value(&"weight", 3.0)
	_editor.set_value(&"weight", 4.0)
	assert_bool(_editor.undo()).is_true()
	assert_float(_editor.value(&"weight")).is_equal(3.0)
	assert_bool(_editor.undo()).is_true()
	assert_bool(_editor.can_undo()).is_false()
