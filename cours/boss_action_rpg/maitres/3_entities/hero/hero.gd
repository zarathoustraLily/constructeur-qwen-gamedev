class_name Hero extends CharacterBody3D
## Le héros : un corps qui court là où pousse le stick, par rapport à la caméra, et qui pivote vers sa marche. Il ne
## lit ni la manette ni le clavier : son entrée (hero_input.gd) lui donne la direction voulue ; lui calcule le
## mouvement (Motion) et laisse move_and_slide gérer les collisions.
#@ 4+
## Ce qu'il fait (courir, rouler) est choisi par sa machine à états (StateMachine, états Move et Roll) : chaque état
## appelle les mouvements ci-dessous ; l'endurance et la mémoire d'appui sont ses composants.
#@ all

## Vitesses, accélérations, virage, gravité.
@export var settings: HeroSettings
## Ce qui donne le lacet de la caméra (la caméra, ou son pivot).
@export var camera: Node3D

## Le stick voulu (x : droite, y : arrière, longueur 0 à 1), posé par l'entrée.
var stick: Vector2 = Vector2.ZERO
## Vrai pendant la visée : la course ralentit.
var aiming: bool = false
#@ 4+
## Vrai tant que le bouton de roulade est tenu : le héros sprinte (état Move).
var dodge_held: bool = false
## Vrai pendant le sprint : la course va plus vite.
var sprinting: bool = false
## Vrai au début de la roulade : aucun coup ne porte.
var invulnerable: bool = false

## L'endurance : la roulade et le sprint la dépensent.
@onready var stamina: StaminaComponent = $Stamina
## La mémoire d'appui de la roulade.
@onready var roll_buffer: InputBuffer = $RollBuffer
## Ce qu'il fait : Move ou Roll.
@onready var machine: StateMachine = $StateMachine
#@ all


func _ready() -> void:
#@ 2-3
	process_physics_priority = ProcessOrder.ACTORS
#@ all
	collision_layer = Layers.bit(Layers.HERO)
	collision_mask = Layers.mask([Layers.WORLD, Layers.BOSS])
#@ 4+
	roll_buffer.window = settings.roll_buffer_time
#@ 2-3


func _physics_process(delta: float) -> void:
	step(delta)
#@ all


## La vitesse de course du moment : plus lente en visant.
#@ 4+
## Plus rapide en sprint.
#@ all
func top_speed() -> float:
#@ 2-3
	return settings.aim_speed if aiming else settings.run_speed
#@ 4+
	if aiming:
		return settings.aim_speed
	return settings.sprint_speed if sprinting else settings.run_speed
#@ all


## Le lacet de la caméra (0 sans caméra) : le déplacement se fait par rapport à lui.
func camera_yaw() -> float:
	return camera.global_rotation.y if camera != null else 0.0


## Avance de `delta` secondes : gravité, vitesse vers la direction voulue, corps tourné vers sa marche, collisions.
func step(delta: float) -> void:
	var direction: Vector3 = Motion.camera_relative(stick, camera_yaw())
	if not is_on_floor():
		velocity.y -= settings.gravity * delta
	velocity = Motion.approach(velocity, direction * top_speed(), settings.acceleration, settings.deceleration, delta)
	rotation.y = Motion.face(rotation.y, direction, settings.turn_speed, delta)
	move_and_slide()
#@ 4+


## La direction de la roulade (longueur 1) : celle du stick par rapport à la caméra, ou l'avant du corps si le stick
## est lâché.
func roll_direction() -> Vector3:
	var direction: Vector3 = Motion.camera_relative(stick, camera_yaw())
	if Vector2(direction.x, direction.z).is_zero_approx():
		return Motion.forward_of(rotation.y)
	return direction.normalized()


## Glisse `delta` secondes à la vitesse horizontale `horizontal` (la roulade) : gravité, puis collisions.
func slide(delta: float, horizontal: Vector3) -> void:
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= settings.gravity * delta
	move_and_slide()
#@ all
