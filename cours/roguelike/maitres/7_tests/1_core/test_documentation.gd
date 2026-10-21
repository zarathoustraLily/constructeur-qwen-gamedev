extends GdUnitTestSuite
## Règle de documentation du projet : chaque script du jeu commence par sa description (des lignes ##
## juste après extends et class_name, suivies d'une ligne vide), et chaque membre public (signal,
## constante, enum, variable ou fonction dont le nom ne commence pas par « _ ») a son commentaire ##
## juste au-dessus de lui, ou au-dessus de ses annotations. Les nœuds @onready en sont dispensés.
## Ces commentaires forment l'aide intégrée de Godot (F1 dans l'éditeur).

const IGNORES: Array[String] = ["addons", "7_tests", "_sources"]
const TEMOIN := "user://documentation_temoin.gd"

var _entete := RegEx.create_from_string("^(@tool|@icon\\(.*\\)|class_name\\s.*|extends\\s.*)\\s*$")
var _membre := RegEx.create_from_string("^((?:@\\w+(?:\\([^)]*\\))?\\s+)*)(?:static\\s+)?(func|var|const|signal|enum)\\s+(\\w+)")
var _annotation := RegEx.create_from_string("^@(?!export_group|export_subgroup|export_category|tool\\b|icon\\b)\\w+(\\(.*\\))?\\s*$")


func after_test() -> void:
	if FileAccess.file_exists(TEMOIN):
		DirAccess.remove_absolute(TEMOIN)


func _scripts(dossier: String, sortie: Array[String]) -> void:
	for nom in DirAccess.get_directories_at(dossier):
		if not nom.begins_with(".") and nom not in IGNORES:
			_scripts(dossier.path_join(nom), sortie)
	for nom in DirAccess.get_files_at(dossier):
		if nom.ends_with(".gd"):
			sortie.append(dossier.path_join(nom))


## Ce qui manque à la documentation du script `chemin`, une entrée par manque.
func _manques(chemin: String) -> Array[String]:
	var lignes := FileAccess.get_file_as_string(chemin).replace("\r\n", "\n").split("\n")
	var manques: Array[String] = []
	var dernier := -1
	for k in mini(12, lignes.size()):
		if _entete.search(lignes[k]):
			dernier = k
	var i := dernier + 1
	while i < lignes.size() and lignes[i].strip_edges().is_empty():
		i += 1
	if dernier < 0 or i >= lignes.size() or not lignes[i].begins_with("##"):
		manques.append("description de la classe")
	else:
		while i < lignes.size() and lignes[i].begins_with("##"):
			i += 1
		if i < lignes.size() and not lignes[i].strip_edges().is_empty():
			manques.append("description de la classe collée au premier membre")
	for n in lignes.size():
		var m := _membre.search(lignes[n])
		if m == null or m.get_string(3).begins_with("_") or "@onready" in m.get_string(1):
			continue
		var k := n - 1
		while k >= 0 and _annotation.search(lignes[k]):
			k -= 1
		if k < 0 or not lignes[k].begins_with("##"):
			manques.append("ligne %d : %s %s" % [n + 1, m.get_string(2), m.get_string(3)])
	return manques


func _ecrire_temoin(texte: String) -> void:
	var fichier := FileAccess.open(TEMOIN, FileAccess.WRITE)
	fichier.store_string(texte)
	fichier.close()


func test_chaque_script_du_jeu_est_documente() -> void:
	var scripts: Array[String] = []
	_scripts("res://", scripts)
	assert_array(scripts).is_not_empty()
	var manques: Array[String] = []
	for chemin in scripts:
		for manque in _manques(chemin):
			manques.append(chemin + " : " + manque)
	assert_array(manques).is_empty()


func test_un_script_bien_documente_passe() -> void:
	_ecrire_temoin("extends Node\n## Description.\n\n## Vitesse.\n@export var vitesse := 1.0\n## Bouton.\n@export_tool_button(\"Jouer\")\nvar bouton := func(): pass\n@onready var noeud := $Noeud\nvar _prive := 0\n\n## Saute.\nfunc sauter() -> void:\n\tpass\n")
	assert_array(_manques(TEMOIN)).is_empty()


func test_un_membre_public_sans_commentaire_est_signale() -> void:
	_ecrire_temoin("extends Node\n## Description.\n\n## Vitesse.\nvar vitesse := 1.0\n\nfunc sauter() -> void:\n\tpass\n")
	assert_array(_manques(TEMOIN)).is_equal(["ligne 7 : func sauter"])


func test_un_script_sans_description_est_signale() -> void:
	_ecrire_temoin("extends Node\n\n## Vitesse.\nvar vitesse := 1.0\n")
	assert_array(_manques(TEMOIN)).is_equal(["description de la classe collée au premier membre"])
