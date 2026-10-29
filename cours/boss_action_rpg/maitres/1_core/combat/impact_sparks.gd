class_name ImpactSparks extends Node3D
## Les étincelles des tirs : chaque impact d'un projectile de la réserve (signal `impacted`) fait jaillir une salve au
## point touché. Les salves sont préparées d'avance (ses enfants GPUParticles3D) et relancées à tour de rôle : aucune
## n'est créée en combat.

## La réserve dont il montre les impacts.
@export var pool: ProjectilePool

## La prochaine salve relancée.
var next: int = 0

var _bursts: Array[GPUParticles3D] = []


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	for child: Node in get_children():
		if child is GPUParticles3D:
			_bursts.append(child as GPUParticles3D)
	pool.impacted.connect(play)


## Une salve en `point`, juste devant la surface touchée (normale `normal`).
func play(point: Vector3, normal: Vector3, _dealt: float) -> void:
	var burst: GPUParticles3D = _bursts[next]
	next = (next + 1) % _bursts.size()
	burst.global_position = point + normal * 0.05
	burst.restart()
