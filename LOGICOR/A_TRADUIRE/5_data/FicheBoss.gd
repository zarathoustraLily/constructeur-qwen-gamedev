class_name FicheBoss
extends Resource
## FicheBoss.gd
## Tous les nombres d'un boss Space Dracula (ANO-XXX).

# Identité
@export var id: String = ""
@export var nom: String = ""
@export var categorie: String = "boss"

# Stats de base
@export var PV_Max: int = 5000
@export var Vitesse: float = 500.0
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
# Chaque phase: { "id": String, "props": { "TypeTransition": String, "Seuil": float, ... } }
@export var phases: Array[Dictionary] = []

# Attaques (liste de dictionnaires)
# Chaque attaque: { "id": String, "props": { "IA.AnnonceDuree": float, ... } }
@export var attaques: Array[Dictionary] = []
