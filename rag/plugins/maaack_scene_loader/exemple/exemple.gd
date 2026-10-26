extends Node
## Exemple minimal de Maaack's Scene Loader (v1.7.0, GDScript) : charger le niveau suivant en arrière-plan, sans
## figer le jeu, et savoir quand il est prêt (ici, sans écran de chargement ni changement de scène).

const NIVEAU: String = "res://exemple/niveau_2.tscn"

var _pret: bool = false
var _image: int = 0


func _ready() -> void:
	# Sans écran de chargement déclaré, load_scene écrit « loading screen is not set », même en arrière-plan.
	SceneLoader.set_loading_screen_path("res://addons/maaacks_scene_loader/base/nodes/loading_screen/loading_screen.tscn")
	SceneLoader.scene_loaded.connect(_on_scene_loaded)
	SceneLoader.load_scene(NIVEAU, true)  # true : en arrière-plan, la scène courante reste affichée


func _process(_delta: float) -> void:
	_image += 1
	if not _pret and _image < 300:
		return
	# Récupérer le résultat par load_threaded_get : SceneLoader.get_resource() relit la scène par
	# ResourceLoader.load quand elle est en cache, et la demande de chargement jamais récupérée fuit à la sortie.
	var scene := ResourceLoader.load_threaded_get(NIVEAU) as PackedScene if _pret else null
	var racine := scene.instantiate() if scene else null
	if _pret and racine != null and racine.name == &"Niveau2":
		print("EXEMPLE VERIFIE : niveau chargé en arrière-plan en %d images, racine %s" % [_image, racine.name])
	else:
		push_error("prêt : %s, scène : %s" % [_pret, scene])
	if racine:
		racine.free()
	SceneLoader.scene_loaded.disconnect(_on_scene_loaded)
	get_tree().quit()


func _on_scene_loaded() -> void:
	_pret = true
