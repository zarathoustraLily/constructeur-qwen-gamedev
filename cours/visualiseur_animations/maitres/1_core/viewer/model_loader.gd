class_name ModelLoader extends RefCounted
## Charge un modèle glTF (.glb, .gltf) à l'exécution, sans l'import de Godot : le visualiseur lit les fichiers tels que
## Blender les écrit, dans n'importe quel dossier, sans les copier dans le projet.
## Deux réglages comptent :
## - les animations gardent leurs pistes constantes (remove_immutable_tracks à false). Sans elles, une pose tenue (le
##   coffre fermé : une seule valeur sur toute la durée) n'a plus de piste, et ne remet rien en place après une autre
##   animation : le coffre resterait ouvert ;
## - glTF ne dit pas si une animation boucle ; c'est le fichier d'accompagnement qui le dit (AssetSidecar).

## Images par seconde auxquelles Godot échantillonne les animations du fichier.
const BAKE_FPS: float = 30.0


## Le modèle du fichier `path`, ou son erreur.
static func load_model(path: String) -> LoadedModel:
	var model: LoadedModel = LoadedModel.new()
	if not FileAccess.file_exists(path):
		model.error = "fichier introuvable : " + path
		return model
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	var err: Error = document.append_from_file(path, state)
	if err != OK:
		model.error = "glTF illisible (%s) : %s" % [error_string(err), path]
		return model
	var scene: Node = document.generate_scene(state, BAKE_FPS, false, false)
	if not scene is Node3D:
		if scene != null:
			scene.free()
		model.error = "le fichier ne contient pas de scène 3D : " + path
		return model
	model.root = scene as Node3D
	var players: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		model.player = players[0] as AnimationPlayer
	var skeletons: Array[Node] = scene.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		model.skeleton = skeletons[0] as Skeleton3D
	return model
