class_name GolemView extends Node3D
## La vue du golem : elle ne décide rien ; elle montre ce que fait le golem. Elle écoute sa machine à états et joue le
## clip de l'état : l'attente quand il dort, récupère ou se tourne sur place ; la marche, à la vitesse de son corps
## (ses pieds ne glissent pas) ; le clip de l'attaque, à la vitesse de la phase ; le rugissement du passage à la seconde
## phase ; la chute. Le déplacement que portent les clips (os racine) est annulé sur le modèle : c'est son corps qui le
## suit (golem.gd). Pendant une frappe, elle penche son buste (GolemStrikeModifier) comme le veut l'attaque. À la
## seconde phase, il jette son bouclier : le bouclier quitte sa main et tombe à côté de lui.

## La vitesse des pieds au sol dans le clip de marche, à sa vitesse propre, en mètres par seconde (mesurée sur walkF) :
## la marche joue à walk_speed / WALK_FOOT_SPEED.
const WALK_FOOT_SPEED: float = 5.39
## Le fondu entre deux clips, en secondes.
const BLEND: float = 0.25
## L'état du golem → le clip qui le montre (Attack joue le clip de l'attaque ; Approach, la marche ou l'attente).
const CLIPS: Dictionary[StringName, StringName] = {
	&"Dormant": &"idle1", &"Wake": &"idle2", &"Recover": &"idle1", &"PhaseShift": &"gethit3", &"Dead": &"death1",
}
## La chute du bouclier jeté, en secondes.
const SHIELD_FALL: float = 0.7

## Le golem montré.
@export var golem: Golem
## Sa machine à états.
@export var machine: StateMachine
## Son modèle : squelette, armes, clips.
@export var model: Node3D

## Le bouclier jeté, posé dans le monde (rien tant qu'il est dans sa main).
var thrown_shield: Node3D
#@ 14+

var _shield_from: Transform3D = Transform3D.IDENTITY
var _shield_to: Transform3D = Transform3D.IDENTITY
var _shield_time: float = -1.0
#@ 12+

@onready var _player: AnimationPlayer = model.get_node(^"AnimationPlayer") as AnimationPlayer
@onready var _bend: GolemStrikeModifier = model.get_node(^"Skeleton3D/StrikeBend") as GolemStrikeModifier


func _ready() -> void:
	process_physics_priority = ProcessOrder.VIEWS
	_player.root_motion_track = Golem.ROOT_TRACK
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	_player.play(CLIPS[&"Dormant"])
	machine.state_changed.connect(_on_state_changed)
	golem.phase_changed.connect(_on_phase_changed)


#@ 12-13
func _physics_process(_delta: float) -> void:
	update()
#@ 14+
func _physics_process(delta: float) -> void:
	update()
	_fall_shield(delta)
#@ 12+


## Montre l'instant : la marche ou l'attente quand il s'approche, le penché du buste quand il frappe.
func update() -> void:
	var state: StringName = machine.current.name
	if state == &"Approach":
		var walking: bool = not golem.velocity.is_zero_approx()
		var clip: StringName = &"walkF" if walking else &"idle1"
		if _player.current_animation != clip:
			_player.play(clip, BLEND)
		_player.speed_scale = golem.settings.walk_speed / WALK_FOOT_SPEED if walking else 1.0
	var attacking: bool = state == &"Attack" and _player.current_animation == golem.attack.clip
	_bend.bend = golem.attack.bend_at(_player.current_animation_position) if attacking else 0.0


func _on_state_changed(_from: StringName, to: StringName) -> void:
	_player.speed_scale = 1.0
	if to == &"Attack":
#@ 12-19
		_player.play(golem.attack.clip, BLEND, golem.clip_speed())
#@ 20+
		_player.play(golem.attack.clip, BLEND, golem.clip_speed() * golem.attack.clip_rate)
#@ 12+
	elif CLIPS.has(to):
		_player.play(CLIPS[to], BLEND)


func _on_phase_changed(phase: int) -> void:
	if phase != 2 or thrown_shield != null:
		return
	var shield: Node3D = model.get_node(^"Skeleton3D/WeaponL/Shield") as Node3D
	shield.reparent(golem.get_parent(), true)
	thrown_shield = shield
	var side: Vector3 = golem.global_basis.x * -3.0
	var landing: Vector3 = Vector3(shield.global_position.x, golem.global_position.y + 0.2, shield.global_position.z) + side
#@ 12-13
	var fall: Tween = create_tween()
	fall.tween_property(shield, ^"global_position", landing, SHIELD_FALL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(shield, ^"rotation", Vector3(PI * 0.5, shield.rotation.y, 0.0), SHIELD_FALL)
#@ 14+
	# Sans Tween (des objets alloués en plein combat) : la chute avance dans _fall_shield, à chaque image.
	_shield_from = shield.global_transform
	var flat: Basis = Basis.from_euler(Vector3(PI * 0.5, shield.rotation.y, 0.0)).scaled(shield.global_basis.get_scale())
	_shield_to = Transform3D(flat, landing)
	_shield_time = 0.0
#@ 12+
#@ 14+


func _fall_shield(delta: float) -> void:
	if _shield_time < 0.0 or _shield_time >= SHIELD_FALL:
		return
	_shield_time = minf(_shield_time + delta, SHIELD_FALL)
	var t: float = _shield_time / SHIELD_FALL
	thrown_shield.global_transform = _shield_from.interpolate_with(_shield_to, t * t)
#@ all
