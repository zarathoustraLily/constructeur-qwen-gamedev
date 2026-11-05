class_name InspectorPanel
extends VBoxContainer
## L'inspecteur : les champs de la sélection, modifiables. Chaque modification passe par `EditorActions` : un pas
## d'annulation, et la même validation que partout ailleurs. Une seule chose sélectionnée : tous ses champs, et ses champs
## inconnus affichés « non édités », en lecture seule. Plusieurs choses : leur nombre et les champs qu'on peut leur
## donner ensemble (calque, actif, parallaxe, hauteur, couleur). Rien de sélectionné : l'inspecteur le dit.

## Ce qu'affiche l'inspecteur quand rien n'est sélectionné.
const NOTHING: String = "Aucune sélection"
## La précision des champs numériques. Un `SpinBox` arrondit sa valeur à un multiple de son pas compté depuis
## `min_value` (référence de la classe Range, 4.7.2) : avec un pas de 0,05 au-dessus de 0,01, une échelle de 1,25
## s'afficherait 1,26. Le pas des flèches est réglé à part (`custom_arrow_step`).
const PRECISION: float = 0.001
## Les champs qu'on peut donner ensemble à plusieurs choses.
const SHARED: Array[StringName] = [&"layer", &"active", &"parallax", &"height", &"color"]

var _document: RoomDocument
var _selection: SelectionModel
var _actions: EditorActions
var _catalog: AssetCatalogDef
var _title: Label = Label.new()
var _extras: Label = Label.new()
var _controls: Dictionary[StringName, Control] = {}
var _refreshing: bool = false


## Branche l'inspecteur sur `document` et `selection` ; ses modifications passent par `actions`.
func setup(document: RoomDocument, selection: SelectionModel, actions: EditorActions,
		catalog: AssetCatalogDef) -> void:
	_document = document
	_selection = selection
	_actions = actions
	_catalog = catalog
	add_child(_title)
	_add_line_edit(&"name")
	_add_layers()
	_add_spin(&"x", -1000.0, 1000.0, 0.05)
	_add_spin(&"z", -1000.0, 1000.0, 0.05)
	_add_spin(&"rotation", 0.0, 359.99, 0.5)
	_add_spin(&"scale", 0.01, 100.0, 0.05)
	_add_spin(&"parallax", 0.0, 10.0, 0.05)
	_add_spin(&"height", -100.0, 100.0, 0.05)
	_add_spin(&"sort", -10000.0, 10000.0, 1.0)
	_add_check(&"active")
	_add_color(&"color")
	_extras.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_extras)
	_document.changed.connect(refresh)
	_selection.changed.connect(refresh)
	refresh()


## Le contrôle du champ `field` (pour les tests et les raccourcis).
func control(field: StringName) -> Control:
	return _controls.get(field)


## Le texte affiché en tête de l'inspecteur.
func title() -> String:
	return _title.text


## Le texte des champs inconnus de la chose sélectionnée (vide s'il n'y en a pas).
func extras_text() -> String:
	return _extras.text


## Donne la valeur `new_value` au champ `field` de la sélection (`x` et `z` : la position d'une chose seule).
func edit(field: StringName, new_value: Variant) -> bool:
	if _refreshing or _selection.is_empty():
		return false
	var ids: Array[int] = _selection.ids()
	if field == &"x" or field == &"z":
		# Pas de variable nommée position : elle masquerait celle du Control (une erreur, ici).
		var place_m: Vector3 = _document.value(ids[0], &"position")
		if field == &"x":
			place_m.x = new_value
		else:
			place_m.z = new_value
		return ids.size() == 1 and _actions.set_field(ids, &"position", place_m)
	return _actions.set_field(ids, field, new_value)


## Montre les valeurs de la sélection.
func refresh() -> void:
	_refreshing = true
	var ids: Array[int] = _selection.ids()
	_title.text = NOTHING if ids.is_empty() else (
			"%s (%d)" % [_document.value(ids[0], &"name"), ids[0]] if ids.size() == 1
			else "%d choses sélectionnées" % ids.size())
	for field: StringName in _controls:
		var shown: bool = ids.size() == 1 or (ids.size() > 1 and SHARED.has(field))
		_controls[field].get_parent().visible = shown
		if shown:
			_show_value(field, ids[0])
	_extras.text = ""
	if ids.size() == 1 and not _document.extras(ids[0]).is_empty():
		_extras.text = "Non édité : " + _document.extras(ids[0])
	_refreshing = false


func _show_value(field: StringName, thing_id: int) -> void:
	var control_of: Control = _controls[field]
	var place_m: Vector3 = _document.value(thing_id, &"position")
	var raw: Variant = place_m.x if field == &"x" else (place_m.z if field == &"z" else
			_document.value(thing_id, field))
	if control_of is SpinBox:
		(control_of as SpinBox).set_value_no_signal(float(raw))
	elif control_of is LineEdit:
		(control_of as LineEdit).text = str(raw)
	elif control_of is CheckBox:
		(control_of as CheckBox).set_pressed_no_signal(int(raw) == 1)
	elif control_of is ColorPickerButton:
		(control_of as ColorPickerButton).color = raw
	elif control_of is OptionButton:
		var picker: OptionButton = control_of as OptionButton
		picker.select(_catalog.layers.find(String(raw)))


func _row(field: StringName, control_of: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = String(field)
	label.custom_minimum_size.x = 90.0
	control_of.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(control_of)
	add_child(row)
	_controls[field] = control_of


func _add_spin(field: StringName, low: float, high: float, arrow_step: float) -> void:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = arrow_step if field == &"sort" else PRECISION
	spin.custom_arrow_step = arrow_step
	if field == &"sort":
		spin.value_changed.connect(func(value: float) -> void: edit(field, roundi(value)))
	else:
		spin.value_changed.connect(func(value: float) -> void: edit(field, value))
	_row(field, spin)


func _add_line_edit(field: StringName) -> void:
	var line: LineEdit = LineEdit.new()
	line.text_submitted.connect(func(value: String) -> void: edit(field, value))
	_row(field, line)


func _add_check(field: StringName) -> void:
	var check: CheckBox = CheckBox.new()
	check.toggled.connect(func(value: bool) -> void: edit(field, value))
	_row(field, check)


func _add_color(field: StringName) -> void:
	var picker: ColorPickerButton = ColorPickerButton.new()
	picker.color_changed.connect(func(value: Color) -> void: edit(field, value))
	_row(field, picker)


func _add_layers() -> void:
	var picker: OptionButton = OptionButton.new()
	for layer: String in _catalog.layers:
		picker.add_item(layer)
	picker.item_selected.connect(func(index: int) -> void: edit(&"layer", _catalog.layers[index]))
	_row(&"layer", picker)
