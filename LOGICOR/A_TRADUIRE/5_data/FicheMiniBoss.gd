class_name FicheMiniBoss
extends Resource
## FicheMiniBoss.gd
## Tous les nombres d'un mini-boss Space Dracula (MIN-XXX).

# Identité
@export var id: String = ""
@export var nom: String = ""
@export var categorie: String = "mini-boss"

# Stats de base
@export var PV_Max: int = 2000
@export var Vitesse: float = 400.0
@export var NoteDifficulte: int = 0
@export var TamponPV: int = 0

# IA
@export var IA_PorteeAggro: float = 0.0
@export var IA_DelaiEveil: float = 0.0
@export var IA_DelaiSetupIA: float = 0.0
@export var IA_MaxAttaquants: int = 0
@export var IA_DistanceEntourer: float = 0.0
@export var IA_IntervalleRafraichissementEntourer: float = 0.0
@export var IA_FinSeuilPV: float = 0.0

# Phases (liste de dictionnaires)
@export var phases: Array[Dictionary] = []

# Attaques (liste de dictionnaires)
@export var attaques: Array[Dictionary] = []

# Props bruts (tout le reste)
@export var props: Dictionary = {}
