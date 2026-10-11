class_name ProcessOrder
extends Object
## L'ordre d'exécution du gameplay (SIM-02) : chaque système prend sa priorité ici, jamais un
## nombre écrit sur place. Godot traite d'abord la plus petite valeur, puis l'ordre de l'arbre.
##   process_physics_priority = ProcessOrder.MOVEMENT

## Collecte des commandes du joueur (scripts *_input.gd).
const INPUT := -30
## Décisions de l'IA et déplacements (machines à états, projectiles).
const MOVEMENT := -10
## Tirs et attaques.
const ATTACK := 0
## Application des dégâts, invincibilités.
const DAMAGE := 10
