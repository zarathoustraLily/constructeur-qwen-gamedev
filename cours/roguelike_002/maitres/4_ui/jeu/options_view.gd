class_name OptionsView extends Control
## La vue des options : le titre, puis une ligne par réglage, chacune un bouton « Libellé : ◀ valeur ▶ ». Godot
## parcourt les lignes de haut en bas (flèches, croix, stick) ; la vue dit quelle ligne est mise en avant et laquelle
## est validée. Elle ne décide rien : l'écran lui donne les libellés et, après chaque changement, les valeurs.

## Une ligne vient d'être mise en avant.
signal row_focused(row: StringName)
## Une ligne vient d'être validée.
signal row_chosen(row: StringName)

var _labels: Dictionary[StringName, String] = {}
var _buttons: Dictionary[StringName, Button] = {}

@onready var _title: Label = $Titre
@onready var _rows_box: VBoxContainer = $Lignes


## Construit le titre et une ligne par réglage de `rows`, avec leurs libellés.
func setup(title: String, rows: Array[StringName], labels: Dictionary[StringName, String]) -> void:
	_title.text = title
	_labels = labels
	for row: StringName in rows:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_entered.connect(func() -> void: row_focused.emit(row))
		button.pressed.connect(func() -> void: row_chosen.emit(row))
		_rows_box.add_child(button)
		_buttons[row] = button
		show_value(row, "")
#@ 5-5
	_link_rows(rows)
#@ 6+
	var column: Array[Control] = []
	for row: StringName in rows:
		column.append(_buttons[row])
	FocusChain.link_column(column)
#@ all


## Montre la valeur de la ligne `row` (une ligne sans valeur ne montre que son libellé).
func show_value(row: StringName, value: String) -> void:
	_buttons[row].text = _labels[row] if value.is_empty() else "%s :  ◀ %s ▶" % [_labels[row], value]


## Met la ligne `row` en avant.
func focus_row(row: StringName) -> void:
	_buttons[row].grab_focus()


## Le texte montré par la ligne `row`.
func row_text(row: StringName) -> String:
	return _buttons[row].text

#@ 5-5

## Chaque ligne nomme sa voisine du dessous et du dessus (la dernière mène à la première) : Godot n'a pas à les
## chercher d'après leur place à l'écran, que le conteneur ne calcule qu'à l'image suivante.
func _link_rows(rows: Array[StringName]) -> void:
	for i: int in rows.size():
		var button: Button = _buttons[rows[i]]
		var below: Button = _buttons[rows[(i + 1) % rows.size()]]
		var above: Button = _buttons[rows[(i + rows.size() - 1) % rows.size()]]
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_next = button.focus_neighbor_bottom
		button.focus_previous = button.focus_neighbor_top
#@ all
