class_name FL_Enemy
extends Resource
## FL_Enemy.gd
## La fiche d'un ennemi (Resource).

@export var nom: String = ""
@export var vie_max: int = 100
@export var vitesse: float = 200.0
@export var portee: float = 120.0
@export var outils: Array = []
@export var stades: Array = []
@export var difficulte: int = 50
