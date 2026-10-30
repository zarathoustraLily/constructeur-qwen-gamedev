class_name SpectreCall extends Node
#@ 11
## L'appel des spectres par le Gardien : quand sa vie passe sous `summon_ratio` (il en a perdu 30 %), les spectres
## préparés (créés avec le niveau, jamais en combat) sortent un par un, à `stagger` secondes d'écart, chacun à sa
## place sur le cercle autour du héros. Une seule fois par combat.
#@ 12+
## L'appel des spectres par le Gardien : quand sa seconde phase commence (il a perdu 30 % de sa vie), les spectres
## préparés (créés avec le niveau, jamais en combat) sortent un par un, à `stagger` secondes d'écart, chacun à sa
## place sur le cercle autour du héros. Une seule fois par combat.
#@ 17+
## Il leur donne aussi le tour de plonger : un seul spectre à la fois, un écart entre deux plongées, et jamais pendant
## un coup du Gardien.
#@ all

## Le Gardien a appelé ses spectres.
signal called

#@ 11
## Le seuil et l'écart entre deux sorties.
@export var settings: SpectreSettings
## La santé du Gardien.
@export var health: HealthComponent
#@ 12+
## L'écart entre deux sorties.
@export var settings: SpectreSettings
## Le Gardien : ses spectres sortent quand sa seconde phase commence.
@export var golem: Golem
#@ all
## Les spectres préparés.
@export var spectres: Array[Spectre] = []
## Ce qu'ils chassent (le héros).
@export var prey: Node3D
## Sa santé : abattu, ils ne plongent plus sur lui.
@export var prey_health: HealthComponent

## Vrai une fois l'appel lancé.
var has_called: bool = false
## Combien de spectres sont déjà sortis.
var sent: int = 0
#@ 17+
## Le spectre qui a le tour de plonger (aucun : le tour est libre).
var diver: Spectre
#@ all

var _clock: float = 0.0
#@ 17+
var _free_at: float = 0.0
#@ all


func _ready() -> void:
	process_physics_priority = ProcessOrder.ACTORS
#@ 11
	health.damaged.connect(_on_damaged)
#@ 12+
	golem.phase_changed.connect(_on_phase_changed)
#@ all


func _physics_process(delta: float) -> void:
	tick(delta)


## Fait passer `delta` secondes : chaque spectre sort à son heure (le premier tout de suite).
func tick(delta: float) -> void:
	if not has_called:
		return
	_clock += delta
#@ 17+
	# Le spectre qui avait le tour a fini sa plongée (ou s'est dissipé) : le tour se libère après l'écart.
	if diver != null and not diver.is_diving():
		diver = null
		_free_at = _clock + settings.dive_gap
#@ all
	while sent < spectres.size() and _clock >= sent * settings.stagger:
#@ 17+
		spectres[sent].pack = self
#@ all
		spectres[sent].activate(prey, TAU * sent / spectres.size(), prey_health)
		sent += 1


#@ 11
func _on_damaged(_amount: float, remaining: float) -> void:
	if not has_called and remaining <= health.settings.max_health * settings.summon_ratio:
		has_called = true
		called.emit()
		tick(0.0)
#@ 12+
func _on_phase_changed(new_phase: int) -> void:
	if new_phase == 2 and not has_called:
		has_called = true
		called.emit()
		tick(0.0)
#@ all
#@ 17+


## Donne à `spectre` le tour de plonger et rend vrai, si le tour est libre, si l'écart depuis la dernière plongée est
## passé et si le Gardien ne frappe pas.
func claim_dive(spectre: Spectre) -> bool:
	if diver != null or _clock < _free_at or golem.machine.current is GolemAttackState:
		return false
	diver = spectre
	return true
#@ all
