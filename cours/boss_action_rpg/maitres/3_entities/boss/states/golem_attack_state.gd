class_name GolemAttackState extends State
## L'état Attack du golem : il joue l'attaque choisie (golem.attack), au temps de son clip (plus vif en seconde phase).
## Son corps suit le déplacement que porte le clip (os racine), allongé ou raccourci pour un coup visé ; il se tourne
## vers le héros pendant l'élan seulement ; son marteau frappe dans sa fenêtre ; un coup qui écrase le sol place l'onde
## juste avant l'impact et la déclenche à l'impact. Le clip fini, il récupère (Recover), ou, en seconde phase, enchaîne
## (Approach) jusqu'à `phase_two_chain` coups ; si la seconde phase est due, elle passe d'abord (PhaseShift).

## Le golem piloté.
@export var golem: Golem
## La durée de l'onde d'un impact au sol, en secondes.
@export_range(0.01, 1.0, 0.01) var slam_duration: float = 0.15
## L'onde est placée cette avance avant l'impact, en secondes : les corps déjà dedans sont vus au déclenchement.
@export_range(0.0, 1.0, 0.01) var slam_lead: float = 0.2

## Le temps du clip, en secondes (à sa vitesse propre).
var clip_time: float = 0.0

var _placed: bool = false
var _motion_scale: float = 1.0
var _slammed: bool = false
var _slam_point: Vector3 = Vector3.ZERO


## L'attaque commence ; il le dit.
func enter(_previous: StringName) -> void:
	clip_time = 0.0
	_placed = false
	_slammed = false
	_motion_scale = golem.motion_scale(golem.attack)
	golem.begin_attack()


## Ses zones de coup s'éteignent, quoi qu'il arrive.
func exit() -> void:
	golem.hammer.deactivate()
	golem.slam_zone.deactivate()
	golem.velocity = Vector3.ZERO


## Le clip avance : le corps suit, le marteau et l'onde frappent à leurs instants.
func physics_update(delta: float) -> void:
	var strike: GolemAttack = golem.attack
	var before: float = clip_time
	clip_time += delta * golem.clip_speed()
	if clip_time <= strike.track_until:
		golem.face_target(delta)
	var moved: Vector3 = (golem.root_offset(strike.clip, clip_time) - golem.root_offset(strike.clip, before)) * _motion_scale
	golem.velocity = moved / delta
	golem.move_and_slide()
	golem.velocity = Vector3.ZERO
	var striking: bool = clip_time >= strike.strike_start and clip_time < strike.strike_end
	if striking and not golem.hammer.active:
		golem.hammer.activate(strike.damage)
	elif not striking and golem.hammer.active:
		golem.hammer.deactivate()
	if strike.slam:
		_update_slam(strike)
	if clip_time >= golem.clip_length(strike.clip):
		_finish_attack()


func _update_slam(strike: GolemAttack) -> void:
	if not _placed and clip_time >= strike.slam_time - slam_lead:
		_placed = true
		# Placée d'avance : là où sera le point d'impact quand son corps aura fini d'avancer jusqu'à l'impact.
		var still: Vector3 = golem.root_offset(strike.clip, strike.slam_time) - golem.root_offset(strike.clip, clip_time)
		_slam_point = golem.slam_point(strike) + still * _motion_scale
		golem.slam_zone.global_position = _slam_point
		((golem.slam_zone.get_node("Shape") as CollisionShape3D).shape as SphereShape3D).radius = strike.slam_radius
	if not _slammed and clip_time >= strike.slam_time:
		_slammed = true
		golem.strike_ground(_slam_point, strike.slam_radius, strike.slam_damage)
	if golem.slam_zone.active and clip_time >= strike.slam_time + slam_duration:
		golem.slam_zone.deactivate()


func _finish_attack() -> void:
	if golem.phase_two_due:
		finish(&"PhaseShift")
	elif golem.phase == 2 and golem.chained < golem.settings.phase_two_chain:
		finish(&"Approach")
	else:
		finish(&"Recover")
