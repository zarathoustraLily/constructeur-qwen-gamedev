class_name FicheArme
extends Resource
## FicheArme.gd
## Tous les nombres d'une arme Space Dracula (REL-XXX).

# Identité
@export var id: String = ""
@export var nom: String = ""
@export var categorie: String = "arme"
@export var numero: int = 0

# Props (dictionnaire libre pour les buffs/passifs)
@export var props: Dictionary = {}
