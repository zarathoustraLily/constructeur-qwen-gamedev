class_name ImpactSparks extends Node3D
#@ 13-18
## Les étincelles des tirs : chaque impact d'un projectile de la réserve (signal `impacted`) fait jaillir une salve au
## point touché. Les salves sont préparées d'avance (ses enfants GPUParticles3D) et relancées à tour de rôle : aucune
## n'est créée en combat.
#@ 19+
## Les impacts des tirs : chaque impact d'un projectile de la réserve (signal `impacted`) fait jaillir une salve au
## point touché, tournée selon la surface, et allume la lumière des impacts à cet endroit. Les salves sont préparées
## d'avance (ses enfants VfxBurst) et relancées à tour de rôle ; une seule lumière (son enfant Flare) sert tous les
## impacts, à la place du dernier : une lumière par salve coûterait au rendu sans se voir de plus.

## La lumière se tient autant devant la surface touchée, en mètres : posée dessus, elle l'éclairerait à peine.
const FLARE_LIFT: float = 0.8
#@ all

## La réserve dont il montre les impacts.
@export var pool: ProjectilePool

## La prochaine salve relancée.
var next: int = 0

#@ 13-18
var _bursts: Array[GPUParticles3D] = []
#@ 19+
var _bursts: Array[VfxBurst] = []

@onready var _flare: VfxBurst = $Flare
#@ all


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	for child: Node in get_children():
#@ 13-18
		if child is GPUParticles3D:
			_bursts.append(child as GPUParticles3D)
#@ 19+
		if child is VfxBurst and child != _flare:
			_bursts.append(child as VfxBurst)
#@ all
	pool.impacted.connect(play)


## Une salve en `point`, juste devant la surface touchée (normale `normal`).
func play(point: Vector3, normal: Vector3, _dealt: float) -> void:
#@ 13-18
	var burst: GPUParticles3D = _bursts[next]
	next = (next + 1) % _bursts.size()
	burst.global_position = point + normal * 0.05
	burst.restart()
#@ 19+
	var burst: VfxBurst = _bursts[next]
	next = (next + 1) % _bursts.size()
	burst.global_position = point + normal * 0.05
	burst.global_basis = Basis(Quaternion(Vector3.UP, normal))
	burst.play()
	_flare.global_position = point + normal * FLARE_LIFT
	_flare.play()
#@ all
