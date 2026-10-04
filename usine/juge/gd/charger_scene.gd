extends SceneTree
## Juge : charge une scène, l'instancie dans l'arbre, puis décrit ce qui manque.
## Usage : godot --headless --path <projet> -s <ce script> -- res://chemin/scene.tscn
## Le rapport est une ligne JSON préfixée par @@JUGE_SCENE@@ sur la sortie standard.

const MARQUEUR := "@@JUGE_SCENE@@"

var _rapport: Dictionary = {}
var _instance: Node = null
var _fini: bool = false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var rapport := {
		"scene": "",
		"chargee": false,
		"instanciee": false,
		"noeuds": [],
		"scripts_manquants": [],
		"ressources_manquantes": [],
	}
	if args.is_empty():
		_terminer(rapport, 2)
		return
	var chemin: String = args[0]
	rapport["scene"] = chemin
	if not ResourceLoader.exists(chemin):
		rapport["ressources_manquantes"].append(chemin)
		_terminer(rapport, 1)
		return
	for dependance in ResourceLoader.get_dependencies(chemin):
		var dep_chemin := _chemin_dependance(dependance)
		if dep_chemin.is_empty():
			continue
		if not ResourceLoader.exists(dep_chemin) and not FileAccess.file_exists(dep_chemin):
			if dep_chemin.get_extension() in ["gd", "cs"]:
				rapport["scripts_manquants"].append(dep_chemin)
			else:
				rapport["ressources_manquantes"].append(dep_chemin)
	var paquet := ResourceLoader.load(chemin) as PackedScene
	if paquet == null:
		_terminer(rapport, 1)
		return
	rapport["chargee"] = true
	var instance := paquet.instantiate()
	if instance == null:
		_terminer(rapport, 1)
		return
	rapport["instanciee"] = true
	# _ready et @onready ne s'exécutent qu'à la première image : on décrit l'arbre dans _process.
	_rapport = rapport
	_instance = instance
	root.add_child(instance)


func _process(_delta: float) -> bool:
	if _instance != null and not _fini:
		_decrire(_instance, _instance, _rapport["noeuds"])
		_terminer(_rapport, 0)
	return _fini


## « uid://…::Type::res://x » ou « res://x::Type » → « res://x ».
func _chemin_dependance(dependance: String) -> String:
	for morceau in dependance.split("::"):
		if morceau.begins_with("res://"):
			return morceau
	if dependance.begins_with("uid://"):
		var id := ResourceUID.text_to_id(dependance.split("::")[0])
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return ""


func _decrire(racine: Node, noeud: Node, sortie: Array) -> void:
	var script: Script = noeud.get_script()
	sortie.append({
		"chemin": str(racine.get_path_to(noeud)),
		"type": noeud.get_class(),
		"script": script.resource_path if script else "",
	})
	for enfant in noeud.get_children():
		_decrire(racine, enfant, sortie)


func _terminer(rapport: Dictionary, code: int) -> void:
	_fini = true
	print(MARQUEUR + JSON.stringify(rapport))
	quit(code)
