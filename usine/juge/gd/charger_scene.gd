extends SceneTree
## Juge : charge une scène, l'instancie dans l'arbre, puis décrit ce qui manque.
## Usage : godot --headless --path <projet> -s <ce script> -- res://chemin/scene.tscn
## Le rapport est une ligne JSON préfixée par @@JUGE_SCENE@@ sur la sortie standard.

const MARQUEUR := "@@JUGE_SCENE@@"

var _rapport: Dictionary = {}
var _instance: Node = null
var _fini: bool = false


func _profondeur(nom: StringName, bases: Dictionary) -> int:
	var n := 0
	while bases.has(nom):
		nom = bases[nom]
		n += 1
	return n


## Classes globales que la scène peut atteindre, chargées de la base vers les dérivées avant
## elle (voir charger_script.gd). Atteignables : les dépendances de la scène, de proche en proche,
## plus les classes nommées dans le texte de ces scripts, avec leurs classes de base. Une classe
## cassée que la scène n'atteint pas n'est pas chargée : elle ne fait pas échouer la scène.
func _charger_classes_globales(scene: String) -> void:
	var bases := {}
	var chemins := {}
	for c in ProjectSettings.get_global_class_list():
		bases[c["class"]] = c["base"]
		chemins[c["class"]] = c["path"]
	var motifs := {}
	for nom in chemins:
		var motif := RegEx.new()
		motif.compile("\\b%s\\b" % nom)
		motifs[nom] = motif
	var atteints := {scene: true}
	var a_voir: Array[String] = [scene]
	var classes := {}
	while not a_voir.is_empty():
		var chemin: String = a_voir.pop_back()
		var suivants: Array[String] = []
		if ResourceLoader.exists(chemin):
			for dependance in ResourceLoader.get_dependencies(chemin):
				suivants.append(_chemin_dependance(dependance))
		if chemin.get_extension() == "gd" and FileAccess.file_exists(chemin):
			var texte := FileAccess.get_file_as_string(chemin)
			for nom in chemins:
				if motifs[nom].search(texte) != null:
					var n: StringName = nom
					while chemins.has(n):
						classes[n] = true
						suivants.append(chemins[n])
						n = bases.get(n, &"")
		for suivant in suivants:
			if not suivant.is_empty() and not atteints.has(suivant):
				atteints[suivant] = true
				a_voir.append(suivant)
	for nom in chemins:
		if atteints.has(chemins[nom]):
			classes[nom] = true
	var noms := classes.keys()
	noms.sort_custom(func(a, b): return [_profondeur(a, bases), str(a)] < [_profondeur(b, bases), str(b)])
	for nom in noms:
		ResourceLoader.load(chemins[nom])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_charger_classes_globales(args[0])
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


## « uid://…::Type::res://x » ou « res://x::Type » → « res://x ». Comme le chargeur de Godot,
## l'UID passe avant le chemin texte (un script déplacé avec son .uid garde son UID).
func _chemin_dependance(dependance: String) -> String:
	var morceaux := dependance.split("::")
	if morceaux[0].begins_with("uid://"):
		var id := ResourceUID.text_to_id(morceaux[0])
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	for morceau in morceaux:
		if morceau.begins_with("res://"):
			return morceau
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
