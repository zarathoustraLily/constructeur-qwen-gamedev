extends GdUnitTestSuite
## Le système de sauvegarde : un emplacement sans fichier est libre ; une partie neuve s'écrit, se relit, porte la
## version et la salle de départ ; une écriture remplace l'ancienne sans laisser de fichier temporaire ; un fichier
## temporaire abandonné n'abîme pas la sauvegarde ; un fichier illisible ou d'une autre version n'est jamais chargé ;
## effacer libère l'emplacement ; les fichiers sont numérotés à partir de 1.

const DOSSIER: String = "user://test_sauvegardes"


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(DOSSIER):
		return
	for nom: String in DirAccess.get_files_at(DOSSIER):
		DirAccess.remove_absolute(DOSSIER.path_join(nom))
	DirAccess.remove_absolute(DOSSIER)


func _systeme() -> SaveSystem:
	var saves: SavesDef = load("res://5_data/jeu/sauvegardes.tres").duplicate()
	saves.directory = DOSSIER
	return SaveSystem.new(saves)


func _ecrire_brut(chemin: String, texte: String) -> void:
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	var fichier := FileAccess.open(chemin, FileAccess.WRITE)
	fichier.store_string(texte)
	fichier.close()


func test_un_emplacement_sans_fichier_est_libre() -> void:
	assert_int(_systeme().state_of(0)).is_equal(SaveSystem.SlotState.EMPTY)


func test_les_fichiers_sont_numerotes_a_partir_de_un() -> void:
	assert_str(_systeme().path_of(0)).is_equal(DOSSIER.path_join("emplacement_1.json"))


func test_une_partie_neuve_s_ecrit_et_se_relit() -> void:
	var systeme := _systeme()
	assert_int(systeme.new_game(2, 12345)).is_equal(OK)
	assert_int(systeme.state_of(2)).is_equal(SaveSystem.SlotState.VALID)
	var lu: Dictionary = systeme.read(2)
	assert_int(int(lu["graine"])).is_equal(12345)
	assert_str(lu["salle"]).is_equal("camp")
	assert_int(int(lu["version"])).is_equal(1)


func test_une_ecriture_remplace_l_ancienne_sans_fichier_temporaire() -> void:
	var systeme := _systeme()
	systeme.new_game(0, 1)
	systeme.write(0, {"graine": 2, "temps_s": 30.0, "salle": "salle_1", "date": "plus tard"})
	assert_str(systeme.read(0)["salle"]).is_equal("salle_1")
	assert_bool(FileAccess.file_exists(systeme.path_of(0) + ".tmp")).is_false()


func test_un_fichier_temporaire_abandonne_n_abime_pas_la_sauvegarde() -> void:
	var systeme := _systeme()
	systeme.new_game(0, 7)
	_ecrire_brut(systeme.path_of(0) + ".tmp", "{\"coupé au milieu")
	assert_int(systeme.state_of(0)).is_equal(SaveSystem.SlotState.VALID)
	assert_int(int(systeme.read(0)["graine"])).is_equal(7)


func test_un_fichier_illisible_n_est_pas_charge() -> void:
	var systeme := _systeme()
	_ecrire_brut(systeme.path_of(1), "ceci n'est pas du JSON")
	assert_int(systeme.state_of(1)).is_equal(SaveSystem.SlotState.UNREADABLE)
	assert_dict(systeme.read(1)).is_empty()


func test_un_fichier_d_une_autre_version_n_est_pas_charge() -> void:
	var systeme := _systeme()
	_ecrire_brut(systeme.path_of(1), JSON.stringify({"version": 99, "graine": 1, "temps_s": 0.0, "salle": "camp",
			"date": "jadis"}))
	assert_int(systeme.state_of(1)).is_equal(SaveSystem.SlotState.OTHER_VERSION)
	assert_dict(systeme.read(1)).is_empty()


func test_effacer_libere_l_emplacement() -> void:
	var systeme := _systeme()
	systeme.new_game(3, 1)
	assert_int(systeme.erase(3)).is_equal(OK)
	assert_int(systeme.state_of(3)).is_equal(SaveSystem.SlotState.EMPTY)
