class_name Bomb extends BuoyantBody3D
## Bombe lancée par le joueur : elle flotte (BuoyantBody3D) et explose au bout de `explosion_delay` secondes,
## à cadence de physique (le décompte s'arrête en pause). L'explosion (`explosion_scene`) est posée à sa place,
## à côté d'elle dans la scène ; dans l'eau, elle soulève une vague par la surface que lit son capteur. Les
## chiffres sont donnés par la scène de la bombe.

## Émis juste avant que la bombe disparaisse dans son explosion.
signal exploded

## Délai (s) entre l'apparition de la bombe et son explosion.
@export var explosion_delay: float = 0.0
## Scène de l'explosion, posée à l'endroit de la bombe.
@export var explosion_scene: PackedScene
## Hauteur (m) de la vague soulevée dans l'eau.
@export var wave_height: float = 0.0
## Rayon de la vague, en pixels de la simulation de vagues.
@export var wave_radius_px: float = 0.0

var _time_left: float = 0.0

@onready var _sensor: WaterBuoyancySensor = $WaterBuoyancySensor


func _ready() -> void:
	super._ready()
	_time_left = explosion_delay


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_time_left -= delta
	if _time_left <= 0.0:
		explode()


## Fait exploser la bombe tout de suite.
func explode() -> void:
	if is_queued_for_deletion():
		return
	if explosion_scene != null:
		var effect := explosion_scene.instantiate() as Node3D
		add_sibling(effect)
		effect.global_position = global_position
	if _sensor.is_in_water() and _sensor.ocean_node != null:
		_sensor.ocean_node.add_wave(global_position, wave_height, wave_radius_px)
	exploded.emit()
	queue_free()
