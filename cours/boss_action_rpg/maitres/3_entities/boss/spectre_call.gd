class_name SpectreCall extends Node
## L'appel des spectres par le Gardien : quand sa vie passe sous `summon_ratio`, les spectres préparés (créés avec le
## niveau, jamais en combat) sortent un par un, à `stagger` secondes d'écart, chacun à sa place sur le cercle autour
## du héros. Une seule fois par combat.

## Le Gardien a appelé ses spectres.
signal called

## Le seuil et l'écart entre deux sorties.
@export var settings: SpectreSettings
## La santé du Gardien.
@export var health: HealthComponent
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

var _clock: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.ACTORS
	health.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	tick(delta)


## Fait passer `delta` secondes : chaque spectre sort à son heure (le premier tout de suite).
func tick(delta: float) -> void:
	if not has_called:
		return
	_clock += delta
	while sent < spectres.size() and _clock >= sent * settings.stagger:
		spectres[sent].activate(prey, TAU * sent / spectres.size(), prey_health)
		sent += 1


func _on_damaged(_amount: float, remaining: float) -> void:
	if not has_called and remaining <= health.settings.max_health * settings.summon_ratio:
		has_called = true
		called.emit()
		tick(0.0)
