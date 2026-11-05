extends GdUnitTestSuite
## L'enregistreur stable : les identifiants de ressources externes sont renommés dans leur ordre d'apparition, partout
## où ils servent ; deux enregistrements de la même ressource, même vers deux fichiers, donnent les mêmes octets ; aucun
## fichier voisin ne reste.

const ROOT: String = "user://test_enregistreur"
const TEXT: String = "[gd_resource type=\"Resource\" format=4]\n\n[ext_resource type=\"Script\" path=\"res://a.gd\" id=\"1_8umkc\"]\n[ext_resource type=\"Texture2D\" path=\"res://b.png\" id=\"2_x0q1z\"]\n\n[resource]\nscript = ExtResource(\"1_8umkc\")\natlas = ExtResource(\"2_x0q1z\")\n"

var _saver: StableSaver


func before_test() -> void:
	_vider()
	DirAccess.make_dir_recursive_absolute(ROOT)
	_saver = StableSaver.new()


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)


func test_les_identifiants_sont_renommes_dans_leur_ordre() -> void:
	var text: String = _saver.stable_text(TEXT)
	assert_str(text).contains("id=\"1_ext\"]").contains("id=\"2_ext\"]")
	assert_str(text).contains("script = ExtResource(\"1_ext\")").contains("atlas = ExtResource(\"2_ext\")")
	assert_str(text).not_contains("8umkc").not_contains("x0q1z")


func test_un_texte_deja_stable_ne_change_plus() -> void:
	var once: String = _saver.stable_text(TEXT)
	assert_str(_saver.stable_text(once)).is_equal(once)


func test_deux_enregistrements_donnent_les_memes_octets() -> void:
	var room: RoomData = ResourceLoader.load("res://5_data/salles/pont.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_int(_saver.save(room, ROOT.path_join("a.tres"))).is_equal(OK)
	assert_int(_saver.save(room, ROOT.path_join("b.tres"))).is_equal(OK)
	var first: PackedByteArray = FileAccess.get_file_as_bytes(ROOT.path_join("a.tres"))
	assert_array(Array(FileAccess.get_file_as_bytes(ROOT.path_join("b.tres")))).is_equal(Array(first))
	assert_array(Array(DirAccess.get_files_at(ROOT))).is_equal(["a.tres", "b.tres"])
