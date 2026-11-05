class_name AssetCatalogDef
extends Resource
## Le catalogue des assets du jeu (`5_data/catalogue/catalogue.tres`) : les calques des salles, et la liste des assets
## qu'une salle peut poser. L'éditeur et le jeu lisent le même : un asset ajouté ici apparaît dans la palette de
## l'éditeur, et le jeu sait le dessiner.

## Identifiant du catalogue.
@export var id: StringName = &"catalogue"
## Les calques des salles, du plus bas au plus haut.
@export var layers: PackedStringArray = PackedStringArray()
## Les assets.
@export var assets: Array[AssetDef] = []


## L'asset `asset_id`, ou null.
func find(asset_id: StringName) -> AssetDef:
	for asset: AssetDef in assets:
		if asset.id == asset_id:
			return asset
	return null


## Les identifiants des assets, dans l'ordre du catalogue.
func ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for asset: AssetDef in assets:
		result.append(String(asset.id))
	return result


## Les erreurs du catalogue, une phrase par erreur ; vide s'il est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if layers.is_empty():
		errors.append("layers : au moins un calque requis")
	var seen: Dictionary[StringName, bool] = {}
	for asset: AssetDef in assets:
		if asset == null:
			errors.append("assets : entrée vide")
			continue
		errors.append_array(asset.validate())
		if seen.has(asset.id):
			errors.append("asset %s : en double" % asset.id)
		seen[asset.id] = true
		if not layers.has(String(asset.default_layer)):
			errors.append("asset %s : calque par défaut inconnu %s" % [asset.id, asset.default_layer])
	return errors


## Les erreurs de `room` face au catalogue : un calque ou un asset que le catalogue ne connaît pas.
func room_errors(room: RoomData) -> Array[String]:
	var errors: Array[String] = []
	for layer: String in room.layers:
		if not layers.has(layer):
			errors.append("calque %s : absent du catalogue" % layer)
	var known: PackedStringArray = ids()
	for index: int in room.thing_count():
		if not known.has(room.thing_assets[index]):
			errors.append("chose %d : asset inconnu %s" % [room.thing_ids[index], room.thing_assets[index]])
	return errors
