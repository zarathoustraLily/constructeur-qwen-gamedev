extends SceneTree
## RAG : compile chaque script donné et dit s'il est instanciable (Godot 4.7, sans LLM).
## Usage : godot --headless --path <projet> -s <ce script> -- res://a.gd res://b.gd …
## Une ligne par script : @@RAG_SCRIPT@@{"chemin": "res://a.gd", "ok": true}

const MARQUEUR := "@@RAG_SCRIPT@@"


func _initialize() -> void:
	for chemin in OS.get_cmdline_user_args():
		var script := ResourceLoader.load(chemin, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var ok := script != null and script.can_instantiate()
		print(MARQUEUR + JSON.stringify({"chemin": chemin, "ok": ok}))
	quit(0)
