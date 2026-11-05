class_name RoomDocument
extends RefCounted
## La salle ouverte dans l'éditeur, et son historique. Toute modification passe par ici : elle s'applique à une copie
## de la salle, la copie est validée, et elle ne devient l'état courant (et un pas d'annulation) que si elle est valide.
## Une salle invalide ne peut donc jamais apparaître dans l'éditeur, ni être enregistrée.
## Les choses se désignent par leur identifiant stable ; les champs par leur nom court (`position`, `scale`…), que
## `COLUMNS` relie à la colonne de `RoomData`.

## Le contenu de la salle vient de changer (modification, annulation, ouverture).
signal changed
## La salle vient de devenir modifiée depuis le dernier enregistrement, ou de ne plus l'être.
signal dirty_changed(dirty: bool)

## Chaque champ modifiable, et la colonne de `RoomData` qui le range.
const COLUMNS: Dictionary[StringName, StringName] = {
	&"name": &"thing_names", &"asset": &"thing_assets", &"layer": &"thing_layers",
	&"position": &"thing_positions", &"rotation": &"thing_rotations", &"scale": &"thing_scales",
	&"parallax": &"thing_parallax", &"hsv": &"thing_hsv", &"color": &"thing_colors", &"active": &"thing_active",
	&"height": &"thing_heights", &"parent": &"thing_parents", &"sort": &"thing_sort",
}
## Le type attendu de chaque champ.
const TYPES: Dictionary[StringName, int] = {
	&"name": TYPE_STRING, &"asset": TYPE_STRING, &"layer": TYPE_STRING, &"position": TYPE_VECTOR3,
	&"rotation": TYPE_FLOAT, &"scale": TYPE_FLOAT, &"parallax": TYPE_FLOAT, &"hsv": TYPE_VECTOR3,
	&"color": TYPE_COLOR, &"active": TYPE_INT, &"height": TYPE_FLOAT, &"parent": TYPE_INT, &"sort": TYPE_INT,
}
## La valeur d'un champ qu'une nouvelle chose ne précise pas.
const DEFAULTS: Dictionary[StringName, Variant] = {
	&"name": "", &"position": Vector3.ZERO, &"rotation": 0.0, &"scale": 1.0, &"parallax": 1.0,
	&"hsv": Vector3.ZERO, &"color": Color.WHITE, &"active": 1, &"height": 0.0, &"parent": 0, &"sort": 0,
}
#@ 10+
## Les champs de la salle elle-même (et non de ses choses) que l'éditeur modifie, et leur type.
const ROOM_FIELDS: Dictionary[StringName, int] = {
	&"collisions": TYPE_ARRAY, &"hero_start": TYPE_VECTOR3, &"spawn_positions": TYPE_PACKED_VECTOR3_ARRAY,
	&"spawn_roles": TYPE_PACKED_STRING_ARRAY, &"encounter_pool": TYPE_PACKED_STRING_ARRAY,
	&"encounter_depth": TYPE_INT, &"effect_ids": TYPE_PACKED_STRING_ARRAY,
	&"effect_positions": TYPE_PACKED_VECTOR3_ARRAY,
}
#@ all

## Les erreurs de la dernière opération refusée, une phrase par erreur.
var errors: Array[String] = []
var _history: UndoStack = UndoStack.new()
var _room: RoomData
var _saved_revision: int = -1
var _notifying: bool = false


## Ouvre `room` : elle devient l'état courant, sans rien à annuler, et non modifiée. Refusée si elle est invalide.
func open(room: RoomData) -> bool:
	if _refuse_while_notifying():
		return false
	errors.clear()
	if room == null:
		errors.append("Aucune salle à ouvrir")
	else:
		errors.assign(room.validate())
	if not errors.is_empty():
		return false
	var was_dirty: bool = is_dirty()
	_history.reset(room)
	_room = _history.current()
	_saved_revision = _history.revision()
	_notify(was_dirty)
	return true


## Vrai si une salle est ouverte.
func is_open() -> bool:
	return _room != null


## Une copie de la salle courante (pour l'enregistrer), ou null.
func snapshot() -> RoomData:
	return null if _room == null else _room.duplicate(true) as RoomData


## Les identifiants des choses, dans l'ordre des colonnes.
func ids() -> PackedInt32Array:
	return PackedInt32Array() if _room == null else _room.thing_ids


## La colonne du champ `field` (un tableau compact, en lecture).
func column(field: StringName) -> Variant:
	return _room.get(COLUMNS[field])


## La valeur du champ `field` de la chose `thing_id`, ou null si elle n'existe pas.
func value(thing_id: int, field: StringName) -> Variant:
	var index: int = -1 if _room == null else _room.index_of(thing_id)
	return null if index < 0 or not COLUMNS.has(field) else column(field)[index]


## Les champs inconnus de la chose `thing_id` (un objet JSON en texte, vide s'il n'y en a pas).
func extras(thing_id: int) -> String:
	if _room == null or not _room.thing_extras.has(thing_id):
		return ""
	return _room.thing_extras[thing_id]


## Change le champ `field` de la chose `thing_id` : un pas d'annulation.
func set_value(thing_id: int, field: StringName, new_value: Variant) -> bool:
	return apply({thing_id: {field: new_value}})


## Applique d'un coup `changes` ({identifiant: {champ: valeur}}) : un seul pas d'annulation, ou rien si une valeur
## est refusée.
func apply(changes: Dictionary[int, Dictionary]) -> bool:
	if _refuse_while_notifying() or not _require_open():
		return false
	var candidate: RoomData = _room.duplicate(true) as RoomData
	for thing_id: int in changes:
		var index: int = candidate.index_of(thing_id)
		if index < 0:
			errors.assign(["chose %d introuvable" % thing_id])
			return false
		for raw_field: Variant in changes[thing_id]:
			var field: StringName = StringName(raw_field)
			var converted: Variant = _converted(field, changes[thing_id][raw_field])
			if not errors.is_empty():
				return false
			var values: Variant = candidate.get(COLUMNS[field])
			values[index] = converted
			candidate.set(COLUMNS[field], values)
	return _commit(candidate)


#@ 3-4
## Ajoute une chose de champs `fields` (au moins `asset` et `layer`) ; rend son identifiant, ou 0 si elle est refusée.
func add_thing(fields: Dictionary[StringName, Variant]) -> int:
	if _refuse_while_notifying() or not _require_open():
		return 0
	var candidate: RoomData = _room.duplicate(true) as RoomData
	var new_id: int = 1
	for thing_id: int in candidate.thing_ids:
		new_id = maxi(new_id, thing_id + 1)
	var ids_column: PackedInt32Array = candidate.thing_ids
	ids_column.append(new_id)
	candidate.thing_ids = ids_column
	for field: StringName in COLUMNS:
		if not fields.has(field) and not DEFAULTS.has(field):
			errors.assign(["%s : champ requis pour une nouvelle chose" % field])
			return 0
		var converted: Variant = _converted(field, fields.get(field, DEFAULTS.get(field)))
		if not errors.is_empty():
			return 0
		var values: Variant = candidate.get(COLUMNS[field])
		values.append(converted)
		candidate.set(COLUMNS[field], values)
	return new_id if _commit(candidate) else 0
#@ 5+
## Ajoute une chose de champs `fields` (au moins `asset` et `layer`) ; rend son identifiant, ou 0 si elle est refusée.
func add_thing(fields: Dictionary[StringName, Variant]) -> int:
	var created: Array[int] = add_things([fields])
	return 0 if created.is_empty() else created[0]


## Ajoute d'un coup les choses `list` (chacune un dictionnaire de champs, au moins `asset` et `layer`) : un seul pas
## d'annulation. Rend leurs identifiants, dans l'ordre, ou une liste vide si l'une d'elles est refusée.
func add_things(list: Array[Dictionary]) -> Array[int]:
	var created: Array[int] = []
	if _refuse_while_notifying() or not _require_open():
		return created
	var candidate: RoomData = _room.duplicate(true) as RoomData
	var next_id: int = 1
	for thing_id: int in candidate.thing_ids:
		next_id = maxi(next_id, thing_id + 1)
	for fields: Dictionary in list:
		var ids_column: PackedInt32Array = candidate.thing_ids
		ids_column.append(next_id)
		candidate.thing_ids = ids_column
		for field: StringName in COLUMNS:
			if not fields.has(field) and not DEFAULTS.has(field):
				errors.assign(["%s : champ requis pour une nouvelle chose" % field])
				return []
			var converted: Variant = _converted(field, fields.get(field, DEFAULTS.get(field)))
			if not errors.is_empty():
				return []
			var values: Variant = candidate.get(COLUMNS[field])
			values.append(converted)
			candidate.set(COLUMNS[field], values)
		created.append(next_id)
		next_id += 1
	return created if _commit(candidate) else []
#@ all


## Supprime les choses `thing_ids` : un pas d'annulation. Refusé si une chose qui reste est attachée à l'une d'elles.
func remove_things(thing_ids: Array[int]) -> bool:
	if _refuse_while_notifying() or not _require_open():
		return false
	var indices: Array[int] = []
	for thing_id: int in thing_ids:
		var index: int = _room.index_of(thing_id)
		if index < 0:
			errors.assign(["chose %d introuvable" % thing_id])
			return false
		indices.append(index)
	for index: int in _room.thing_count():
		var parent: int = _room.thing_parents[index]
		if parent != 0 and thing_ids.has(parent) and not thing_ids.has(_room.thing_ids[index]):
			errors.assign(["Suppression refusée : la chose %d est attachée à la chose %d" % [_room.thing_ids[index],
					parent]])
			return false
	indices.sort()
	indices.reverse()
	var candidate: RoomData = _room.duplicate(true) as RoomData
	for column_name: StringName in [&"thing_ids"] + COLUMNS.values():
		var values: Variant = candidate.get(column_name)
		for index: int in indices:
			values.remove_at(index)
		candidate.set(column_name, values)
	for thing_id: int in thing_ids:
		candidate.thing_extras.erase(thing_id)
	return _commit(candidate)


#@ 10+
## Une copie du champ `field` de la salle (`ROOM_FIELDS` : collisions, apparitions, rencontre, effets), ou null.
func room_value(field: StringName) -> Variant:
	if _room == null or not ROOM_FIELDS.has(field):
		return null
	var raw: Variant = _room.get(field)
	return raw.duplicate() if raw is Array else raw


## Change d'un coup les champs de la salle `changes` ({champ: valeur}) : un seul pas d'annulation, ou rien si une valeur
## est refusée.
func set_room_fields(changes: Dictionary[StringName, Variant]) -> bool:
	if _refuse_while_notifying() or not _require_open():
		return false
	var candidate: RoomData = _room.duplicate(true) as RoomData
	for field: StringName in changes:
		if not ROOM_FIELDS.has(field):
			errors.assign(["%s : champ de salle inconnu ou non modifiable" % field])
			return false
		var new_value: Variant = changes[field]
		if typeof(new_value) != ROOM_FIELDS[field]:
			errors.assign(["%s : %s attendu" % [field, type_string(ROOM_FIELDS[field])]])
			return false
		if field == &"collisions":
			# Une propriété typée (Array[PackedVector2Array]) se remplit par assign : un tableau sans type lui serait
			# refusé.
			var polygons: Array[PackedVector2Array] = []
			polygons.assign(new_value)
			candidate.collisions = polygons
		else:
			candidate.set(field, new_value)
	return _commit(candidate)


#@ all
## Vrai s'il y a un pas à annuler.
func can_undo() -> bool:
	return _history.can_undo()


## Vrai s'il y a un pas annulé à refaire.
func can_redo() -> bool:
	return _history.can_redo()


## Annule le dernier pas.
func undo() -> bool:
	if _refuse_while_notifying() or not can_undo():
		return false
	var was_dirty: bool = is_dirty()
	_room = _history.undo()
	_notify(was_dirty)
	return true


## Refait le pas annulé.
func redo() -> bool:
	if _refuse_while_notifying() or not can_redo():
		return false
	var was_dirty: bool = is_dirty()
	_room = _history.redo()
	_notify(was_dirty)
	return true


## Vrai si la salle a changé depuis son ouverture ou son dernier enregistrement.
func is_dirty() -> bool:
	return _room != null and _history.revision() != _saved_revision


## Note que l'état courant vient d'être enregistré.
func mark_saved() -> void:
	if _room == null or _notifying:
		return
	var was_dirty: bool = is_dirty()
	_saved_revision = _history.revision()
	if was_dirty:
		dirty_changed.emit(false)


func _converted(field: StringName, raw: Variant) -> Variant:
	errors.clear()
	if not COLUMNS.has(field):
		errors.append("%s : champ inconnu ou non modifiable" % field)
		return null
	var expected: int = TYPES[field]
	if expected == TYPE_FLOAT and raw is int:
		return float(raw)
	if expected == TYPE_INT and raw is bool:
		return 1 if raw else 0
	if typeof(raw) != expected:
		errors.append("%s : %s attendu" % [field, type_string(expected)])
		return null
	return raw


func _commit(candidate: RoomData) -> bool:
	errors.assign(candidate.validate())
	if not errors.is_empty():
		return false
	var was_dirty: bool = is_dirty()
	_history.push(candidate)
	_room = candidate
	_notify(was_dirty)
	return true


func _require_open() -> bool:
	errors.clear()
	if _room == null:
		errors.append("Aucune salle ouverte")
	return _room != null


# Un abonné à `changed` qui modifierait la salle pendant la notification en créerait une autre au milieu de la
# première : on refuse, et l'abonné le voit dans `errors`.
func _refuse_while_notifying() -> bool:
	if _notifying:
		errors.assign(["Modification refusée pendant une notification"])
	return _notifying


func _notify(was_dirty: bool) -> void:
	_notifying = true
	changed.emit()
	if was_dirty != is_dirty():
		dirty_changed.emit(is_dirty())
	_notifying = false
