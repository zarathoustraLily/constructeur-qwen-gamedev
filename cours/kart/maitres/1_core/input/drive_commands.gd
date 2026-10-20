class_name DriveCommands extends RefCounted
## Les commandes de conduite d'une image : ce que le pilote demande, sans dire d'où cela vient (clavier,
## manette, script de test). La logique du véhicule ne lit que cela, jamais Input : un adaptateur
## d'entrées (<nom>_input.gd) remplit ces commandes à chaque image (règle ARC-04).

## Accélération demandée, de -1 (marche arrière) à 1 (plein gaz) ; une gâchette donne une valeur entre les deux.
var throttle: float = 0.0
## Braquage demandé, de -1 (à gauche) à 1 (à droite).
var steering: float = 0.0
## Frein demandé.
var brake: bool = false
## Saut demandé à cette image : la touche vient d'être enfoncée.
var jump: bool = false
## Touche de saut tenue.
var jump_held: bool = false
## Touche de saut relâchée à cette image.
var jump_released: bool = false
