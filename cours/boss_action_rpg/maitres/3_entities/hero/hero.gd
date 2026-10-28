class_name Hero extends CharacterBody3D
## Le héros : un corps qui court là où pousse le stick, par rapport à la caméra, et qui pivote vers sa marche. Il ne
## lit ni la manette ni le clavier : son entrée (hero_input.gd) lui donne la direction voulue ; lui calcule le
## mouvement (Motion) et laisse move_and_slide gérer les collisions.

## Vitesses, accélérations, virage, gravité.
@export var settings: HeroSettings
## Ce qui donne le lacet de la caméra (la caméra, ou son pivot).
@export var camera: Node3D

## Le stick voulu (x : droite, y : arrière, longueur 0 à 1), posé par l'entrée.
var stick: Vector2 = Vector2.ZERO
## Vrai pendant la visée : la course ralentit.
var aiming: bool = false


func _ready() -> void:
	process_physics_priority = ProcessOrder.ACTORS
	collision_layer = Layers.bit(Layers.HERO)
	collision_mask = Layers.mask([Layers.WORLD, Layers.BOSS])


func _physics_process(delta: float) -> void:
	step(delta)


## La vitesse de course du moment : plus lente en visant.
func top_speed() -> float:
	return settings.aim_speed if aiming else settings.run_speed


## Avance de `delta` secondes : gravité, vitesse vers la direction voulue, corps tourné vers sa marche, collisions.
func step(delta: float) -> void:
	var yaw: float = camera.global_rotation.y if camera != null else 0.0
	var direction: Vector3 = Motion.camera_relative(stick, yaw)
	if not is_on_floor():
		velocity.y -= settings.gravity * delta
	velocity = Motion.approach(velocity, direction * top_speed(), settings.acceleration, settings.deceleration, delta)
	rotation.y = Motion.face(rotation.y, direction, settings.turn_speed, delta)
	move_and_slide()
