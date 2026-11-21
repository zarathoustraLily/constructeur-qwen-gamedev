extends Control
## Un écran témoin pour les tests de la coquille : il ne montre rien et finit quand on le lui demande.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)


## Finit l'écran, en nommant le suivant.
func finish(next: StringName) -> void:
	finished.emit(next)
