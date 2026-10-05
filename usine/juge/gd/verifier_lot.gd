extends SceneTree
## Juge : vérifie en un seul lancement tous les scripts ou toutes les scènes d'un projet.
## Usage : godot --headless --path <projet> -s <ce script> -- scripts|scenes res://a res://b …
##
## Les classes globales (class_name) sont d'abord chargées de la base vers les dérivées, comme
## le jeu les rencontre (voir charger_script.gd). Puis, pour chaque élément :
##   @@JUGE_LOT_DEBUT@@<chemin>            (les erreurs du moteur qui suivent lui appartiennent)
##   @@JUGE_LOT@@{"chemin": …, "ok": …}
## Script : compilé et instanciable. Scène : chargée, instanciée, ajoutée à l'arbre, une image
## jouée (_ready et @onready), puis libérée.
## Le lot n'est qu'un raccourci : à la moindre erreur, le juge refait la vérification élément par
## élément (check_script, load_scene), qui reste l'autorité.

const DEBUT := "@@JUGE_LOT_DEBUT@@"
const MARQUEUR := "@@JUGE_LOT@@"


func _profondeur(nom: StringName, bases: Dictionary) -> int:
	var n := 0
	while bases.has(nom):
		nom = bases[nom]
		n += 1
	return n


func _charger_classes_globales() -> void:
	var bases := {}
	var chemins := {}
	for c in ProjectSettings.get_global_class_list():
		bases[c["class"]] = c["base"]
		chemins[c["class"]] = c["path"]
	var noms := chemins.keys()
	noms.sort_custom(func(a, b): return [_profondeur(a, bases), str(a)] < [_profondeur(b, bases), str(b)])
	for nom in noms:
		ResourceLoader.load(chemins[nom])


func _initialize() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		quit(2)
		return
	var mode: String = args[0]
	print(DEBUT + "<classes>")
	_charger_classes_globales()
	for chemin in args.slice(1):
		print(DEBUT + chemin)
		var ok := false
		if mode == "scripts":
			var script := ResourceLoader.load(chemin) as Script
			ok = script != null and script.can_instantiate()
		else:
			ok = await _scene(chemin)
		print(MARQUEUR + JSON.stringify({"chemin": chemin, "ok": ok}))
	print(DEBUT + "<fin>")
	quit(0)


func _scene(chemin: String) -> bool:
	if not ResourceLoader.exists(chemin):
		return false
	var paquet := ResourceLoader.load(chemin) as PackedScene
	if paquet == null:
		return false
	var instance := paquet.instantiate()
	if instance == null:
		return false
	root.add_child(instance)
	await process_frame
	instance.queue_free()
	await process_frame
	return true
