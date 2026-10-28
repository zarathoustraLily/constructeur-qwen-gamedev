class_name Player extends CharacterBody3D
## Le joueur : un corps qui se déplace sur le sol, saute et retombe. Il ne lit pas la manette : son entrée
## (player_input.gd) lui donne une direction voulue et les appuis sur saut ; lui calcule le mouvement (Motion) et
## laisse move_and_slide gérer les collisions.

## Il vient de quitter le sol par un saut.
signal jumped

## Vitesses, gravité, saut.
@export var settings: MoveSettings

## La direction voulue, de longueur 0 à 1 (x : droite, y : arrière), posée par l'entrée.
var wish: Vector2 = Vector2.ZERO

var _time_since_floor: float = 0.0
var _time_since_jump_press: float = -1.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.ENTITIES
	collision_layer = Layers.bit(Layers.PLAYER)
	collision_mask = Layers.mask([Layers.WORLD, Layers.ENEMY])


func _physics_process(delta: float) -> void:
	step(delta)


## L'entrée signale un appui sur saut ; il sera tenté pendant `jump_buffer_time`.
func press_jump() -> void:
	_time_since_jump_press = 0.0


## Avance le joueur de `delta` secondes : gravité, saut permis et demandé, vitesse horizontale, puis move_and_slide.
func step(delta: float) -> void:
	if is_on_floor():
		_time_since_floor = 0.0
	else:
		_time_since_floor += delta
		velocity.y = Motion.fall(velocity.y, settings, delta)
	if _time_since_jump_press >= 0.0:
		_time_since_jump_press += delta
	if Motion.jump_buffered(_time_since_jump_press, settings) and Motion.can_jump(is_on_floor(), _time_since_floor, settings):
		velocity.y = Motion.jump_speed(settings)
		_time_since_jump_press = -1.0
		_time_since_floor = settings.coyote_time + 1.0
		jumped.emit()
	velocity = Motion.horizontal(velocity, wish, is_on_floor(), settings, delta)
	move_and_slide()
