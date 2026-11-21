class_name MenuView extends Control
## La vue du menu principal : le fond étoilé qui glisse, la planète qui flotte, le titre qui tombe à sa place, les
## choix qui arrivent l'un après l'autre par la droite, le choix mis en avant qui grandit et s'écarte, un choix pas
## encore disponible qui tremble, puis tout qui s'efface au départ. Elle ne décide rien : chaque position se calcule à
## partir du temps et de l'âge des événements que l'écran lui donne (`Tween.interpolate_value`, `pingpong`, `sin`).
## Les choix sont des boutons : Godot les parcourt lui-même au clavier, à la croix et au stick.

## Un choix vient d'être mis en avant (focus du clavier ou de la manette).
signal item_focused(item: StringName)
## Un choix vient d'être validé.
signal item_chosen(item: StringName)

var _menu: MenuDef = null
var _buttons: Dictionary[StringName, Button] = {}

@onready var _background: TextureRect = $Fond
@onready var _planet: TextureRect = $Planete
@onready var _title: Label = $Titre
@onready var _items_root: Control = $Choix


## Construit le titre, la planète et un bouton par choix, d'après `menu`.
func setup(menu: MenuDef) -> void:
	_menu = menu
	_title.text = menu.game_title
	_title.add_theme_font_size_override(&"font_size", menu.title_font_size)
	_planet.position = menu.planet_rect_px.position
	_planet.size = menu.planet_rect_px.size
	for item: StringName in menu.items:
		var button := Button.new()
		button.text = menu.labels[item]
		button.custom_minimum_size = menu.item_size_px
		button.size = menu.item_size_px
		button.pivot_offset_ratio = menu.focus_pivot
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override(&"font_size", menu.item_font_size)
		button.focus_entered.connect(func() -> void: item_focused.emit(item))
		button.pressed.connect(func() -> void: item_chosen.emit(item))
		_items_root.add_child(button)
		_buttons[item] = button


## Rend les choix accessibles au clavier et à la manette (le premier prend le focus), ou plus du tout.
func set_interactive(on: bool) -> void:
	for item: StringName in _menu.items:
		_buttons[item].focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
	if on:
		_buttons[_menu.items[0]].grab_focus()


## Montre l'instant `time` : `focused` est mis en avant depuis `focus_age` secondes, `refused` tremble depuis
## `refuse_age` secondes, et le départ en est à `leave` (de 0 à 1).
func render(time: float, focused: StringName, focus_age: float, refused: StringName, refuse_age: float,
		leave: float) -> void:
	modulate.a = 1.0 - leave
	_background.position.x = -pingpong(time * _menu.background_speed_px_s, _menu.background_travel_px)
	_planet.position.y = _menu.planet_rect_px.position.y + sin(time / _menu.planet_period_s * TAU) * _menu.planet_bob_px
	var title_t: float = time - _menu.title_delay_s
	_title.position.y = _arrive(_menu.title_y_px - _menu.title_drop_px, _menu.title_drop_px, title_t,
			_menu.title_in_s, Tween.TRANS_BACK)
	_title.modulate.a = _ratio(title_t, _menu.title_in_s)
	for i: int in _menu.items.size():
		var item: StringName = _menu.items[i]
		var button: Button = _buttons[item]
		var item_t: float = time - _menu.items_delay_s - _menu.item_stagger_s * i
		var x: float = _arrive(_menu.items_origin_px.x + _menu.item_slide_px, -_menu.item_slide_px, item_t,
				_menu.item_in_s, Tween.TRANS_CUBIC)
		var lift: float = _ratio(focus_age, _menu.focus_s) if item == focused else 0.0
		x += _menu.focus_shift_px * lift
		if item == refused and refuse_age < _menu.refuse_s:
			var k: float = _ratio(refuse_age, _menu.refuse_s)
			x += sin(k * TAU * _menu.refuse_shakes) * _menu.refuse_px * (1.0 - k)
		button.position = Vector2(x, _menu.items_origin_px.y + _menu.item_spacing_px * i)
		button.scale = Vector2.ONE * lerpf(1.0, _menu.focus_scale, lift)
		button.modulate.a = _ratio(item_t, _menu.item_in_s)


## Le bouton du choix `item`.
func button_of(item: StringName) -> Button:
	return _buttons[item]


## Le titre.
func title_label() -> Label:
	return _title


## Le fond étoilé.
func background() -> TextureRect:
	return _background


func _ratio(t: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(t / duration, 0.0, 1.0)


func _arrive(from: float, delta: float, t: float, duration: float, trans: Tween.TransitionType) -> float:
	if duration <= 0.0 or t >= duration:
		return from + delta
	return Tween.interpolate_value(from, delta, maxf(t, 0.0), duration, trans, Tween.EASE_OUT)
