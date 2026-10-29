class_name Spectre extends Node3D
## Un spectre : l'âme d'un aventurier vaincu par le Gardien. Il vole et traverse le décor. Il dort jusqu'à ce que le
## boss l'appelle (activate) ; sa machine à états le fait alors planer autour du héros (Hover), annoncer sa plongée en
## s'illuminant (Windup), plonger sur lui (Dive), remonter (Recover) ; abattu au fusil, il se dissipe (Fade) et se
## rendort pour de bon (Idle). Sa vue (spectre_view.gd) montre tout cela ; lui ne fait que bouger et décider.

## Le spectre abattu s'est dissipé.
signal dissipated

## Planée, annonce, plongée, remontée, dissipation.
@export var settings: SpectreSettings

## Ce qu'il chasse (le héros), posé à l'appel.
var target: Node3D
## La santé de ce qu'il chasse : abattu, il ne plonge plus sur lui (rien si la cible n'en a pas).
var target_health: HealthComponent
## L'angle de sa place sur le cercle autour de sa cible, en radians.
var orbit_angle: float = 0.0
## Vrai une fois dissipé : il ne revient plus.
var gone: bool = false

## Ce qu'il fait : Idle, Hover, Windup, Dive, Recover, Fade.
@onready var machine: StateMachine = $StateMachine
## Sa santé : trois tirs.
@onready var health: HealthComponent = $Health
## La zone qui reçoit les tirs.
@onready var hurtbox: Hurtbox = $Hurtbox
## La zone de coup de sa plongée.
@onready var hitbox: Hitbox = $Hitbox


func _ready() -> void:
	visible = false
	hurtbox.collision_layer = 0
	health.died.connect(_on_died)


## Vrai entre l'appel et la dissipation.
func is_active() -> bool:
	return visible and not gone


## Le boss l'appelle : il chasse `prey` (de santé `prey_health`), sa place sur le cercle part de l'angle `angle`.
func activate(prey: Node3D, angle: float, prey_health: HealthComponent = null) -> void:
	if gone:
		return
	target = prey
	target_health = prey_health
	orbit_angle = angle
	visible = true
	hurtbox.collision_layer = Layers.bit(Layers.TARGETS)
	machine.transition_to(&"Hover")


## Vrai tant que sa cible n'est pas abattue.
func prey_alive() -> bool:
	return target_health == null or not target_health.is_dead()


## Sa place sur le cercle autour de sa cible, à la hauteur de planée.
func hover_point() -> Vector3:
	var autour: Vector3 = Vector3(cos(orbit_angle), 0.0, sin(orbit_angle)) * settings.hover_radius
	return target.global_position + autour + Vector3.UP * settings.hover_height


## Le point que vise une plongée : le torse de sa cible, à l'instant où elle part.
func dive_point() -> Vector3:
	return target.global_position + Vector3.UP


## Rejoint `point` en douceur pendant `delta` secondes (suivi exponentiel), tourné vers sa cible.
func glide_to(point: Vector3, delta: float) -> void:
	global_position = global_position.lerp(point, 1.0 - exp(-settings.follow_speed * delta))
	face_target()


## Se tourne vers sa cible (au sol).
func face_target() -> void:
	var vers: Vector3 = target.global_position - global_position
	vers.y = 0.0
	if not vers.is_zero_approx():
		rotation.y = Motion.yaw_of(vers)


## Se dissipe pour de bon : invisible, plus rien ne le touche ; il le dit.
func vanish() -> void:
	gone = true
	visible = false
	machine.transition_to(&"Idle")
	dissipated.emit()


func _on_died() -> void:
	hitbox.deactivate()
	hurtbox.collision_layer = 0
	machine.transition_to(&"Fade")
