class_name HierarchyPanel
extends Tree
## La hiérarchie : les calques de la salle et, sous chacun, ses choses dans l'ordre de dessin. Un clic sur une chose la
## sélectionne, même une dalle du sol, que la vue ne laisse pas prendre ; la sélection faite ailleurs se reflète ici.
## Une modification du document reconstruit l'arbre ; un changement de sélection ne fait que remettre les marques de
## sélection : reconstruire l'arbre pendant que le `Tree` traite le clic qui a changé la sélection libérerait la ligne
## sur laquelle il travaille encore.

var _document: RoomDocument
var _selection: SelectionModel
var _catalog: AssetCatalogDef
var _items: Dictionary[int, TreeItem] = {}
var _refreshing: bool = false


## Branche la hiérarchie sur `document` et `selection`, avec les calques de `catalog`.
func setup(document: RoomDocument, selection: SelectionModel, catalog: AssetCatalogDef) -> void:
	_document = document
	_selection = selection
	_catalog = catalog
	hide_root = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_selected.connect(_on_item_selected)
	_document.changed.connect(refresh)
	_selection.changed.connect(sync_selection)
	refresh()


## Reconstruit l'arbre depuis le document et la sélection.
func refresh() -> void:
	_refreshing = true
	clear()
	_items.clear()
	var root: TreeItem = create_item()
	var layer_items: Dictionary[String, TreeItem] = {}
	for layer: String in _catalog.layers:
		var layer_item: TreeItem = create_item(root)
		layer_item.set_text(0, layer)
		layer_item.set_selectable(0, false)
		layer_items[layer] = layer_item
	if _document.is_open():
		for thing_id: int in DrawOrder.sorted(_document, _catalog.layers):
			var layer: String = _document.value(thing_id, &"layer")
			var item: TreeItem = create_item(layer_items.get(layer, root))
			item.set_text(0, "%s (%d)" % [_document.value(thing_id, &"name"), thing_id])
			item.set_metadata(0, thing_id)
			_items[thing_id] = item
	_refreshing = false
	sync_selection()


## Remet les marques de sélection d'après la sélection, sans reconstruire l'arbre.
func sync_selection() -> void:
	_refreshing = true
	deselect_all()
	for thing_id: int in _selection.ids():
		if _items.has(thing_id):
			_items[thing_id].select(0)
	_refreshing = false


## La ligne de la chose `thing_id`, ou null.
func item_of(thing_id: int) -> TreeItem:
	return _items.get(thing_id)


func _on_item_selected() -> void:
	if _refreshing or get_selected() == null:
		return
	_selection.replace([int(get_selected().get_metadata(0))])
