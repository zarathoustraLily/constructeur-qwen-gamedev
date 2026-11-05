class_name EditorActions
extends RefCounted
## Les gestes de l'éditeur, sur un groupe de choses (en général, la sélection). Chaque geste calcule les nouvelles valeurs
## de toutes les choses concernées, puis les confie d'un coup au document : un seul pas d'annulation par geste, et rien
## ne change si une seule valeur est refusée.
## Un groupe tourne et s'agrandit autour de son centre, comme dans un logiciel de dessin : les positions tournent ou
## s'écartent, en plus de la rotation ou de l'échelle de chaque chose.

## Les erreurs du dernier geste refusé, une phrase par erreur.
var errors: Array[String] = []
var _document: RoomDocument
var _catalog: AssetCatalogDef
var _settings: EditorSettingsDef


## Branche les gestes sur `document`, avec le catalogue (pour ajouter un asset) et les réglages (grille, bornes).
func setup(document: RoomDocument, catalog: AssetCatalogDef, settings: EditorSettingsDef) -> void:
	_document = document
	_catalog = catalog
	_settings = settings


## `position` aimantée à la grille, en x et en z.
func snapped_position(position: Vector3) -> Vector3:
	return Vector3(snappedf(position.x, _settings.snap_m), position.y, snappedf(position.z, _settings.snap_m))


## Le centre des positions des choses `ids`, en mètres.
func center_of(ids: Array[int]) -> Vector3:
	var sum: Vector3 = Vector3.ZERO
	for thing_id: int in ids:
		sum += _position(thing_id)
	return sum / maxf(ids.size(), 1.0)


## Déplace les choses `ids` de `delta` ; aimantées à la grille si `snap`.
func move(ids: Array[int], delta: Vector3, snap: bool = false) -> bool:
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		var target: Vector3 = _position(thing_id) + delta
		changes[thing_id] = {&"position": snapped_position(target) if snap else target}
	return _apply(changes)


## Tourne les choses `ids` de `delta_deg` degrés ; un groupe tourne aussi autour de son centre. Aimanté au pas de
## rotation si `snap`.
func rotate(ids: Array[int], delta_deg: float, snap: bool = false) -> bool:
	var pivot: Vector3 = center_of(ids)
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		var angle: float = _float(thing_id, &"rotation") + delta_deg
		if snap:
			angle = snappedf(angle, _settings.rotation_step_deg)
		var fields: Dictionary[StringName, Variant] = {&"rotation": fposmod(angle, RoomData.FULL_TURN)}
		if ids.size() > 1:
			var offset: Vector2 = Vector2(_position(thing_id).x - pivot.x, _position(thing_id).z - pivot.z)
			offset = offset.rotated(deg_to_rad(delta_deg))
			fields[&"position"] = Vector3(pivot.x + offset.x, _position(thing_id).y, pivot.z + offset.y)
		changes[thing_id] = fields
	return _apply(changes)


## Multiplie l'échelle des choses `ids` par `factor`, dans les bornes des réglages ; un groupe s'écarte aussi de son
## centre.
func scale_by(ids: Array[int], factor: float) -> bool:
	var pivot: Vector3 = center_of(ids)
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		var fields: Dictionary[StringName, Variant] = {
			&"scale": clampf(_float(thing_id, &"scale") * factor, _settings.min_scale, _settings.max_scale)}
		if ids.size() > 1:
			var spread: Vector3 = (_position(thing_id) - pivot) * factor
			fields[&"position"] = Vector3(pivot.x + spread.x, _position(thing_id).y, pivot.z + spread.z)
		changes[thing_id] = fields
	return _apply(changes)


## Donne à toutes les choses `ids` la valeur `new_value` du champ `field` (teinte, parallaxe, actif, couleur…).
func set_field(ids: Array[int], field: StringName, new_value: Variant) -> bool:
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		changes[thing_id] = {field: new_value}
	return _apply(changes)


## Range les choses `ids` dans le calque `layer`.
func set_layer(ids: Array[int], layer: String) -> bool:
	return set_field(ids, &"layer", layer)


## Avance les choses `ids` d'un rang dans leur calque (`steps` négatif : les recule).
func shift_depth(ids: Array[int], steps: int) -> bool:
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		changes[thing_id] = {&"sort": int(_document.value(thing_id, &"sort")) + steps}
	return _apply(changes)


## Passe les choses `ids` devant (`to_front`) ou derrière toutes les autres choses de leur calque.
func to_extreme_depth(ids: Array[int], to_front: bool) -> bool:
	var changes: Dictionary[int, Dictionary] = {}
	for thing_id: int in ids:
		changes[thing_id] = {&"sort": _extreme_sort(_document.value(thing_id, &"layer"), ids, to_front)}
	return _apply(changes)


## Duplique les choses `ids`, décalées des réglages ; un double reste attaché au double de son parent si le parent est
## dupliqué avec lui. Un seul pas d'annulation ; rend les identifiants des doubles (vide si refusé).
func duplicate(ids: Array[int]) -> Array[int]:
	var list: Array[Dictionary] = []
	for thing_id: int in ids:
		var fields: Dictionary[StringName, Variant] = {}
		for field: StringName in RoomDocument.COLUMNS:
			fields[field] = _document.value(thing_id, field)
		fields[&"position"] = _position(thing_id) + _settings.duplicate_offset_m
		list.append(fields)
	var next_id: int = 1
	for existing: int in _document.ids():
		next_id = maxi(next_id, existing + 1)
	for index: int in list.size():
		var parent: int = list[index][&"parent"]
		if ids.has(parent):
			list[index][&"parent"] = next_id + ids.find(parent)
	var created: Array[int] = _document.add_things(list)
	errors.assign(_document.errors)
	return created


## Supprime les choses `ids`.
func delete(ids: Array[int]) -> bool:
	var done: bool = _document.remove_things(ids)
	errors.assign(_document.errors)
	return done


## Pose l'asset `asset_id` du catalogue en `position`, dans son calque par défaut, devant les choses de ce calque ;
## rend l'identifiant de la nouvelle chose, ou 0.
func add_asset(asset_id: StringName, position: Vector3) -> int:
	var asset: AssetDef = _catalog.find(asset_id)
	if asset == null:
		errors.assign(["asset %s : absent du catalogue" % asset_id])
		return 0
	var layer: String = String(asset.default_layer)
	var created: Array[int] = _document.add_things([{&"name": String(asset_id), &"asset": String(asset_id),
			&"layer": layer, &"position": position, &"sort": _extreme_sort(layer, [], true)}])
	errors.assign(_document.errors)
	return 0 if created.is_empty() else created[0]


# Le rang juste devant (ou juste derrière) toutes les choses du calque `layer`, sauf celles de `ignored`.
func _extreme_sort(layer: String, ignored: Array[int], to_front: bool) -> int:
	var extreme: int = 0
	var found: bool = false
	for other: int in _document.ids():
		if ignored.has(other) or _document.value(other, &"layer") != layer:
			continue
		var sort: int = _document.value(other, &"sort")
		extreme = sort if not found else (maxi(extreme, sort) if to_front else mini(extreme, sort))
		found = true
	return extreme + 1 if to_front else extreme - 1


func _position(thing_id: int) -> Vector3:
	return _document.value(thing_id, &"position")


func _float(thing_id: int, field: StringName) -> float:
	return _document.value(thing_id, field)


func _apply(changes: Dictionary[int, Dictionary]) -> bool:
	var done: bool = _document.apply(changes)
	errors.assign(_document.errors)
	return done
