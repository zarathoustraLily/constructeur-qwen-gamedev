class_name PlayerCommands extends RefCounted
## Les commandes du joueur pour une image : ce qu'il demande, sans dire d'où cela vient (clavier et souris,
## manette, script de test). La logique du joueur ne lit que cela, jamais Input : un adaptateur d'entrées
## (<nom>_input.gd) remplit ces commandes à chaque image (règle ARC-04).
## Les directions sont celles de l'écran : x vers la droite, y vers le bas. C'est le joueur qui les tourne
## selon la caméra pour en faire des directions du monde.

## Déplacement demandé ; sa longueur va de 0 à 1 (un stick à moitié poussé donne une demi-longueur).
var move: Vector2 = Vector2.ZERO
## Visée demandée ; nulle quand le joueur ne vise pas (stick droit au repos) : il frappe alors vers où il marche.
var aim: Vector2 = Vector2.ZERO
## Coup demandé à cette image : la touche vient d'être enfoncée.
var attack: bool = false
## Esquive demandée à cette image.
var dash: bool = false
## Vrai quand la dernière entrée venait d'une manette.
var from_pad: bool = false
