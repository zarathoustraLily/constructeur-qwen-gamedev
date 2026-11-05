class_name FxDef
extends Resource
## Un effet du jeu (`5_data/effets/<id>.tres`) : de la fumée, des étincelles, de la vapeur. Ses réglages disent combien
## de particules il émet par seconde, combien de temps chacune vit, sa taille et sa couleur, et s'il s'ajoute à ce qui est
## dessous (additif : il éclaire). Le jeu en fait un émetteur de particules ; l'éditeur, un aperçu à l'endroit où une
## salle le place.

## Identifiant, en snake_case, jamais renommé : les salles le citent.
@export var id: StringName = &""
## Nom affiché.
@export var display_name: String = ""
## Les particules émises par seconde.
@export var rate: float = 1.0
## La vie d'une particule, en secondes.
@export var lifetime_s: float = 1.0
## La taille d'une particule, en mètres.
@export var size_m: float = 0.1
## La couleur des particules.
@export var color: Color = Color.WHITE
## Vrai si l'effet s'ajoute à ce qui est dessous (il éclaire) ; faux s'il le recouvre.
@export var additive: bool = false


## Les erreurs de la définition, une phrase par erreur ; vide si elle est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var label: String = "effet %s" % id
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : identifiant en snake_case requis" % label)
	if rate <= 0.0 or lifetime_s <= 0.0 or size_m <= 0.0:
		errors.append("%s : débit, durée de vie et taille positifs requis" % label)
	return errors


## Les erreurs des effets placés dans `room` face aux effets `effects` du jeu : un effet inconnu.
static func placement_errors(room: RoomData, effects: Array[FxDef]) -> Array[String]:
	var known: Array[StringName] = []
	for effect: FxDef in effects:
		known.append(effect.id)
	var errors: Array[String] = []
	for index: int in room.effect_ids.size():
		if not known.has(StringName(room.effect_ids[index])):
			errors.append("effet %d : effet inconnu %s" % [index, room.effect_ids[index]])
	return errors
