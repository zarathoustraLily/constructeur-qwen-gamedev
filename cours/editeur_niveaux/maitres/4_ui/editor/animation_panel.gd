class_name AnimationPanel
extends VBoxContainer
## Le panneau des animations, en mode « Animations » : la liste des définitions d'animation du jeu, et pour celle qu'on
## choisit, une ligne par état : le clip, choisi parmi ceux du modèle (on ne peut pas citer un clip qui n'existe pas), et
## sa vitesse. Sous les lignes, ce que la validation refuse ; « Enregistrer » écrit seulement une définition valide.

## Une définition d'animation vient d'être enregistrée : `path`.
signal animation_saved(path: String)

## La précision du champ de vitesse.
const PRECISION: float = 0.001

var _folder: String = ""
var _files: PackedStringArray = PackedStringArray()
var _editor: DefinitionEditor = DefinitionEditor.new()
var _list: ItemList = ItemList.new()
var _rows: VBoxContainer = VBoxContainer.new()
var _messages: Label = Label.new()
var _pickers: Dictionary[StringName, OptionButton] = {}
var _open_path: String = ""


## Construit le panneau pour les définitions du dossier `folder`.
func setup(folder: String) -> void:
	_folder = folder
	var title: Label = Label.new()
	title.text = "Animations"
	add_child(title)
	_list.custom_minimum_size.y = 120.0
	_list.item_selected.connect(open_index)
	add_child(_list)
	add_child(_rows)
	var save_button: Button = Button.new()
	save_button.text = "Enregistrer"
	save_button.pressed.connect(save)
	add_child(save_button)
	_messages.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_messages)
	if DirAccess.dir_exists_absolute(folder):
		for file: String in DirAccess.get_files_at(folder):
			if file.get_extension() == "tres" and not file.begins_with("."):
				_files.append(folder.path_join(file))
				_list.add_item(file.get_basename())


## Ouvre la définition de la ligne `index`.
func open_index(index: int) -> void:
	if index < 0 or index >= _files.size() or not _editor.open(_files[index]):
		return
	_open_path = _files[index]
	_build_rows()
	_show_problems()


## Donne au clip de l'état `state` le clip `clip` du modèle ; rend false si la valeur est refusée.
func choose_clip(state: StringName, clip: StringName) -> bool:
	var clips: Dictionary[StringName, StringName] = _editor.value(&"clips").duplicate()
	clips[state] = clip
	var done: bool = _editor.set_value(&"clips", clips)
	_show_problems()
	return done


## Donne à l'état `state` la vitesse `speed`.
func set_speed(state: StringName, speed: float) -> bool:
	var speeds: Dictionary[StringName, float] = _editor.value(&"speeds").duplicate()
	speeds[state] = speed
	var done: bool = _editor.set_value(&"speeds", speeds)
	_show_problems()
	return done


## Les clips proposés pour un état : ceux du modèle de la définition ouverte.
func offered_clips() -> PackedStringArray:
	var definition: AnimationDef = AnimationDef.new()
	definition.model = _editor.value(&"model")
	return definition.model_clips()


## Le texte des messages sous les lignes.
func messages() -> String:
	return _messages.text


## Enregistre la définition ouverte, si elle est valide.
func save() -> bool:
	if not _editor.save():
		_messages.text = "Enregistrement impossible : " + "; ".join(_editor.errors)
		return false
	_messages.text = "%s enregistré" % _editor.id()
	animation_saved.emit(_open_path)
	return true


func _build_rows() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_pickers.clear()
	var offered: PackedStringArray = offered_clips()
	var clips: Dictionary = _editor.value(&"clips")
	var speeds: Dictionary = _editor.value(&"speeds")
	for state: StringName in AnimationDef.STATES:
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = String(state)
		label.custom_minimum_size.x = 70.0
		var picker: OptionButton = OptionButton.new()
		for clip: String in offered:
			picker.add_item(clip)
		picker.select(offered.find(String(clips.get(state, &""))))
		picker.item_selected.connect(func(index: int) -> void: choose_clip(state, StringName(offered[index])))
		var speed: SpinBox = SpinBox.new()
		speed.min_value = 0.0
		speed.max_value = 10.0
		speed.step = PRECISION
		speed.set_value_no_signal(float(speeds.get(state, 1.0)))
		speed.value_changed.connect(func(value: float) -> void: set_speed(state, value))
		row.add_child(label)
		row.add_child(picker)
		row.add_child(speed)
		_rows.add_child(row)
		_pickers[state] = picker


func _show_problems() -> void:
	var problems: Array[String] = _editor.validation_errors()
	_messages.text = "" if problems.is_empty() else "À corriger avant d'enregistrer : " + "; ".join(problems)
