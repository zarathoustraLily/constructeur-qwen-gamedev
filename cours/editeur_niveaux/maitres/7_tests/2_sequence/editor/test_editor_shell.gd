extends GdUnitTestSuite
#@ 1-5
## La coquille de l'éditeur s'ouvre : elle charge, dit qu'aucune salle n'est ouverte, et signale chaque texte qu'elle
## écrit dans sa barre d'état.
#@ 6+
## La coquille de l'éditeur s'ouvre sur la salle de départ et dit ce qu'elle contient ; une salle introuvable est
## signalée dans la barre d'état sans rien ouvrir ; chaque texte écrit dans la barre d'état est signalé.
#@ 8+
## Un asset choisi dans la palette se pose au centre de la vue et devient la sélection.
#@ all

const SHELL: PackedScene = preload("res://2_sequence/editor/editor_shell.tscn")


func _shell() -> EditorShell:
	var shell: EditorShell = auto_free(SHELL.instantiate())
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
#@ all


func test_la_barre_d_etat_signale_son_texte() -> void:
	var shell: EditorShell = _shell()
	var seen: Array[String] = []
	shell.status_changed.connect(func(value: String) -> void: seen.append(value))
	shell.show_status("Salle enregistrée")
	assert_array(seen).is_equal(["Salle enregistrée"])
	assert_str(shell.status()).is_equal("Salle enregistrée")
