class_name Step
extends Node
## Le contrat commun à toutes les étapes du déroulé : cinématique, menu ou niveau.
## Une étape démarre (son _ready), tourne, puis appelle finish() ; GameFlow passe à la suivante.

signal finished(outcome: StringName)


## outcome : &"done" (passer à la suite), &"retry" (rejouer l'étape), &"restart" (revenir au début).
func finish(outcome: StringName = &"done") -> void:
	finished.emit(outcome)
