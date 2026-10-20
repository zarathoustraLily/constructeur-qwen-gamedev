class_name WheelSplashEffects extends Node3D
## Gerbes et traînées des roues : très fortes sur la mer, légères sur la route mouillée. Les enfants SeaDroplets,
## SeaSpray, RoadDroplets, SeaTrail et RoadTrail servent de modèles, dupliqués pour chaque roue au démarrage :
## gouttelettes autour de chaque roue, embruns et traînée derrière les roues arrière. C'est une présentation :
## ondulations, vagues et écume, qui changent l'eau, viennent du sillage du kart (KartWake).


## Les effets d'une roue.
class WheelFx:
	## La roue.
	var wheel: WheelView
	## Vrai pour une roue arrière : elle a des embruns et des traînées.
	var rear: bool
	## Gouttelettes sur la mer.
	var sea_droplets: GPUParticles3D
	## Gouttelettes sur la route mouillée.
	var road_droplets: GPUParticles3D
	## Embruns sur la mer (roues arrière).
	var sea_spray: GPUParticles3D
	## Traînée sur la mer (roues arrière).
	var sea_trail: WheelTrail
	## Traînée sur la route mouillée (roues arrière).
	var road_trail: WheelTrail


## Le kart dont les roues éclaboussent.
@export var kart: Kart
## Ses roues.
@export var wheels: Array[WheelView] = []

@export_group("Mer")
## Multiplicateur des effets sur l'eau.
@export_range(0.0, 2.0) var sea_strength: float = 1.0
## Une roue est « dans l'eau » si elle est à moins de cette hauteur au-dessus de la surface (m).
@export var sea_contact_margin: float = 0.15

@export_group("Route")
## Multiplicateur des effets sur la route, lui-même multiplié par le mouillage.
@export_range(0.0, 2.0) var road_strength: float = 1.0
## Mouillage de la route, de 0 (sèche : aucun effet) à 1.
@export_range(0.0, 1.0) var road_wetness: float = 0.0

@export_group("Vitesse")
## Vitesse (m/s) à partir de laquelle les effets apparaissent.
@export var min_speed: float = 1.5
## Vitesse (m/s) à laquelle les effets atteignent leur maximum.
@export var full_speed: float = 15.0

var _fx: Array[WheelFx] = []
## Repère horizontal du kart pour l'image en cours (x à droite, z vers l'arrière).
var _emit_basis: Basis

@onready var _sea_droplets: GPUParticles3D = $SeaDroplets
@onready var _sea_spray: GPUParticles3D = $SeaSpray
@onready var _road_droplets: GPUParticles3D = $RoadDroplets
@onready var _sea_trail: WheelTrail = $SeaTrail
@onready var _road_trail: WheelTrail = $RoadTrail


func _ready() -> void:
	for template: GPUParticles3D in [_sea_droplets, _sea_spray, _road_droplets]:
		template.emitting = false
		template.visible = false
	_sea_trail.visible = false
	_road_trail.visible = false
	# Scène ouverte seule, hors d'un kart : aucun effet à produire.
	if kart == null:
		set_process(false)
		return
	for wheel: WheelView in wheels:
		var fx := WheelFx.new()
		fx.wheel = wheel
		fx.rear = not wheel.steering_enabled
		fx.sea_droplets = _make_emitter(_sea_droplets)
		fx.road_droplets = _make_emitter(_road_droplets)
		if fx.rear:
			fx.sea_spray = _make_emitter(_sea_spray)
			fx.sea_trail = _make_trail(_sea_trail)
			fx.road_trail = _make_trail(_road_trail)
		_fx.append(fx)


func _make_emitter(template: GPUParticles3D) -> GPUParticles3D:
	var emitter := template.duplicate() as GPUParticles3D
	var process := (template.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	emitter.process_material = process
	emitter.set_meta("base_direction", process.direction)
	emitter.set_meta("base_velocity", Vector2(process.initial_velocity_min, process.initial_velocity_max))
	emitter.top_level = true
	emitter.visible = true
	emitter.emitting = false
	add_child(emitter)
	return emitter


func _make_trail(template: WheelTrail) -> WheelTrail:
	var trail := template.duplicate() as WheelTrail
	trail.visible = true
	add_child(trail)
	return trail


func _process(_delta: float) -> void:
	var speed := kart.get_horizontal_velocity().length()
	var moving := speed > min_speed
	var speed_factor := clampf(inverse_lerp(min_speed, full_speed, speed), 0.0, 1.0)
	var water_height := kart.water_sensor.get_water_height()
	var kart_basis := kart.global_basis
	var right := Vector3(kart_basis.x.x, 0.0, kart_basis.x.z).normalized()
	var forward := Vector3(-kart_basis.z.x, 0.0, -kart_basis.z.z).normalized()
	_emit_basis = Basis(right, Vector3.UP, -forward)
	var sea_factor := (0.25 + 0.75 * speed_factor) * sea_strength
	var road_factor := (0.2 + 0.8 * speed_factor) * road_strength * road_wetness
	for fx: WheelFx in _fx:
		var contact := fx.wheel.get_wheel_position()
		var side_sign := 1.0 if (contact - kart.global_position).dot(right) >= 0.0 else -1.0
		var in_water := kart.is_in_water() and contact.y <= water_height + sea_contact_margin
		var on_road := not in_water and fx.wheel.is_grounded()
		var water_point := Vector3(contact.x, water_height, contact.z)
		# Mer : gouttelettes autour de chaque roue, embruns derrière les roues arrière.
		var sea_on := in_water and moving and sea_strength > 0.0
		_drive_emitter(fx.sea_droplets, sea_on, sea_factor, water_point, side_sign, 0.5 + speed_factor)
		if fx.sea_spray != null:
			_drive_emitter(fx.sea_spray, sea_on, sea_factor, water_point + Vector3.UP * 0.12, side_sign,
				0.4 + speed_factor)
		# Route mouillée : petites gouttelettes.
		var road_on := on_road and moving and road_factor > 0.02
		var road_point := fx.wheel.get_contact_point() if on_road else contact
		_drive_emitter(fx.road_droplets, road_on, road_factor, road_point, side_sign, 0.5 + speed_factor)
		# Traînées, roues arrière.
		if fx.rear:
			if sea_on:
				fx.sea_trail.add_point(water_point, right, Vector3.UP, minf(sea_factor, 1.0))
			else:
				fx.sea_trail.stop()
			if road_on:
				var normal := fx.wheel.get_contact_normal()
				var across := normal.cross(forward).normalized() * -1.0
				fx.road_trail.add_point(road_point, across, normal, minf(road_factor, 1.0))
			else:
				fx.road_trail.stop()


## Allume ou éteint `emitter` ; allumé, il est placé en `pos`, orienté vers l'extérieur du kart (`side_sign`),
## avec `amount` de ses particules et une vitesse multipliée par `velocity_scale`. Dans le modèle, x pointe vers
## l'extérieur du kart, y vers le haut, z vers l'arrière.
func _drive_emitter(emitter: GPUParticles3D, on: bool, amount: float, pos: Vector3, side_sign: float,
		velocity_scale: float) -> void:
	if on:
		emitter.global_transform = Transform3D(_emit_basis, pos)
		var process := emitter.process_material as ParticleProcessMaterial
		var base_direction: Vector3 = emitter.get_meta("base_direction")
		var base_velocity: Vector2 = emitter.get_meta("base_velocity")
		process.direction = Vector3(base_direction.x * side_sign, base_direction.y, base_direction.z)
		process.initial_velocity_min = base_velocity.x * velocity_scale
		process.initial_velocity_max = base_velocity.y * velocity_scale
		emitter.amount_ratio = clampf(amount, 0.05, 1.0)
	if emitter.emitting != on:
		emitter.emitting = on
