extends GdUnitTestSuite
#@ 1-5
## La coquille de l'éditeur s'ouvre : elle charge, dit qu'aucune salle n'est ouverte, et signale chaque texte qu'elle
## écrit dans sa barre d'état.
#@ 6+
## La coquille de l'éditeur s'ouvre sur la salle de départ et dit ce qu'elle contient ; une salle introuvable est
## signalée dans la barre d'état sans rien ouvrir ; chaque texte écrit dans la barre d'état est signalé.
#@ 8+
## Un asset choisi dans la palette se pose au centre de la vue et devient la sélection.
#@ 9+
## Enregistrer écrit la salle et retire l'astérisque du titre ; une salle modifiée ne laisse pas ouvrir une autre salle
## sans qu'on abandonne ses modifications ; la liste montre les salles du dossier. La coquille des tests travaille dans
## un dossier à elle : les salles du projet ne sont jamais réécrites par un test.
#@ 18+
## Une planche peinte importée entre au catalogue, enregistré, et ses pièces se posent ; le sol se déverrouille pour
## l'éditer pièce par pièce.
#@ all

const SHELL: PackedScene = preload("res://2_sequence/editor/editor_shell.tscn")
#@ 9+
const ROOT: String = "user://test_coquille_salles"
const ROOMS: Array[String] = ["hangar.tres", "pont.tres", "soute.tres"]


func before_test() -> void:
	_vider()
	DirAccess.make_dir_recursive_absolute(ROOT)
	for file: String in ROOMS:
		DirAccess.copy_absolute("res://5_data/salles".path_join(file), ROOT.path_join(file))


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)
#@ all


func _shell() -> EditorShell:
	var shell: EditorShell = auto_free(SHELL.instantiate())
#@ 9+
	shell.rooms_dir = ROOT
	shell.start_room = ROOT.path_join("hangar.tres")
#@ all
	add_child(shell)
	return shell
#@ 1-5


func test_la_coquille_s_ouvre_sans_salle() -> void:
	assert_str(_shell().status()).is_equal(EditorShell.NOTHING_OPEN)
#@ 6+


func test_la_coquille_ouvre_la_salle_de_depart() -> void:
	var shell: EditorShell = _shell()
	assert_bool(shell.document().is_open()).is_true()
	assert_str(shell.status()).is_equal("Le hangar : %d choses" % shell.document().ids().size())


func test_une_salle_introuvable_est_signalee() -> void:
	var shell: EditorShell = _shell()
	assert_bool(shell.open_room("res://5_data/salles/absente.tres")).is_false()
	assert_str(shell.status()).is_equal("Ouverture impossible : Salle introuvable : res://5_data/salles/absente.tres")
	assert_bool(shell.document().is_open()).is_true()
#@ 8+


func test_un_asset_de_la_palette_se_pose_et_se_selectionne() -> void:
	var shell: EditorShell = _shell()
	var count: int = shell.document().ids().size()
	var created: int = shell.place_asset(&"caisse_cargo")
	assert_int(created).is_greater(0)
	assert_int(shell.document().ids().size()).is_equal(count + 1)
	assert_array(shell.selection().ids()).is_equal([created])
	assert_str(shell.status()).is_equal("caisse_cargo posé")
#@ 9+


func test_enregistrer_ecrit_la_salle_et_retire_l_asterisque() -> void:
	var shell: EditorShell = _shell()
	var thing_id: int = shell.document().ids()[0]
	shell.document().set_value(thing_id, &"height", 1.5)
	assert_str(shell.title()).is_equal("Éditeur de niveaux · Le hangar *")
	assert_bool(shell.save_room()).is_true()
	assert_str(shell.title()).is_equal("Éditeur de niveaux · Le hangar")
	assert_str(shell.status()).is_equal("Le hangar enregistré")
	var saved: RoomData = RoomStore.new().load_room(ROOT.path_join("hangar.tres"))
	assert_float(saved.thing_heights[saved.index_of(thing_id)]).is_equal(1.5)


func test_une_salle_modifiee_ne_laisse_pas_ouvrir_une_autre() -> void:
	var shell: EditorShell = _shell()
	shell.document().set_value(shell.document().ids()[0], &"height", 1.5)
	assert_bool(shell.open_room(ROOT.path_join("soute.tres"))).is_false()
	assert_str(shell.status()).is_equal(EditorShell.UNSAVED)
	assert_str(shell.title()).is_equal("Éditeur de niveaux · Le hangar *")
	assert_bool(shell.open_room(ROOT.path_join("soute.tres"), true)).is_true()
	assert_str(shell.title()).is_equal("Éditeur de niveaux · La soute")


func test_abandonner_rouvre_la_salle_du_disque() -> void:
	var shell: EditorShell = _shell()
	var thing_id: int = shell.document().ids()[0]
	shell.document().set_value(thing_id, &"height", 1.5)
	assert_bool(shell.discard_changes()).is_true()
	assert_float(shell.document().value(thing_id, &"height")).is_equal(0.0)
	assert_bool(shell.document().is_dirty()).is_false()


func test_la_liste_montre_les_salles_du_dossier() -> void:
	assert_array(Array(_shell().room_files())).is_equal(ROOMS)
#@ 10+


func test_le_mode_choisit_ce_que_fait_la_souris() -> void:
	var shell: EditorShell = _shell()
	assert_str(String(shell.current_mode())).is_equal("choses")
	assert_bool(shell.collision_input().active).is_false()
	shell.selection().replace([shell.document().ids()[0]])
	shell.set_mode(&"collisions")
	assert_str(String(shell.current_mode())).is_equal("collisions")
	assert_bool(shell.collision_input().active).is_true()
	assert_bool(shell.selection().is_empty()).is_true()
#@ 11+


func test_une_rencontre_incomplete_ne_s_enregistre_pas() -> void:
	var shell: EditorShell = _shell()
	shell.set_mode(&"apparitions")
	assert_bool(shell.encounter_panel().visible).is_true()
	shell.document().set_room_fields({&"encounter_pool": PackedStringArray(["licorne"])})
	assert_bool(shell.save_room()).is_false()
	assert_str(shell.status()).is_equal("Enregistrement impossible : rencontre : ennemi inconnu licorne")
#@ 12+


func test_un_effet_inconnu_ne_s_enregistre_pas() -> void:
	var shell: EditorShell = _shell()
	shell.set_mode(&"effets")
	assert_bool(shell.effect_input().active).is_true()
	var ids: PackedStringArray = shell.document().room_value(&"effect_ids")
	ids[0] = "arc_en_ciel"
	shell.document().set_room_fields({&"effect_ids": ids})
	assert_bool(shell.save_room()).is_false()
	assert_str(shell.status()).is_equal("Enregistrement impossible : effet 0 : effet inconnu arc_en_ciel")
#@ 13+


func test_le_mode_parametres_montre_les_definitions() -> void:
	var shell: EditorShell = _shell()
	shell.set_mode(&"parametres")
	assert_bool(shell.definition_panel().visible).is_true()
	shell.set_mode(&"choses")
	assert_bool(shell.definition_panel().visible).is_false()
#@ 16+


func test_une_salle_neuve_se_cree_et_s_ouvre() -> void:
	var shell: EditorShell = _shell()
	assert_bool(shell.create_room("Salle des machines")).is_true()
	assert_bool(FileAccess.file_exists(ROOT.path_join("salle_des_machines.tres"))).is_true()
	assert_array(Array(shell.room_files())).contains(["salle_des_machines.tres"])
	assert_str(shell.title()).is_equal("Éditeur de niveaux · Salle des machines")


func test_renommer_ne_change_que_le_nom_affiche() -> void:
	var shell: EditorShell = _shell()
	assert_bool(shell.rename_room("Le grand hangar")).is_true()
	assert_str(shell.title()).is_equal("Éditeur de niveaux · Le grand hangar *")
	assert_bool(shell.save_room()).is_true()
	var saved: RoomData = RoomStore.new().load_room(ROOT.path_join("hangar.tres"))
	assert_str(saved.display_name).is_equal("Le grand hangar")
	assert_str(String(saved.id)).is_equal("hangar")


func test_une_salle_modifiee_empeche_d_en_creer_une() -> void:
	var shell: EditorShell = _shell()
	shell.document().set_value(shell.document().ids()[0], &"height", 1.0)
	assert_bool(shell.create_room("Autre")).is_false()
	assert_str(shell.status()).is_equal(EditorShell.UNSAVED)
#@ all


func test_la_barre_d_etat_signale_son_texte() -> void:
	var shell: EditorShell = _shell()
	var seen: Array[String] = []
	shell.status_changed.connect(func(value: String) -> void: seen.append(value))
	shell.show_status("Salle enregistrée")
	assert_array(seen).is_equal(["Salle enregistrée"])
	assert_str(shell.status()).is_equal("Salle enregistrée")
#@ 18+


func test_une_planche_importee_entre_au_catalogue_enregistre() -> void:
	var shell: EditorShell = auto_free(SHELL.instantiate())
	shell.rooms_dir = ROOT
	shell.start_room = ROOT.path_join("hangar.tres")
	shell.painted_dir = ROOT.path_join("peint")
	# Une copie à part du catalogue, qui s'enregistre dans le dossier d'essai.
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres", "",
			ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef
	catalog.take_over_path(ROOT.path_join("catalogue.tres"))
	shell.catalog = catalog
	add_child(shell)
	assert_bool(shell.import_sheet("res://6_assets/planches_peintes/sol_01.png")).is_true()
	assert_str(shell.status()).starts_with("Planche sol_01.png : 11 pièces")
	var saved: AssetCatalogDef = ResourceLoader.load(ROOT.path_join("catalogue.tres"), "",
			ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef
	assert_object(saved.find(&"sol_01_11")).is_not_null()
	assert_int(shell.place_asset(&"sol_01_01")).is_greater(0)
	_vider_planches(ROOT.path_join("peint"))


func test_le_sol_se_deverrouille_pour_l_editer_piece_par_piece() -> void:
	var shell: EditorShell = _shell()
	assert_array(Array(shell.view().locked_layers)).is_equal(["sol"])
	shell.set_floor_locked(false)
	assert_array(Array(shell.view().locked_layers)).is_empty()
	shell.set_floor_locked(true)
	assert_array(Array(shell.view().locked_layers)).is_equal(["sol"])


func _vider_planches(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub: String in DirAccess.get_directories_at(folder):
		_vider_planches(folder.path_join(sub))
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
#@ all
