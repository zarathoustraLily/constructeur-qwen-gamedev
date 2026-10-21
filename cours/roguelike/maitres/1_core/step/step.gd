class_name Step extends Node
## Le contrat commun à toutes les étapes du déroulé : cinématique, menu ou niveau. Une étape démarre (son
## _ready), tourne, puis appelle finish() ; elle ne charge jamais une autre scène : le chef d'orchestre
## (GameFlow, 0_autoload/game_flow.gd) écoute son signal et charge la suivante.

## Émis quand l'étape est finie, avec la suite voulue.
signal finished(outcome: StringName)


## Finit l'étape. `outcome` : &"done" (passer à la suite), &"retry" (rejouer l'étape), &"restart" (revenir au
## début du déroulé).
func finish(outcome: StringName = &"done") -> void:
	finished.emit(outcome)
