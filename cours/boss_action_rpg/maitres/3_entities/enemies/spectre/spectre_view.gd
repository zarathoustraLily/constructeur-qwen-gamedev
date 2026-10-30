class_name SpectreView extends Node3D
## La vue d'un spectre : le squelette spectral (SpectreModel) sous le shader de spectre, avec un matériau à lui pour
## qu'il ait son propre éclat. Elle le fait vivre sans clip d'animation : chaque état a sa pose, vers laquelle les os
## glissent en douceur, et une houle s'y ajoute (il flotte, ses bras se balancent). Pour annoncer sa plongée, il se
## cabre, bras et mâchoire grands ouverts, en s'illuminant ; il plonge couché, griffes en avant, le linceul étiré
## derrière lui ; il se relève ; dissipé, il s'affaisse en s'éteignant. Elle ne décide rien.
#@ 17+
## Une traîne de lumière le suit, partie du bas de son linceul (SpectreTrail).
#@ all

## Une pose du squelette.
class Pose:
	## Penché en avant autour de la poitrine (radians ; négatif : cabré).
	var lean: float = 0.0
	## Rotation de l'épaule droite (Euler, radians) ; la gauche est son miroir.
	var shoulder: Vector3 = Vector3.ZERO
	## Pli des coudes vers l'avant, en radians.
	var elbow: float = 0.0
	## Pli des poignets vers l'avant (griffes recourbées), en radians.
	var wrist: float = 0.0
	## Ouverture de la mâchoire, en radians.
	var jaw: float = 0.0
	## Tête baissée (radians ; négatif : relevée).
	var head: float = 0.0
	## Le corps descend (négatif) ou monte par rapport à la place du spectre, en mètres.
	var rise: float = 0.0
	## Étirement du linceul derrière lui, en mètres.
	var trail: float = 0.0

	func _init(p_lean: float, p_shoulder: Vector3, p_elbow: float, p_wrist: float, p_jaw: float, p_head: float,
			p_rise: float, p_trail: float) -> void:
		lean = p_lean
		shoulder = p_shoulder
		elbow = p_elbow
		wrist = p_wrist
		jaw = p_jaw
		head = p_head
		rise = p_rise
		trail = p_trail

	## Glisse vers `target` : la fraction `k` (0 à 1) du chemin qui reste.
	func blend_toward(target: Pose, k: float) -> void:
		lean = lerpf(lean, target.lean, k)
		shoulder = shoulder.lerp(target.shoulder, k)
		elbow = lerpf(elbow, target.elbow, k)
		wrist = lerpf(wrist, target.wrist, k)
		jaw = lerpf(jaw, target.jaw, k)
		head = lerpf(head, target.head, k)
		rise = lerpf(rise, target.rise, k)
		trail = lerpf(trail, target.trail, k)


## Le point du modèle autour duquel il se penche (la poitrine).
const CHEST: Vector3 = Vector3(0.0, 1.2, 0.0)
## La vitesse à laquelle les os rejoignent leur pose (par seconde).
const POSE_SPEED: float = 8.0
#@ 17+
## Le point du modèle d'où part la traîne (le bas du linceul).
const TRAIL_ANCHOR: Vector3 = Vector3(0.0, 0.6, 0.0)
#@ all

## Le spectre montré.
@export var spectre: Spectre
## Sa machine à états.
@export var machine: StateMachine
## Le matériau de spectre (copié pour ce spectre).
@export var material: ShaderMaterial

## L'éclat du moment (paramètre `intensity` du shader).
var intensity: float = 0.0
## Le matériau propre à ce spectre.
var own_material: ShaderMaterial
## La pose du moment.
var pose: Pose = Pose.new(0.0, Vector3.ZERO, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

var _poses: Dictionary[StringName, Pose] = {
	&"Hover": Pose.new(0.1, Vector3(0.35, 0.0, 0.25), 0.6, 0.4, 0.12, 0.05, 0.0, 0.0),
	&"Windup": Pose.new(-0.35, Vector3(-0.4, 0.0, 2.2), 0.5, -0.3, 0.6, -0.25, 0.15, 0.0),
	&"Dive": Pose.new(1.15, Vector3(2.6, 0.0, 0.25), 0.15, 0.2, 0.5, -0.6, -0.7, 0.6),
	&"Recover": Pose.new(-0.15, Vector3(0.2, 0.0, 0.9), 0.6, 0.5, 0.15, 0.1, 0.0, 0.25),
	&"Fade": Pose.new(0.4, Vector3(0.1, 0.0, 0.1), 0.2, 0.8, 0.7, 0.7, -0.5, 0.0),
}
var _clock: float = 0.0

@onready var _model: SpectreModel = $Model
#@ 17+
@onready var _trail: SpectreTrail = $Trail
#@ all


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	own_material = material.duplicate() as ShaderMaterial
	for n: Node in _model.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).material_override = own_material
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	intensity = spectre.settings.base_intensity
	# Chaque spectre a sa houle, décalée par sa place de départ.
	_clock = spectre.position.x
#@ 17+
	_trail.settings = spectre.settings
#@ all


func _process(delta: float) -> void:
	update(delta)


## Fait passer `delta` secondes : l'éclat (il monte vers l'éclat d'annonce pendant Windup, s'éteint pendant Fade,
## revient à l'éclat ordinaire sinon), puis la pose de l'état, puis la houle.
func update(delta: float) -> void:
	var s: SpectreSettings = spectre.settings
	var etat: StringName = machine.current.name
	if etat == &"Windup":
		intensity = move_toward(intensity, s.windup_intensity, (s.windup_intensity - s.base_intensity) * delta / s.windup_time)
	elif etat == &"Fade":
		intensity = move_toward(intensity, 0.0, s.base_intensity * delta / s.fade_time)
	else:
		intensity = move_toward(intensity, s.base_intensity, s.windup_intensity * delta)
	own_material.set_shader_parameter(&"intensity", intensity)
	pose.blend_toward(_poses.get(etat, _poses[&"Hover"]), 1.0 - exp(-POSE_SPEED * delta))
	_clock += delta
	_show(etat)
#@ 17+
	_trail.follow(_model.global_transform * TRAIL_ANCHOR, delta, intensity)
#@ all


## Pose les os : la pose du moment, plus la houle (le corps flotte, les bras se balancent, la mâchoire claque pendant
## l'annonce).
func _show(etat: StringName) -> void:
	var swing: float = sin(_clock * 1.3) * 0.12
	var tilt: Basis = Basis(Vector3.RIGHT, -pose.lean)
	_model.transform = Transform3D(tilt, CHEST - tilt * CHEST + Vector3(0.0, pose.rise + sin(_clock * 1.7) * 0.05, 0.0))
	_model.head.rotation.x = -pose.head
	var chatter: float = absf(sin(_clock * 14.0)) * 0.12 if etat == &"Windup" else 0.0
	_model.jaw.rotation.x = -(pose.jaw + chatter)
	for k: int in 2:
		var mirror: float = -1.0 if k == 0 else 1.0
		var arm: Vector3 = pose.shoulder + Vector3(swing * (1.0 if k == 0 else -0.8), 0.0, 0.0)
		_model.shoulders[k].rotation = Vector3(arm.x, arm.y * mirror, arm.z * mirror)
		_model.elbows[k].rotation.x = pose.elbow
		_model.wrists[k].rotation.x = pose.wrist
	own_material.set_shader_parameter(&"trail", pose.trail)
