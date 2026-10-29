class_name HeroJumpState extends State
## L'état Jump du héros : il part vers le haut à la vitesse qui le monte de `jump_height`, au prix d'un peu
## d'endurance ; en l'air, il se dirige encore un peu (`air_control`) et peut tirer ; retombé au sol, il reprend sa
## course (Move).

## Le héros piloté.
@export var hero: Hero

var _left_ground: bool = false


## L'envol : l'endurance est dépensée, la vitesse verticale donnée.
func enter(_previous: StringName) -> void:
	hero.stamina.spend(hero.settings.jump_cost)
	hero.velocity.y = hero.jump_speed()
	_left_ground = false


## En l'air : il se dirige un peu, tombe, tire s'il le veut ; au sol, il court.
func physics_update(delta: float) -> void:
	var direction: Vector3 = Motion.camera_relative(hero.stick, hero.camera_yaw())
	var control: float = hero.settings.air_control
	hero.velocity = Motion.approach(hero.velocity, direction * hero.top_speed(), hero.settings.acceleration * control,
			hero.settings.deceleration * control, delta)
	hero.velocity.y -= hero.settings.gravity * delta
	hero.rotation.y = Motion.face(hero.rotation.y, hero.facing_direction(direction), hero.settings.turn_speed * control,
			delta)
	hero.move_and_slide()
	if hero.trigger:
		hero.gun.pull(hero.aim_point())
	if not hero.is_on_floor():
		_left_ground = true
	elif _left_ground:
		finish(&"Move")
