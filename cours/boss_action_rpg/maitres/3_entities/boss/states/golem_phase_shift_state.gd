class_name GolemPhaseShiftState extends State
## L'état PhaseShift du golem : la seconde phase commence (son bouclier ne bloque plus, ses spectres sortent : signal
## `phase_changed`) ; il rugit et jette son bouclier pendant `phase_shift_time`, puis revient vers le héros (Approach).

## Le golem piloté.
@export var golem: Golem

## Le temps écoulé, en secondes.
var elapsed: float = 0.0


## La seconde phase commence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	golem.chained = 0
	golem.enter_phase_two()


## Il rugit, puis reprend le combat.
func physics_update(delta: float) -> void:
	elapsed += delta
	if elapsed >= golem.settings.phase_shift_time:
		finish(&"Approach")
