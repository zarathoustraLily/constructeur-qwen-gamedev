class_name AnimationDef
extends Resource
## Les animations d'un ennemi (`5_data/animations/<id>.tres`, le même identifiant que l'ennemi) : son modèle, et pour
## chaque état du jeu (repos, déplacement, attaque, coup reçu, mort, apparition) le clip à jouer et sa vitesse, plus la
## durée du fondu entre deux clips. La validation vérifie chaque clip sur le modèle lui-même : un clip absent du modèle
## donnerait en jeu un ennemi figé.

## Les états du jeu qui ont chacun leur clip.
const STATES: Array[StringName] = [&"idle", &"move", &"attack", &"hit", &"death", &"spawn"]

## Identifiant, celui de l'ennemi animé.
@export var id: StringName = &""
## Nom affiché.
@export var display_name: String = ""
## Le modèle animé : une scène qui contient un `AnimationPlayer`.
@export var model: PackedScene
## Le clip de chaque état.
@export var clips: Dictionary[StringName, StringName] = {}
## La vitesse de lecture de chaque état (1 : la vitesse du clip).
@export var speeds: Dictionary[StringName, float] = {}
## La durée du fondu entre deux clips, en secondes.
@export var blend_s: float = 0.15


## Les clips du modèle (ceux de son premier `AnimationPlayer`), ou une liste vide.
func model_clips() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if model == null:
		return result
	var instance: Node = model.instantiate()
	var players: Array[Node] = instance.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		result = (players[0] as AnimationPlayer).get_animation_list()
	instance.free()
	return result


## Les erreurs de la définition, une phrase par erreur ; vide si elle est valide. Les clips sont vérifiés sur le modèle.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var label: String = "animation %s" % id
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : identifiant en snake_case requis" % label)
	if model == null:
		errors.append("%s : modèle requis" % label)
	if blend_s < 0.0:
		errors.append("%s : fondu positif ou nul requis" % label)
	var available: PackedStringArray = model_clips()
	for state: StringName in clips:
		if not STATES.has(state):
			errors.append("%s : état inconnu %s" % [label, state])
	for state: StringName in STATES:
		if not clips.has(state):
			errors.append("%s : état %s sans clip" % [label, state])
		elif model != null and not available.has(String(clips[state])):
			errors.append("%s : clip %s absent du modèle (%s)" % [label, clips[state], state])
		if speeds.get(state, 1.0) <= 0.0:
			errors.append("%s : vitesse de %s positive requise" % [label, state])
	return errors
