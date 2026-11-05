class_name DefinitionPanel
extends VBoxContainer
## Le panneau des paramètres du jeu : une famille (ennemis, effets), ses définitions, et le formulaire de celle qu'on a
## choisie, construit d'après ses champs (un `SpinBox` par nombre, une case par booléen, une ligne de texte par nom, un
## sélecteur par couleur). « Enregistrer » écrit la définition seulement si elle est valide ; sinon, les erreurs
## s'affichent sous le formulaire et rien n'est écrit. « Annuler » défait le dernier changement.

## Une définition vient d'être enregistrée : `path`.
signal definition_saved(path: String)

## La précision des champs numériques (voir l'inspecteur : un `SpinBox` arrondit depuis son minimum).
const PRECISION: float = 0.001
## Les bornes des champs numériques.
const LIMIT: float = 100000.0

var _families: Dictionary[String, String] = {}
var _editor: DefinitionEditor = DefinitionEditor.new()
var _family: OptionButton = OptionButton.new()
var _list: ItemList = ItemList.new()
var _form: VBoxContainer = VBoxContainer.new()
var _messages: Label = Label.new()
var _files: PackedStringArray = PackedStringArray()
var _open_path: String = ""


## Construit le panneau pour les familles `families` ({nom affiché : dossier de 5_data}).
func setup(families: Dictionary[String, String]) -> void:
	_families = families
	for family: String in families:
		_family.add_item(family)
	_family.item_selected.connect(func(_index: int) -> void: show_family())
	add_child(_family)
	_list.custom_minimum_size.y = 120.0
	_list.item_selected.connect(open_index)
	add_child(_list)
	add_child(_form)
	var buttons: HBoxContainer = HBoxContainer.new()
	var save_button: Button = Button.new()
	save_button.text = "Enregistrer"
	save_button.pressed.connect(save)
	var undo_button: Button = Button.new()
	undo_button.text = "Annuler"
	undo_button.pressed.connect(undo)
	buttons.add_child(save_button)
	buttons.add_child(undo_button)
	add_child(buttons)
	_messages.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_messages)
	show_family()


## Montre les définitions de la famille choisie.
func show_family() -> void:
	_list.clear()
	_files = PackedStringArray()
	var folder: String = _families.values()[maxi(_family.selected, 0)] if not _families.is_empty() else ""
	if DirAccess.dir_exists_absolute(folder):
		for file: String in DirAccess.get_files_at(folder):
			if file.get_extension() == "tres" and not file.begins_with("."):
				_files.append(folder.path_join(file))
				_list.add_item(file.get_basename())


## Ouvre la définition de la ligne `index`.
func open_index(index: int) -> void:
	if index >= 0 and index < _files.size() and _editor.open(_files[index]):
		_open_path = _files[index]
		_messages.text = ""
		_build_form()


## L'éditeur de la définition ouverte (pour les tests).
func editor() -> DefinitionEditor:
	return _editor


## Le texte des messages sous le formulaire.
func messages() -> String:
	return _messages.text


## Enregistre la définition ouverte, si elle est valide.
func save() -> bool:
	if _editor.save():
		_messages.text = "%s enregistré" % _editor.id()
		definition_saved.emit(_open_path)
		return true
	_messages.text = "Enregistrement impossible : " + "; ".join(_editor.errors)
	return false


## Défait le dernier changement de la définition ouverte.
func undo() -> bool:
	if not _editor.undo():
		return false
	_build_form()
	return true


func _build_form() -> void:
	for child: Node in _form.get_children():
		_form.remove_child(child)
		child.queue_free()
	var title: Label = Label.new()
	title.text = String(_editor.id())
	_form.add_child(title)
	for entry: Dictionary in _editor.fields():
		_form.add_child(_row(entry[&"name"], entry[&"type"]))


func _row(field: StringName, type: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = String(field)
	label.custom_minimum_size.x = 110.0
	row.add_child(label)
	var current: Variant = _editor.value(field)
	var control_of: Control
	match type:
		TYPE_FLOAT, TYPE_INT:
			var spin: SpinBox = SpinBox.new()
			spin.min_value = -LIMIT
			spin.max_value = LIMIT
			spin.step = 1.0 if type == TYPE_INT else PRECISION
			spin.set_value_no_signal(float(current))
			if type == TYPE_INT:
				spin.value_changed.connect(func(value: float) -> void: _edit(field, roundi(value)))
			else:
				spin.value_changed.connect(func(value: float) -> void: _edit(field, value))
			control_of = spin
		TYPE_BOOL:
			var check: CheckBox = CheckBox.new()
			check.set_pressed_no_signal(bool(current))
			check.toggled.connect(func(value: bool) -> void: _edit(field, value))
			control_of = check
		TYPE_COLOR:
			var picker: ColorPickerButton = ColorPickerButton.new()
			picker.color = current
			picker.color_changed.connect(func(value: Color) -> void: _edit(field, value))
			control_of = picker
		_:
			var line: LineEdit = LineEdit.new()
			line.text = str(current)
			line.text_submitted.connect(func(value: String) -> void: _edit(field, value))
			control_of = line
	control_of.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control_of)
	return row


func _edit(field: StringName, new_value: Variant) -> void:
	if not _editor.set_value(field, new_value):
		_messages.text = "; ".join(_editor.errors)
		return
	var problems: Array[String] = _editor.validation_errors()
	_messages.text = "" if problems.is_empty() else "À corriger avant d'enregistrer : " + "; ".join(problems)
