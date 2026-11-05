extends GdUnitTestSuite
## La coquille de l'éditeur s'ouvre : elle charge, dit qu'aucune salle n'est ouverte, et signale chaque texte qu'elle
## écrit dans sa barre d'état.

const SHELL: PackedScene = preload("res://2_sequence/editor/editor_shell.tscn")


func _shell() -> EditorShell:
	var shell: EditorShell = auto_free(SHELL.instantiate())
	add_child(shell)
	return shell


func test_la_coquille_s_ouvre_sans_salle() -> void:
	assert_str(_shell().status()).is_equal(EditorShell.NOTHING_OPEN)


func test_la_barre_d_etat_signale_son_texte() -> void:
	var shell: EditorShell = _shell()
	var seen: Array[String] = []
	shell.status_changed.connect(func(value: String) -> void: seen.append(value))
	shell.show_status("Salle enregistrée")
	assert_array(seen).is_equal(["Salle enregistrée"])
	assert_str(shell.status()).is_equal("Salle enregistrée")
