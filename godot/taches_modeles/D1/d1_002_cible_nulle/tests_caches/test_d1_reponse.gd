extends GdUnitTestSuite
## Juge D1 : la réponse res://reponse.json doit donner la bonne catégorie et la bonne position.

const CATEGORIE := "null_instance"
const FICHIER := "res://scripts/ghost.gd"
const LIGNE := 28


func _reponse() -> Dictionary:
	if not FileAccess.file_exists("res://reponse.json"):
		return {}
	var donnees = JSON.parse_string(FileAccess.get_file_as_string("res://reponse.json"))
	return donnees if donnees is Dictionary else {}


func test_categorie() -> void:
	assert_str(str(_reponse().get("categorie", ""))).is_equal(CATEGORIE)


func test_fichier() -> void:
	assert_str(str(_reponse().get("fichier", ""))).is_equal(FICHIER)


func test_ligne() -> void:
	var ligne = _reponse().get("ligne", -1)
	assert_bool(ligne is float or ligne is int).is_true()
	assert_int(int(ligne)).is_equal(LIGNE)
