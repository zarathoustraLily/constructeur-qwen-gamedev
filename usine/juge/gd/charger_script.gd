extends SceneTree
## Juge : compile un script avec les autoloads du projet enregistrés.
## Sert de second avis quand --check-only échoue sur un autoload, directement ou par un
## script dont il dépend (--check-only s'arrête avant de les enregistrer).
## Avant le script visé, les classes globales (class_name) sont chargées de la base vers
## les dérivées, comme le jeu les rencontre : charger seule une classe dérivée dont la base
## précharge une scène qui la référence échoue sur un cycle que le jeu ne voit jamais.
## Usage : godot --headless --path <projet> -s <ce script> -- res://chemin/script.gd

const MARQUEUR := "@@JUGE_SCRIPT@@"


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
	var args := OS.get_cmdline_user_args()
	var ok := false
	if not args.is_empty():
		_charger_classes_globales()
		var script := ResourceLoader.load(args[0]) as Script
		ok = script != null and script.can_instantiate()
	print(MARQUEUR + JSON.stringify({"ok": ok}))
	quit(0 if ok else 1)
