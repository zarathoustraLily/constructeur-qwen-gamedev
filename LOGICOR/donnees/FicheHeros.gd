class_name FicheHeros
extends Resource
## FicheHeros.gd
## Tous les nombres du héros.

@export var vie_max: int = 30
@export var souffle_max: int = 50
@export var vitesse: float = 300.0
@export var degat_attaque: int = 10
@export var degat_crit: int = 30
@export var portee_attaque: float = 150.0
@export var seuil_invuln: float = 0.25
@export var degat_min_invuln: int = 15
@export var fenetre_cumul: float = 0.6
@export var duree_invuln: float = 1.3
@export var dernier_effort_soin: float = 0.4
@export var dernier_effort_duree: float = 5.0
@export var dernier_effort_modif: float = 0.3
@export var mode_facile_base: float = 0.8
@export var mode_facile_mort: float = -0.02
@export var mode_facile_cap: int = 30
@export var cout_porte_secrete_base: float = 10.0
@export var cout_porte_secrete_ramp: float = 0.4
@export var seuil_combo: int = 12
@export var dash_duree: float = 0.4
@export var dash_vitesse: float = 800.0
@export var dash_cooldown: float = 1.0
@export var buffer_sprint: float = 0.42
