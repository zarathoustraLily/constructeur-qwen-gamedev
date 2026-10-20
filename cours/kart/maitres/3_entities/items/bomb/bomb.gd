extends BuoyantBody3D
## Bombe lancée par le joueur : elle flotte (BuoyantBody3D) et explose au bout de `explosion_delay`
## secondes ; dans l'eau, l'explosion soulève une vague.

## Délai (s) entre l'apparition de la bombe et son explosion.
@export var explosion_delay := 5.0
## Scène de l'explosion, placée à l'endroit de la bombe.
@export var explosion_effect : PackedScene
@onready var bouyancy_sensor : WaterBuoyancySensor = $WaterBuoyancySensor


func _ready() -> void:		
	
	super._ready()
	await get_tree().create_timer(explosion_delay).timeout
	_explode()

func _explode() -> void:
	var effect: Node3D = explosion_effect.instantiate() as Node3D
	get_tree().root.add_child(effect)
	effect.global_position = global_position
	queue_free()

	if bouyancy_sensor.is_in_water() and bouyancy_sensor.ocean_node:
		bouyancy_sensor.ocean_node.add_wave(global_position, 0.5, 24)
