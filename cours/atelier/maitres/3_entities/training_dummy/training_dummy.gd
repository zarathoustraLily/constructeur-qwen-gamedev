class_name TrainingDummy extends Node3D
## Un mannequin d'entraînement : il encaisse les coups, reste étourdi un instant (Hit), puis revient au repos (Idle) ;
## à zéro point de vie, il tombe (Defeated) et ne réagit plus. Sa santé et sa machine à états sont ses enfants ; il
## relie l'une à l'autre. Sa vue (training_dummy_view.gd) montre son état sans le décider.

## Sa santé.
@onready var health: HealthComponent = $HealthComponent
## Ses états : Idle, Hit, Defeated.
@onready var machine: StateMachine = $StateMachine


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


## Un coup de `amount` points ; rend ce qui a vraiment été retiré (rien pendant le répit ni une fois vaincu).
func hit(amount: float) -> float:
	return health.take_damage(amount)


## Le nom de l'état actif : Idle, Hit ou Defeated.
func state() -> StringName:
	return machine.current.name


func _on_damaged(_amount: float, remaining: float) -> void:
	if remaining > 0.0:
		# Un nouveau coup pendant Hit relance l'étourdissement : on ressort pour rentrer.
		if state() == &"Hit":
			machine.transition_to(&"Idle")
		machine.transition_to(&"Hit")


func _on_died() -> void:
	machine.transition_to(&"Defeated")
