class_name JsonValues extends RefCounted
## Les valeurs lues dans un JSON, typées : un objet devient un Dictionary[String, Variant], une liste un
## Array[Variant]. Une valeur d'une autre sorte donne un objet ou une liste vides : quand l'absence est une erreur,
## qui lit vérifie la sorte avant (is_object, is_list, is_number).


## Vrai si `value` est un objet JSON.
static func is_object(value: Variant) -> bool:
	return typeof(value) == TYPE_DICTIONARY


## Vrai si `value` est une liste JSON.
static func is_list(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY


## Vrai si `value` est un nombre (JSON lit 3 comme un flottant, un test peut donner un entier).
static func is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT


## L'objet `value`, typé ; vide si ce n'est pas un objet.
static func object(value: Variant) -> Dictionary[String, Variant]:
	var typed: Dictionary[String, Variant] = {}
	if is_object(value):
		typed.assign(value as Dictionary)
	return typed


## La liste `value`, typée ; vide si ce n'est pas une liste.
static func list(value: Variant) -> Array[Variant]:
	var typed: Array[Variant] = []
	if is_list(value):
		typed.assign(value as Array)
	return typed
