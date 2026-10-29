class_name GolemRecoverState extends State
## L'état Recover du golem : après son coup, il reprend son souffle pendant le temps de récupération de l'attaque ; il
## ne se tourne pas : c'est la fenêtre pour le punir, de dos surtout. Puis il revient vers le héros (Approach), ou
## passe à la seconde phase si elle est due (PhaseShift).

## Le golem piloté.
@export var golem: Golem

## Le temps écoulé, en secondes.
var elapsed: float = 0.0


## La récupération commence : la série de coups enchaînés est finie.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	golem.chained = 0


## Il attend la fin de sa récupération.
func physics_update(delta: float) -> void:
	elapsed += delta
	if elapsed >= golem.attack.recover:
		finish(&"PhaseShift" if golem.phase_two_due else &"Approach")
