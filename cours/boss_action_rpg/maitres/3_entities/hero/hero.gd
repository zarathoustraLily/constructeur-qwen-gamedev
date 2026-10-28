class_name Hero extends CharacterBody3D
## Le héros : un corps qui court là où pousse le stick, par rapport à la caméra, et qui pivote vers sa marche. Il ne
## lit ni la manette ni le clavier : son entrée (hero_input.gd) lui donne la direction voulue ; lui calcule le
## mouvement (Motion) et laisse move_and_slide gérer les collisions.
#@ 4+
## Ce qu'il fait (courir, rouler) est choisi par sa machine à états (StateMachine, états Move et Roll) : chaque état
## appelle les mouvements ci-dessous ; l'endurance et la mémoire d'appui sont ses composants.
#@ 5+
## Il tire avec son arme (Gun) vers le point qu'il vise au centre de l'écran.
#@ all

## Vitesses, accélérations, virage, gravité.
@export var settings: HeroSettings
## Ce qui donne le lacet de la caméra (la caméra, ou son pivot).
@export var camera: Node3D
#@ 5+
## La caméra qui rend l'image : le centre de l'écran est le point visé.
@export var aim_camera: Camera3D
## La réserve des projectiles du niveau, donnée à l'arme.
@export var projectiles: ProjectilePool
#@ all

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
#@ 5+
## Vrai tant que la gâchette est tenue : l'arme tire à sa cadence (état Move).
var trigger: bool = false
#@ 4+

## L'endurance : la roulade et le sprint la dépensent.
@onready var stamina: StaminaComponent = $Stamina
## La mémoire d'appui de la roulade.
@onready var roll_buffer: InputBuffer = $RollBuffer
## Ce qu'il fait : Move ou Roll.
@onready var machine: StateMachine = $StateMachine
#@ 5+
## L'arme : sa bouche est à la main droite.
@onready var gun: HeroGun = $Gun
#@ all


func _ready() -> void:
#@ 2-3
	process_physics_priority = ProcessOrder.ACTORS
#@ all
	collision_layer = Layers.bit(Layers.HERO)
	collision_mask = Layers.mask([Layers.WORLD, Layers.BOSS])
#@ 4+
	roll_buffer.window = settings.roll_buffer_time
#@ 5+
	gun.pool = projectiles
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
#@ 2-4
	rotation.y = Motion.face(rotation.y, direction, settings.turn_speed, delta)
#@ 5+
	rotation.y = Motion.face(rotation.y, facing_direction(direction), settings.turn_speed, delta)
#@ all
	move_and_slide()
#@ 5+


## Où le corps se tourne : là où regarde la caméra en visant ou en tirant (on tire droit devant soi), sinon vers sa
## marche `direction`.
func facing_direction(direction: Vector3) -> Vector3:
	if aiming or trigger:
		return Motion.forward_of(camera_yaw())
	return direction


## Le point visé : ce que touche le rayon du centre de l'écran ; sans caméra de visée, droit devant le corps, à
## portée.
func aim_point() -> Vector3:
	if aim_camera == null:
		return gun.global_position + Motion.forward_of(rotation.y) * gun.settings.aim_range
	var forward: Vector3 = -aim_camera.global_basis.z
	return Aim.point(get_world_3d().direct_space_state, aim_camera.global_position, forward, gun.settings.aim_range,
			Projectile.hit_mask())
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
