extends GdUnitTestSuite
## Règles de la sauvegarde de partie : un état se relit à l'identique, ses nombres en flottants (JSON) ; le texte
## porte la version actuelle ; une sauvegarde de la version 1 est migrée (hp devient health) ; un texte illisible, une
## version inconnue ou plus récente donnent un état vide ; un fichier absent aussi.

const PATH := "user://test_partie.json"


func after_test() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_un_etat_se_relit_a_l_identique() -> void:
	var state: Dictionary = {"level": 3, "health": 42.5, "items": ["clef", "carte"]}
	assert_int(SaveGame.write(PATH, state)).is_equal(OK)
	assert_dict(SaveGame.read(PATH)).is_equal({"level": 3.0, "health": 42.5, "items": ["clef", "carte"]})


func test_le_texte_porte_la_version_actuelle() -> void:
	var json: JSON = JSON.new()
	assert_int(json.parse(SaveGame.encode({"level": 1}))).is_equal(OK)
	var parsed: Dictionary = json.data
	assert_int(int(parsed["version"])).is_equal(SaveGame.VERSION)
	assert_dict(parsed["state"]).is_equal({"level": 1.0})


func test_une_sauvegarde_de_la_version_1_est_migree() -> void:
	var old: String = JSON.stringify({"version": 1, "hp": 30, "level": 2})
	assert_dict(SaveGame.decode(old)).is_equal({"health": 30.0, "level": 2.0})
	assert_dict(SaveGame.migrate({"version": 2, "state": {}})).is_equal({"version": 2, "state": {}})


func test_un_texte_illisible_ou_d_une_autre_version_est_refuse() -> void:
	assert_dict(SaveGame.decode("pas du json {")).is_empty()
	assert_dict(SaveGame.decode("[1, 2, 3]")).is_empty()
	assert_dict(SaveGame.decode(JSON.stringify({"version": 9, "state": {"level": 1}}))).is_empty()
	assert_dict(SaveGame.decode(JSON.stringify({"version": 2, "state": "rien"}))).is_empty()


func test_un_fichier_absent_donne_un_etat_vide() -> void:
	assert_dict(SaveGame.read("user://nulle_part.json")).is_empty()
