class_name AssetList extends Tree
## La liste des assets : une branche par catégorie qui en a, dans l'ordre de ViewerConfig.CATEGORIES, avec son nombre
## d'assets ; une ligne par asset, avec sa forme (3D ou 2D) et son chemin en info-bulle. Choisir une ligne émet
## asset_chosen ; choisir une branche ne fait rien.

## Un asset vient d'être choisi dans la liste.
signal asset_chosen(entry: AssetEntry)

## L'intitulé de chaque catégorie.
const TITLES: Dictionary[String, String] = {"heros": "Héros", "ennemi": "Ennemis", "boss": "Boss", "prop": "Props",
		"effet": "Effets"}

var _entries: Array[AssetEntry] = []


func _ready() -> void:
	hide_root = true
	item_selected.connect(_on_item_selected)


## Remplace la liste par `entries` (déjà triés).
func show_entries(entries: Array[AssetEntry]) -> void:
	clear()
	_entries = entries
	var root: TreeItem = create_item()
	var branch: TreeItem = null
	var branch_category: String = ""
	var branch_count: int = 0
	for i: int in entries.size():
		var entry: AssetEntry = entries[i]
		if branch == null or entry.category != branch_category:
			if branch != null:
				branch.set_text(0, "%s (%d)" % [TITLES[branch_category], branch_count])
			branch = create_item(root)
			branch.set_selectable(0, false)
			branch_category = entry.category
			branch_count = 0
		var item: TreeItem = create_item(branch)
		item.set_text(0, "%s · %s" % [entry.display_name, "3D" if entry.is_3d() else "2D"])
		item.set_tooltip_text(0, entry.path)
		item.set_metadata(0, i)
		branch_count += 1
	if branch != null:
		branch.set_text(0, "%s (%d)" % [TITLES[branch_category], branch_count])


## Le nombre d'assets montrés.
func entry_count() -> int:
	return _entries.size()


## Les textes des lignes, branches comprises, de haut en bas (pour les tests et l'aide).
func lines() -> Array[String]:
	var texts: Array[String] = []
	var root: TreeItem = get_root()
	if root == null:
		return texts
	for branch: TreeItem in root.get_children():
		texts.append(branch.get_text(0))
		for item: TreeItem in branch.get_children():
			texts.append("  " + item.get_text(0))
	return texts


## Sélectionne l'asset d'identifiant `id`, comme un clic ; faux s'il n'est pas dans la liste.
func choose(id: String) -> bool:
	var root: TreeItem = get_root()
	if root == null:
		return false
	for branch: TreeItem in root.get_children():
		for item: TreeItem in branch.get_children():
			if _entries[item.get_metadata(0) as int].id == id:
				item.select(0)
				return true
	return false


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()
	if item != null and item.get_metadata(0) != null:
		asset_chosen.emit(_entries[item.get_metadata(0) as int])
