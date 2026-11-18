class_name ModelView extends Subject
## Un modèle 3D chargé (LoadedModel), posé sous ce nœud ; ses animations se jouent par son AnimationPlayer. Les
## boucles viennent du fichier d'accompagnement : glTF ne les dit pas. En lecture manuelle (un test), le lecteur ne
## s'avance plus seul : seul advance le fait avancer, d'autant de secondes qu'on veut.

## Vrai pour avancer la lecture à la main (advance), faux pour qu'elle suive le jeu.
@export var manual: bool = false

## Le modèle montré ; null avant show_model.
var model: LoadedModel


## Montre `loaded` (sa scène passe sous ce nœud) avec les boucles de `sidecar` ; faux s'il n'a pas de scène.
func show_model(loaded: LoadedModel, sidecar: AssetSidecar) -> bool:
	clear()
	if loaded.root == null:
		return false
	model = loaded
	add_child(loaded.root)
	if loaded.player != null:
		loaded.player.callback_mode_process = (AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL if manual
				else AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE)
		for clip: String in loaded.clips():
			loaded.player.get_animation(clip).loop_mode = (Animation.LOOP_LINEAR if sidecar.loops_clip(clip)
					else Animation.LOOP_NONE)
	return true


## Les noms des animations du modèle, triés.
func clips() -> Array[String]:
	if model == null:
		var none: Array[String] = []
		return none
	return model.clips()


## Le temps écoulé dans l'animation en cours ; sa durée quand elle est finie.
func position_s() -> float:
	if model == null or model.player == null or _clip.is_empty():
		return 0.0
	if model.player.current_animation.is_empty():
		return model.player.get_animation(_clip).length
	return model.player.current_animation_position


## Avance la lecture de `seconds` secondes (en lecture manuelle).
func advance(seconds: float) -> void:
	if model != null and model.player != null:
		model.player.advance(seconds)


## Retire le modèle et le libère.
func clear() -> void:
	super.clear()
	if model == null:
		return
	if model.root != null and model.root.get_parent() == self:
		remove_child(model.root)
	model.free_scene()
	model = null


## Le nœud `node_name` du modèle (le couvercle d'un coffre), ou null.
func part(node_name: String) -> Node3D:
	if model == null:
		return null
	return model.root.find_child(node_name, true, false) as Node3D


func _start(clip_name: String, at: float) -> void:
	if model == null or model.player == null:
		return
	model.player.play(clip_name)
	model.player.seek(at, true)
