class_name GolemWakeState extends State
## L'état Wake du golem : il se dresse et se tourne vers le héros pendant `wake_time`, puis s'approche (Approach). Il
## annonce son réveil (signal `woke` : la jauge du boss apparaît).

## Le golem piloté.
@export var golem: Golem

## Le temps écoulé depuis le réveil, en secondes.
var elapsed: float = 0.0


## Il se réveille et le dit.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	golem.wake_up()


## Il fait face ; réveillé, il s'approche.
func physics_update(delta: float) -> void:
	elapsed += delta
	golem.face_target(delta)
	if elapsed >= golem.settings.wake_time:
		finish(&"Approach")
