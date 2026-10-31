class_name VfxBurst extends Node3D
## Un effet bref, préparé d'avance et rejoué sans rien créer. À chaque `play` : ses enfants GPUParticles3D repartent, et
## s'il en a, sa lueur (enfant Glow) et sa lumière (enfant Light) s'allument puis s'éteignent sur `duration`. Il se cache
## quand tout est fini : au repos, il ne coûte rien au rendu. C'est le contrôleur des effets de Binbun (CC0), typé, sans
## leur AnimationPlayer : le temps suit `update`, et les particules se relancent par `restart`, sans allocation.

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

## Faux : sa lumière reste éteinte (qualité basse).
var light_allowed: bool = true
## Ce qu'il reste de l'éclat, de 1 (à l'instant) à 0 (éteint).
var flare: float = 0.0

var _particles: Array[GPUParticles3D] = []
var _length: float = 0.0
var _left: float = 0.0

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
			_particles.append(particles)
			_length = maxf(_length, particles.lifetime)
	_show()
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	update(delta)


## Rejoue l'effet depuis son début, même s'il n'avait pas fini.
func play() -> void:
	_left = _length
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
	_show()
	if _left <= 0.0:
		visible = false
		set_process(false)


func _show() -> void:
	if _glow != null:
		_glow.visible = flare > 0.0
		_glow.scale = Vector3.ONE * maxf(flare, 0.001)
	if _light != null:
		_light.visible = light_allowed and flare > 0.0
		_light.light_energy = light_energy * flare * flare
