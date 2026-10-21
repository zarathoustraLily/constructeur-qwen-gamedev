class_name DamageNumbers extends CanvasLayer
## La couche des chiffres de dégâts, au-dessus de l'image du jeu : show_damage() y pose un chiffre au-dessus d'un
## point du monde. Elle ne connaît aucun personnage : c'est la scène qui lui envoie les dégâts.

## La scène d'un chiffre (4_ui/hud/damage_number).
@export var number_scene: PackedScene


func _ready() -> void:
	if number_scene == null:
		push_error("DamageNumbers : la scène d'un chiffre (number_scene) manque")


## Affiche `amount` au-dessus de `world_position` ; rend le chiffre posé.
func show_damage(world_position: Vector3, amount: float) -> DamageNumber:
	var number := number_scene.instantiate() as DamageNumber
	add_child(number)
	number.set_damage_text(amount)
	number.target_position = world_position
	return number
