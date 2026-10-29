class_name GolemDormantState extends State
## L'état Dormant du golem : il garde le comptoir sans bouger ; le héros qui s'approche à moins de `wake_distance` le
## réveille (Wake). Un tir le réveille aussi (le golem le voit à sa santé).

## Le golem piloté.
@export var golem: Golem


## Le héros assez près : il se réveille.
func physics_update(_delta: float) -> void:
	if golem.target != null and golem.distance_to_target() <= golem.settings.wake_distance:
		finish(&"Wake")
