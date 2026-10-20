class_name FicheSalle
extends Resource
## FicheSalle.gd
## Fiche d'un niveau : profil de rencontre + pool d'ennemis.

@export var id: String = ""
@export var nom: String = ""
@export var niveau: int = 1
@export var profil_nom: String = ""

# Profil de rencontre (clés françaises)
@export var difficulte_de_base: int = 30
@export var ramp_difficulte_par_profondeur: int = 10
@export var plafond_ennemis_de_base: float = 2.3
@export var ramp_plafond_par_profondeur: float = 0.35
@export var plafond_ennemis_max: int = 8
@export var types_min: int = 1
@export var types_max: int = 2
@export var plafond_types: int = 4
@export var ramp_types_par_profondeur: float = 0.2
@export var elite_types_max: int = 0
@export var vagues_min: int = 1
@export var vagues_max: int = 3
@export var intervalle_spawn_min: float = 0.175
@export var intervalle_spawn_max: float = 0.225

# Pool d'ennemis : [{ref, poids, elite}, ...]
@export var pool: Array = []
@export var total_poids: int = 0
@export var nb_types: int = 0
