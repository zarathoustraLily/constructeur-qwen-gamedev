class_name Golem extends CharacterBody3D
#@ 7-11
## Le Gardien du Comptoir : un golem de pierre en armure, quatre fois la taille d'un homme, qui garde le comptoir du
## saloon d'un géant. À cette étape, il tient sa place (son modèle joue l'attente) ; il a son corps (couche du boss),
## sa santé, la zone qui reçoit les tirs du héros et le point que la caméra verrouille, à hauteur de poitrine. Sa
## machine à états (réveil, approche, attaques) vient ensuite.
#@ 12+
## Le Gardien du Comptoir : un golem de pierre en armure, quatre fois la taille d'un homme, qui garde le comptoir du
## saloon d'un géant. Il dort jusqu'à ce que le héros approche ou le touche. Réveillé, il marche vers lui et choisit
## une attaque selon la distance ; l'attaque joue son clip, et son corps suit le déplacement que porte le clip (l'os
## racine) ; son marteau frappe dans sa fenêtre, certains coups écrasent le sol ; après, il récupère : c'est le moment
## de le punir, de dos surtout (son point faible). Son bouclier bloque les tirs. Quand il a perdu 30 % de sa vie, la
## seconde phase commence : il jette son bouclier, ses spectres sortent (SpectreCall), ses coups sont plus vifs, il
## enchaîne et bondit. Sa vue (golem_view.gd) montre tout cela ; lui ne fait que bouger et décider.
#@ 20+
## De loin, il lance des boules de feu ; en seconde phase, des éclairs : un sort s'annonce (charge_started), part
## (spell_cast), et ses sorts (golem_spells.gd) font le reste. Un coup peut demander un repos avant de resservir.
#@ 12+

## Il s'est réveillé.
signal woke
## La phase du combat a changé (2 : la seconde phase commence).
signal phase_changed(phase: int)
## L'attaque `attack` commence.
signal attack_started(attack: GolemAttack)
## Le sol est écrasé en `point`, une onde de rayon `radius`.
signal slammed(point: Vector3, radius: float)
## Il est vaincu.
signal defeated
#@ 20+
## Le sort de l'attaque `attack` se prépare : il s'annonce.
signal charge_started(attack: GolemAttack)
## Le sort de l'attaque `attack` part.
signal spell_cast(attack: GolemAttack)
## L'attaque qui portait un sort est finie, ou interrompue.
signal charge_ended
#@ 12+

## Le modèle est quatre fois plus grand que ses clips.
const MODEL_SCALE: float = 4.0
## La piste qui porte le déplacement des clips : l'os racine.
const ROOT_TRACK: NodePath = ^"Skeleton3D:root"
## Pour vérifier un chemin, son corps est soulevé d'autant, en mètres : le plancher ne compte pas.
const PATH_LIFT: float = 0.3

## Réveil, marche, attaques, seconde phase.
@export var settings: GolemSettings
## Ses clips : on y lit le déplacement que porte chaque attaque.
@export var animations: AnimationLibrary
## Ce qu'il combat (le héros).
@export var target: Node3D

## La phase du combat : 1, puis 2.
var phase: int = 1
## L'attaque en cours, ou la dernière.
var attack: GolemAttack
## Vrai quand sa vie est passée sous le seuil : la seconde phase commence dès qu'il n'est plus en pleine attaque.
var phase_two_due: bool = false
## Les attaques enchaînées depuis sa dernière récupération.
var chained: int = 0

var _next: int = 0
#@ 20+
var _clock: float = 0.0
var _used_at: Dictionary[StringName, float] = {}
#@ 12+
#@ 14+
var _path_query: PhysicsShapeQueryParameters3D
#@ 7+

## La santé du golem.
@onready var health: HealthComponent = $Health
## Le point que la caméra verrouille.
@onready var lock_point: Node3D = $LockPoint
#@ 12+
## Ce qu'il fait : Dormant, Wake, Approach, Attack, Recover, PhaseShift, Dead.
@onready var machine: StateMachine = $StateMachine
## La zone de coup de son marteau, sur la tête du marteau.
@onready var hammer: Hitbox = $Model/Skeleton3D/WeaponR/HammerHit
## La zone de coup de ses impacts au sol.
@onready var slam_zone: Hitbox = $SlamZone
## Son bouclier : il bloque les tirs (jusqu'à la seconde phase).
@onready var shield: Hurtbox = $Model/Skeleton3D/WeaponL/ShieldGuard
#@ 7+


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BOSS)
	collision_mask = Layers.mask([Layers.WORLD, Layers.HERO])
#@ 12+
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
#@ 14+
	# La requête du chemin est créée une fois : en créer une à chaque choix de coup était une allocation en combat.
	_path_query = PhysicsShapeQueryParameters3D.new()
	_path_query.shape = ($Shape as CollisionShape3D).shape
	_path_query.collision_mask = Layers.bit(Layers.WORLD)
	_path_query.exclude = [get_rid()]
#@ 20+


func _physics_process(delta: float) -> void:
	_clock += delta
#@ 12+


## La distance au sol jusqu'à sa cible.
func distance_to_target() -> float:
	var vers: Vector3 = target.global_position - global_position
	vers.y = 0.0
	return vers.length()


## L'angle entre là où il regarde et sa cible, en radians (0 : en face).
func angle_to_target() -> float:
	var vers: Vector3 = target.global_position - global_position
	vers.y = 0.0
	if vers.is_zero_approx():
		return 0.0
	return absf(angle_difference(rotation.y, Motion.yaw_of(vers)))


## Se tourne vers sa cible, d'au plus turn_speed × delta.
func face_target(delta: float) -> void:
	var vers: Vector3 = target.global_position - global_position
	vers.y = 0.0
	if not vers.is_zero_approx():
		rotation.y = rotate_toward(rotation.y, Motion.yaw_of(vers), settings.turn_speed * delta)


## La vitesse de ses clips : plus vive en seconde phase.
func clip_speed() -> float:
	return settings.phase_two_speed if phase == 2 else 1.0


## La durée du clip `clip`, en secondes (à sa vitesse propre).
func clip_length(clip: StringName) -> float:
	return animations.get_animation(clip).length


## La prochaine attaque permise à la distance `distance` : il essaie ses attaques dans l'ordre, à partir de celle qui
## suit la dernière choisie (il ne répète pas un coup s'il en a un autre), et ne garde un coup qui porte son corps que si
## le chemin est libre ; aucune : null.
func choose_attack(distance: float) -> GolemAttack:
	var count: int = settings.attacks.size()
	for i: int in count:
		var candidate: GolemAttack = settings.attacks[(_next + i) % count]
#@ 12-19
		if candidate.allowed(distance, phase) and path_clear(candidate):
			_next = (_next + i + 1) % count
			return candidate
#@ 20+
		if candidate.allowed(distance, phase) and rested(candidate) and path_clear(candidate):
			_next = (_next + i + 1) % count
			_used_at[candidate.id] = _clock
			return candidate
#@ 12+
	return null


#@ 20+
## Vrai si le coup `strike` s'est assez reposé pour resservir.
func rested(strike: GolemAttack) -> bool:
	return not _used_at.has(strike.id) or _clock - _used_at[strike.id] >= strike.cooldown


#@ 12+
## Le déplacement que porte le clip `clip` de son début à l'instant `t` (l'os racine), au sol et dans le monde, selon
## la direction où il regarde : le modèle est quatre fois plus grand que le clip et tourné d'un demi-tour.
func root_offset(clip: StringName, t: float) -> Vector3:
	var animation: Animation = animations.get_animation(clip)
	var track: int = animation.find_track(ROOT_TRACK, Animation.TYPE_POSITION_3D)
	if track < 0:
		return Vector3.ZERO
	var moved: Vector3 = animation.position_track_interpolate(track, t) - animation.position_track_interpolate(track, 0.0)
	return global_basis * (Vector3(-moved.x, 0.0, -moved.z) * MODEL_SCALE)


## Vrai si son corps peut parcourir, vers sa cible et sans heurter le décor, le déplacement que porte le clip de
## l'attaque `strike` (toujours vrai pour un coup sur place). Le corps est soulevé de `PATH_LIFT` : le plancher et les
## débris plus bas ne comptent pas.
func path_clear(strike: GolemAttack) -> bool:
	var reach: float = root_offset(strike.clip, clip_length(strike.clip)).length() * motion_scale(strike)
	if is_zero_approx(reach):
		return true
	var toward: Vector3 = target.global_position - global_position
	toward.y = 0.0
	if toward.is_zero_approx():
		return true
	var body: CollisionShape3D = $Shape as CollisionShape3D
#@ 12-13
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = body.shape
#@ 14+
	var query: PhysicsShapeQueryParameters3D = _path_query
#@ 12+
	query.transform = body.global_transform.translated(Vector3.UP * PATH_LIFT)
	query.motion = toward.normalized() * reach
#@ 12-13
	query.collision_mask = Layers.bit(Layers.WORLD)
	query.exclude = [get_rid()]
#@ 12+
	return get_world_3d().direct_space_state.cast_motion(query)[0] >= 1.0


## La part du déplacement du clip que son corps parcourt pendant l'attaque `strike` : 1, sauf pour un coup visé, où
## l'impact doit tomber sur sa cible (dans les bornes du coup) : le déplacement jusqu'à l'impact, plus le point
## d'impact devant lui, font la distance à la cible.
func motion_scale(strike: GolemAttack) -> float:
	if not strike.aimed:
		return 1.0
	var until_impact: float = root_offset(strike.clip, strike.slam_time).length()
	if is_zero_approx(until_impact):
		return 1.0
	return clampf((distance_to_target() - strike.slam_offset.y) / until_impact, strike.aim_min, strike.aim_max)


## Le point d'impact au sol de l'attaque `strike`, depuis là où il est et où il regarde.
func slam_point(strike: GolemAttack) -> Vector3:
	var forward: Vector3 = Motion.forward_of(rotation.y)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x)
	var point: Vector3 = global_position + forward * strike.slam_offset.y + right * strike.slam_offset.x
	point.y = global_position.y
	return point


## Il se réveille, et le dit.
func wake_up() -> void:
	woke.emit()


## L'attaque `golem.attack` commence : elle compte dans la série enchaînée ; il le dit.
func begin_attack() -> void:
	chained += 1
	attack_started.emit(attack)


#@ 20+
## Le sort de `strike` se prépare ; il le dit.
func begin_charge(strike: GolemAttack) -> void:
	charge_started.emit(strike)


## Le sort de `strike` part ; il le dit.
func cast_spell(strike: GolemAttack) -> void:
	spell_cast.emit(strike)


## L'attaque qui portait un sort est finie ; il le dit.
func end_charge() -> void:
	charge_ended.emit()


#@ 12+
## Il écrase le sol en `point` : l'onde (placée là d'avance) frappe de `damage` dans le rayon `radius` ; il le dit.
func strike_ground(point: Vector3, radius: float, damage: float) -> void:
	slam_zone.activate(damage)
	slammed.emit(point, radius)


## La seconde phase commence : son bouclier ne bloque plus, il le dit.
func enter_phase_two() -> void:
	phase = 2
	phase_two_due = false
	shield.collision_layer = 0
	phase_changed.emit(2)


## Plus rien ne le touche ni ne frappe : il est tombé.
func fall() -> void:
	hammer.deactivate()
	slam_zone.deactivate()
	for zone: Node in find_children("*", "Area3D", true, false):
		if zone is Hurtbox:
			(zone as Hurtbox).collision_layer = 0
	defeated.emit()


func _on_damaged(_amount: float, remaining: float) -> void:
	if health.is_dead():
		return
	if phase == 1 and remaining <= health.settings.max_health * settings.phase_two_ratio:
		phase_two_due = true
	if machine.current.name == &"Dormant":
		machine.transition_to(&"Wake")
	if phase_two_due and machine.current.name in [&"Wake", &"Approach", &"Recover"]:
		machine.transition_to(&"PhaseShift")


func _on_died() -> void:
	machine.transition_to(&"Dead")
