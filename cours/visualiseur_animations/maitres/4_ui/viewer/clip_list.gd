class_name ClipList extends ItemList
## La liste des animations de l'asset montré, une ligne par animation, dans l'ordre reçu. Choisir une ligne émet
## clip_chosen avec son nom, pas son intitulé.

## Une animation vient d'être choisie.
signal clip_chosen(clip: String)

var _names: Array[String] = []


func _ready() -> void:
	item_selected.connect(_on_item_selected)


## Remplace la liste : `names` les noms, `titles` les intitulés montrés (le nom s'il en manque) ; `current` est
## sélectionné.
func show_clips(names: Array[String], titles: Array[String], current: String) -> void:
	clear()
	_names = names
	for i: int in names.size():
		add_item(titles[i] if i < titles.size() else names[i])
		if names[i] == current:
			select(i)


## Les intitulés montrés, de haut en bas.
func labels() -> Array[String]:
	var texts: Array[String] = []
	for i: int in item_count:
		texts.append(get_item_text(i))
	return texts


## Sélectionne l'animation `clip` sans rien émettre (le sujet a changé de clip lui-même).
func mark(clip: String) -> void:
	deselect_all()
	var index: int = _names.find(clip)
	if index >= 0:
		select(index)


## Choisit l'animation `clip`, comme un clic ; faux si elle n'est pas dans la liste.
func choose(clip: String) -> bool:
	var index: int = _names.find(clip)
	if index < 0:
		return false
	select(index)
	clip_chosen.emit(clip)
	return true


func _on_item_selected(index: int) -> void:
	clip_chosen.emit(_names[index])
