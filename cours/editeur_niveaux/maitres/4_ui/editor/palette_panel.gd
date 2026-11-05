class_name PalettePanel
extends VBoxContainer
## La palette : une zone de recherche et la liste des assets du catalogue, chacun avec sa vignette (sa région de la
## planche). Un double-clic, ou Entrée, choisit l'asset : la coquille le pose au centre de la vue.

## L'asset `asset_id` vient d'être choisi pour être posé.
signal asset_chosen(asset_id: StringName)

## La taille des vignettes, en pixels.
const ICON_SIZE: Vector2i = Vector2i(48, 48)

var _catalog: AssetCatalogDef
var _search: AssetSearch = AssetSearch.new()
var _query: LineEdit = LineEdit.new()
var _list: ItemList = ItemList.new()
var _shown: Array[StringName] = []


## Remplit la palette avec les assets de `catalog`.
func setup(catalog: AssetCatalogDef) -> void:
	_catalog = catalog
	_search.setup(catalog)
	_query.placeholder_text = "Chercher un asset"
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = ICON_SIZE
	add_child(_query)
	add_child(_list)
	_query.text_changed.connect(filter)
	_list.item_activated.connect(choose)
	filter("")


## Ne montre que les assets qui répondent à `query` (tous si elle est vide).
func filter(query: String) -> void:
	_shown = _search.search(query)
	_list.clear()
	for asset_id: StringName in _shown:
		var asset: AssetDef = _catalog.find(asset_id)
		var icon: AtlasTexture = AtlasTexture.new()
		icon.atlas = asset.atlas
		icon.region = Rect2(asset.region)
		_list.add_item(String(asset_id), icon)


## Les assets montrés, dans l'ordre de la liste.
func shown() -> Array[StringName]:
	return _shown.duplicate()


## Choisit l'asset de la ligne `index`.
func choose(index: int) -> void:
	if index >= 0 and index < _shown.size():
		asset_chosen.emit(_shown[index])
