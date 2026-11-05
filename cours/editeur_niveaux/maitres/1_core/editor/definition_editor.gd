class_name DefinitionEditor
extends RefCounted
## L'édition d'une définition du jeu (un ennemi, un effet…), quelle que soit sa classe : ses champs sont les variables
## exportées de son script (`PROPERTY_USAGE_SCRIPT_VARIABLE` et `PROPERTY_USAGE_EDITOR`), sauf `id`, qui ne se renomme
## jamais. On modifie une copie privée ; on n'écrit le fichier que si la définition est valide (`validate()`), par
## l'enregistreur stable. Après l'écriture, la ressource que le reste du projet a déjà chargée reçoit les nouvelles
## valeurs (`CACHE_MODE_REPLACE`) : écrire le fichier ne suffit pas à changer ce qui est déjà en mémoire.

## Les erreurs de la dernière opération refusée, une phrase par erreur.
var errors: Array[String] = []
var _path: String = ""
var _definition: Resource
var _history: Array[Resource] = []
var _saver: StableSaver = StableSaver.new()


## Ouvre la définition `path` (une copie privée) ; rend false si elle ne se charge pas.
func open(path: String) -> bool:
	errors.clear()
	_definition = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if _definition == null or not _definition.has_method(&"validate"):
		errors.append("Pas une définition : " + path)
		_definition = null
		return false
	_path = path
	_history.clear()
	return true


## Vrai si une définition est ouverte.
func is_open() -> bool:
	return _definition != null


## Les champs modifiables de la définition : pour chacun, son nom et son type (`name`, `type`).
func fields() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _definition == null:
		return result
	var wanted: int = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR
	for property: Variant in _definition.get_property_list():
		if int(property["usage"]) & wanted == wanted and property["name"] != "id":
			result.append({&"name": StringName(property["name"]), &"type": int(property["type"])})
	return result


## La valeur du champ `field`.
func value(field: StringName) -> Variant:
	return null if _definition == null else _definition.get(field)


## L'identifiant de la définition ouverte.
func id() -> StringName:
	return &"" if _definition == null else StringName(_definition.get(&"id"))


## Donne la valeur `new_value` au champ `field` ; refusé si le champ n'est pas modifiable ou si le type ne va pas (un
## entier vaut pour un nombre à virgule).
func set_value(field: StringName, new_value: Variant) -> bool:
	errors.clear()
	var expected: int = -1
	for entry: Variant in fields():
		if entry[&"name"] == field:
			expected = entry[&"type"]
	if expected < 0:
		errors.append("%s : champ inconnu ou non modifiable" % field)
		return false
	var converted: Variant = new_value
	if expected == TYPE_FLOAT and new_value is int:
		converted = float(new_value)
	elif expected == TYPE_STRING_NAME and new_value is String:
		converted = StringName(new_value)
	if typeof(converted) != expected:
		errors.append("%s : %s attendu" % [field, type_string(expected)])
		return false
	_history.append(_definition.duplicate())
	_definition.set(field, converted)
	return true


## Vrai s'il y a une modification à annuler.
func can_undo() -> bool:
	return not _history.is_empty()


## Annule la dernière modification.
func undo() -> bool:
	if _history.is_empty():
		return false
	_definition = _history.pop_back()
	return true


## Les erreurs de la définition telle qu'elle est (`validate()`).
func validation_errors() -> Array[String]:
	var result: Array[String] = []
	if _definition != null:
		result.assign(_definition.call(&"validate"))
	return result


## Enregistre la définition si elle est valide, puis met à jour la ressource déjà chargée par le projet.
func save() -> bool:
	errors.assign(validation_errors())
	if _definition == null:
		errors.append("Aucune définition ouverte")
	if not errors.is_empty():
		return false
	var status: Error = _saver.save(_definition, _path)
	if status != OK:
		errors.append("Écriture impossible (%s) : %s" % [error_string(status), _path])
		return false
	ResourceLoader.load(_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	_history.clear()
	return true
