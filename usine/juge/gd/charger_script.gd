extends SceneTree
## Juge : compile un script avec les autoloads du projet enregistrés.
## Sert de second avis quand --check-only échoue seulement sur un autoload
## (--check-only s'arrête avant de les enregistrer).
## Usage : godot --headless --path <projet> -s <ce script> -- res://chemin/script.gd

const MARQUEUR := "@@JUGE_SCRIPT@@"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var ok := false
	if not args.is_empty():
		var script := ResourceLoader.load(args[0], "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		ok = script != null and script.can_instantiate()
	print(MARQUEUR + JSON.stringify({"ok": ok}))
	quit(0 if ok else 1)
