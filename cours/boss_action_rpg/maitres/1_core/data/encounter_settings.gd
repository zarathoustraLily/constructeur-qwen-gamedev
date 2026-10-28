class_name EncounterSettings extends Resource
## Réglages de la rencontre avec le boss : ce qui se passe autour du combat, pas dans le combat.

## Après la chute du héros, le temps avant que le niveau recommence, en secondes : le joueur voit ce qui l'a tué.
@export_range(0.0, 10.0, 0.1) var restart_delay: float = 3.0
