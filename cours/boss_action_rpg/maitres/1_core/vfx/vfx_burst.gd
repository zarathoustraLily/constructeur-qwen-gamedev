class_name VfxBurst extends Node3D
## Un effet bref, préparé d'avance et rejoué sans rien créer. À chaque `play` : ses enfants GPUParticles3D repartent, et
## s'il en a, sa lueur (enfant Glow) et sa lumière (enfant Light) s'allument puis s'éteignent sur `duration`. Il se cache
## quand tout est fini : au repos, il ne coûte rien au rendu. C'est le contrôleur des effets de Binbun (CC0), typé, sans
## leur AnimationPlayer : le temps suit `update`, et les particules se relancent par `restart`, sans allocation.
#@ 23+
## Un enfant Stream est un flux, pas une salve : il coule tant que l'effet est rejoué, et ses particules vivent leur vie : la
## fumée d'une rafale ne disparaît pas au tir suivant.
#@ all

#@ 19
## Le groupe des effets : la qualité graphique leur coupe la lumière.
#@ 20+
## Le groupe des effets : la qualité graphique règle leur `light_allowed`.
#@ all
const GROUP: StringName = &"vfx_burst"

## Le temps que mettent la lueur et la lumière à s'éteindre, en secondes.
@export_range(0.01, 5.0, 0.01) var duration: float = 0.2
## L'énergie de la lumière au début de l'effet.
@export_range(0.0, 100.0, 0.1) var light_energy: float = 2.0
#@ 23+
## Le flux coule encore autant après un `play`, en secondes.
@export_range(0.0, 2.0, 0.01) var stream_time: float = 0.2
#@ all

## Faux : sa lumière reste éteinte (qualité basse).
var light_allowed: bool = true
## Ce qu'il reste de l'éclat, de 1 (à l'instant) à 0 (éteint).
var flare: float = 0.0
#@ 23+
## La part de ses particules qui vivent (qualité graphique).
var detail: float = 1.0:
	set(value):
		detail = value
		for particles: GPUParticles3D in _particles:
			particles.amount_ratio = value
#@ all

var _particles: Array[GPUParticles3D] = []
var _length: float = 0.0
var _left: float = 0.0
#@ 23+
var _stream_left: float = 0.0

@onready var _stream: GPUParticles3D = get_node_or_null(^"Stream") as GPUParticles3D
#@ 19-22

#@ all
@onready var _glow: Node3D = get_node_or_null(^"Glow") as Node3D
@onready var _light: OmniLight3D = get_node_or_null(^"Light") as OmniLight3D


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	_length = duration
	for child: Node in get_children():
		if child is GPUParticles3D:
			var particles: GPUParticles3D = child as GPUParticles3D
#@ 19-22
			_particles.append(particles)
#@ all
			_length = maxf(_length, particles.lifetime)
#@ 23+
			if particles != _stream:
				_particles.append(particles)
#@ all
	_show()
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	update(delta)


## Rejoue l'effet depuis son début, même s'il n'avait pas fini.
func play() -> void:
	_left = _length
#@ 23+
	_stream_left = stream_time
#@ all
	flare = 1.0
	visible = true
	for particles: GPUParticles3D in _particles:
		particles.restart()
	_show()
	set_process(true)


## Fait passer `delta` secondes : la lueur et la lumière baissent ; quand ses particules ont fini de vivre, il se cache.
func update(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	flare = maxf(flare - delta / duration, 0.0)
#@ 23+
	_stream_left = maxf(_stream_left - delta, 0.0)
#@ all
	_show()
	if _left <= 0.0:
		visible = false
		set_process(false)


func _show() -> void:
#@ 23+
	if _stream != null:
		_stream.emitting = _stream_left > 0.0
#@ all
	if _glow != null:
		_glow.visible = flare > 0.0
		_glow.scale = Vector3.ONE * maxf(flare, 0.001)
	if _light != null:
		_light.visible = light_allowed and flare > 0.0
		_light.light_energy = light_energy * flare * flare
