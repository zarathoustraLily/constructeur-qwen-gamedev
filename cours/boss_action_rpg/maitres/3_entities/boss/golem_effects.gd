class_name GolemEffects extends Node3D
## Les effets visuels du golem : ils montrent ses coups et ne décident rien.
## - Un impact au sol (signal `slammed`) : une onde de poussière qui s'étend sur le plancher, un nuage, des éclats de
##   pierre, et la caméra qui tremble (moins fort de loin).
## - Pendant la fenêtre du marteau : une traînée derrière sa tête.
## - Un coup qui porte (zone de coup du marteau ou de l'onde) : des étincelles sur le héros.
## - À la seconde phase : une onde autour de lui, la caméra qui tremble, et les jointures de son armure qui s'allument,
##   braise qui palpite (une couche posée par-dessus l'armure, qui n'éclaire que les lignes claires de sa carte
##   d'émission). À sa chute : un nuage, et la braise s'éteint.
#@ 19+
## - Un tir qui porte (ni bloqué ni perdu) : les jointures brillent un instant, même en première phase.
#@ all
## Tout est préparé avec lui : aucun effet n'est créé en combat. Les effets sont posés dans le monde (top_level).

## Le nombre de positions gardées pour la traînée (une par image).
const TRAIL_CAPACITY: int = 32
## Le matériau des pièces d'armure (celles qui portent la braise).
const ARMOR_MATERIAL: String = "M_Golem_Armor.tres"

## Le golem montré.
@export var golem: Golem
## Durées, ampleurs, éclat.
@export var settings: GolemVfxSettings
## La couche de braise des jointures (copiée pour ce golem).
@export var ember: ShaderMaterial
## La caméra qui tremble (posée par la scène principale ; aucune : pas de tremblement).
@export var camera: OrbitCamera

## L'avancée de l'onde au sol, de 0 à 1 (1 : finie, cachée).
var shockwave_progress: float = 1.0
## L'éclat des jointures de l'armure, sans la palpitation.
var glow: float = 0.0
#@ 19+
## L'éclat d'un tir qui vient de porter, de 1 à 0.
var hit_flash: float = 0.0
#@ 13+
## Le nombre de positions de la traînée en ce moment.
var trail_count: int = 0
## La couche de braise propre à ce golem, posée sur chaque pièce de son armure.
var ember_material: ShaderMaterial
## Les pièces de son armure, qui portent la braise.
var armor_pieces: Array[MeshInstance3D] = []

var _clock: float = 0.0
var _trail_times: PackedFloat32Array = PackedFloat32Array()
var _trail_heads: PackedVector3Array = PackedVector3Array()
var _trail_grips: PackedVector3Array = PackedVector3Array()
var _trail_mesh: ImmediateMesh
var _shockwave_material: ShaderMaterial
#@ 13
var _glow_tween: Tween
#@ 14+
var _glow_target: float = 0.0
#@ 13+

@onready var _shockwave: MeshInstance3D = $Shockwave
@onready var _dust: GPUParticles3D = $SlamDust
@onready var _debris: GPUParticles3D = $SlamDebris
@onready var _sparks: GPUParticles3D = $HitSparks
@onready var _trail: MeshInstance3D = $HammerTrail
@onready var _hammer_tip: Node3D = golem.get_node(^"Model/Skeleton3D/WeaponR/HammerHit/Shape") as Node3D
@onready var _hammer_grip: Node3D = golem.get_node(^"Model/Skeleton3D/WeaponR") as Node3D


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	_trail_times.resize(TRAIL_CAPACITY)
	_trail_heads.resize(TRAIL_CAPACITY)
	_trail_grips.resize(TRAIL_CAPACITY)
	_trail_mesh = ImmediateMesh.new()
	_trail.mesh = _trail_mesh
	_shockwave_material = (_shockwave.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_shockwave.material_override = _shockwave_material
	_shockwave.visible = false
	ember_material = ember.duplicate() as ShaderMaterial
	for piece: Node in golem.get_node(^"Model").find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = piece as MeshInstance3D
		var source: Material = mesh_instance.get_active_material(0)
		if source != null and source.resource_path.get_file() == ARMOR_MATERIAL:
			mesh_instance.material_overlay = ember_material
			armor_pieces.append(mesh_instance)
	golem.slammed.connect(_on_slammed)
	golem.phase_changed.connect(_on_phase_changed)
	golem.defeated.connect(_on_defeated)
	# Ses enfants sont prêts avant lui : ses zones de coup se prennent par leur chemin.
	(golem.get_node(^"Model/Skeleton3D/WeaponR/HammerHit") as Hitbox).landed.connect(_on_landed)
	(golem.get_node(^"SlamZone") as Hitbox).landed.connect(_on_landed)
#@ 19+
	(golem.get_node(^"Hurtbox") as Hurtbox).received.connect(_on_shot)
	(golem.get_node(^"BackWeakPoint") as Hurtbox).received.connect(_on_shot)
#@ 13+


func _process(delta: float) -> void:
	update(delta)


## Fait passer `delta` secondes : l'onde avance, la traînée suit le marteau, la braise palpite.
func update(delta: float) -> void:
	_clock += delta
	if shockwave_progress < 1.0:
		shockwave_progress = minf(shockwave_progress + delta / settings.shockwave_time, 1.0)
		_shockwave_material.set_shader_parameter(&"progress", shockwave_progress)
		_shockwave.visible = shockwave_progress < 1.0
	_update_trail()
#@ 14+
	glow = move_toward(glow, _glow_target, settings.glow_energy * delta / settings.glow_time)
#@ 13+
#@ 13-18
	ember_material.set_shader_parameter(&"glow", glow * (1.0 + settings.glow_pulse * sin(_clock * settings.glow_pulse_speed)))
#@ 19+
	hit_flash = move_toward(hit_flash, 0.0, delta / settings.hit_glow_time)
	var ember_glow: float = glow * (1.0 + settings.glow_pulse * sin(_clock * settings.glow_pulse_speed))
	ember_material.set_shader_parameter(&"glow", ember_glow + hit_flash * settings.hit_glow)
#@ 13+


## Une onde de poussière de rayon `radius` part de `point`.
func play_shockwave(point: Vector3, radius: float) -> void:
	_shockwave.global_position = point + Vector3.UP * 0.05
	var size: float = radius * settings.shockwave_reach
	_shockwave.scale = Vector3(size, 1.0, size)
	shockwave_progress = 0.0
	_shockwave_material.set_shader_parameter(&"progress", 0.0)
	_shockwave.visible = true


func _on_slammed(point: Vector3, radius: float) -> void:
	play_shockwave(point, radius)
	_burst(_dust, point)
	_burst(_debris, point)
	_shake(point, settings.slam_shake, settings.slam_shake_time)


func _on_phase_changed(phase: int) -> void:
	if phase != 2:
		return
	var feet: Vector3 = golem.global_position
	play_shockwave(feet, settings.roar_radius)
	_burst(_dust, feet)
	_shake(feet, settings.roar_shake, settings.roar_shake_time)
	_fade_glow(settings.glow_energy)


func _on_defeated() -> void:
	_burst(_dust, golem.global_position)
	_fade_glow(0.0)


func _on_landed(body: Node3D, dealt: float) -> void:
	if dealt > 0.0:
		_burst(_sparks, body.global_position + Vector3.UP)


#@ 19+
func _on_shot(_amount: float, dealt: float) -> void:
	if dealt > 0.0:
		hit_flash = 1.0


#@ 13+
func _burst(particles: GPUParticles3D, at: Vector3) -> void:
	particles.global_position = at
	particles.restart()


func _shake(at: Vector3, strength: float, duration: float) -> void:
	if camera == null:
		return
	var near: float = 1.0 - clampf(camera.global_position.distance_to(at) / settings.shake_range, 0.0, 1.0)
	camera.shake(strength * near, duration)


func _fade_glow(to: float) -> void:
#@ 13
	if _glow_tween != null:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(self, ^"glow", to, settings.glow_time)
#@ 14+
	# Sans Tween : en créer un en plein combat, c'est des objets alloués ; l'éclat rejoint sa cible dans update.
	_glow_target = to
#@ 13+


## La traînée : pendant la fenêtre du marteau (élargie de `trail_margin`), une position par image ; les plus vieilles
## que `trail_time` s'en vont ; la bande est refaite à chaque image, du manche au bout, l'âge dans la couleur.
func _update_trail() -> void:
	var state: GolemAttackState = golem.machine.current as GolemAttackState
	if state != null:
		var strike: GolemAttack = golem.attack
		var t: float = state.clip_time
		if t >= strike.strike_start - settings.trail_margin and t <= strike.strike_end + settings.trail_margin:
			_add_trail_point()
	while trail_count > 0 and _clock - _trail_times[0] > settings.trail_time:
		_drop_oldest()
	_trail_mesh.clear_surfaces()
	if trail_count < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in trail_count:
		var age: float = 1.0 - (_clock - _trail_times[i]) / settings.trail_time
		var u: float = float(i) / float(trail_count - 1)
		_trail_mesh.surface_set_color(Color(1.0, 1.0, 1.0, age))
		_trail_mesh.surface_set_uv(Vector2(u, 0.0))
		_trail_mesh.surface_add_vertex(_trail_grips[i])
		_trail_mesh.surface_set_color(Color(1.0, 1.0, 1.0, age))
		_trail_mesh.surface_set_uv(Vector2(u, 1.0))
		_trail_mesh.surface_add_vertex(_trail_heads[i])
	_trail_mesh.surface_end()


func _add_trail_point() -> void:
	if trail_count == TRAIL_CAPACITY:
		_drop_oldest()
	var head: Vector3 = _hammer_tip.global_position
	var toward_grip: Vector3 = _hammer_grip.global_position - head
	_trail_times[trail_count] = _clock
	_trail_heads[trail_count] = head
	_trail_grips[trail_count] = head + toward_grip.normalized() * minf(settings.trail_width, toward_grip.length())
	trail_count += 1


func _drop_oldest() -> void:
	for i: int in trail_count - 1:
		_trail_times[i] = _trail_times[i + 1]
		_trail_heads[i] = _trail_heads[i + 1]
		_trail_grips[i] = _trail_grips[i + 1]
	trail_count -= 1
