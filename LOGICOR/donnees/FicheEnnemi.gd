class_name FicheEnnemi
extends Resource
## FicheEnnemi.gd
## Tous les nombres d'un ennemi Space Dracula (CRT-XXX).

# Identité
@export var id: String = ""
@export var nom: String = ""
@export var categorie: String = "ennemi"

# Stats de base
@export var PV_Max: int = 100
@export var Vitesse: float = 200.0
@export var NoteDifficulte: int = 50

# Poids dans la génération de salles
@export var PoidsPiscine: int = 1
@export var PoidsPlafondActif: int = 0

# Modificateurs
@export var ModificateurCassureEtourdissement: float = 1.0
@export var ModificateurEffetRalentissement: float = 1.0

# IA
@export var IA_PorteeAggro: float = 900.0
@export var IA_DelaiEveil: float = 0.0
@export var IA_DelaiSetupIA: float = 0.0
@export var IA_MaxAttaquants: int = 1
@export var IA_DistanceEntourer: float = 0.0
@export var IA_DistanceEntourerRiposte: float = 0.0
@export var IA_IntervalleRafraichissementEntourer: float = 0.0
@export var IA_FinSeuilPV: float = 0.0
@export var IA_TamponRecul: float = 0.0

# Arsenal (liste d'IDs d'attaques)
@export var arsenal: Array[String] = []
