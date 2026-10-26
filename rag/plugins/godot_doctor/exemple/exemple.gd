extends Node
## Exemple minimal de Godot Doctor (2.2.0, GDScript) : un ennemi déclare ses conditions de validité
## (_get_validation_conditions) ; mal réglé (santé à 0, sans cible), il est signalé avant même de jouer.


## Un ennemi mal réglé : santé nulle et cible non assignée.
class Ennemi extends Node:
	@export var sante: int = 0
	@export var cible: Node3D

	func _get_validation_conditions() -> Array[ValidationCondition]:
		return [
			ValidationCondition.simple(sante > 0, "La santé doit être positive"),
			ValidationCondition.is_instance_valid(cible, "cible"),
		]


func _ready() -> void:
	var ennemi := Ennemi.new()
	# Dans l'éditeur, le plugin évalue ces conditions à l'enregistrement de la scène ; ici on les évalue directement.
	var messages := GodotDoctorValidator.evaluate_conditions(ennemi._get_validation_conditions())
	var textes: PackedStringArray = []
	for m: GodotDoctorValidationMessage in messages:
		textes.append(m.message)
	ennemi.free()
	if textes == PackedStringArray(["La santé doit être positive", "cible is not a valid instance."]):
		print("EXEMPLE VERIFIE : %d problèmes signalés : %s" % [textes.size(), " ; ".join(textes)])
	else:
		push_error("messages : %s" % textes)
	get_tree().quit()
