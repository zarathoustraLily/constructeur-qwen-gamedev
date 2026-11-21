class_name OptionsScreen extends Control
## L'écran des options : une ligne par réglage (difficulté, définition, plein écran, un volume par bus) et « Retour ».
## Gauche et droite changent la ligne mise en avant ; valider la change aussi (ou revient, sur « Retour ») ; revenir
## (B, Échap) enregistre et ramène au menu. Chaque changement s'applique tout de suite : on entend le volume baisser
## pendant qu'on le règle. Les entrées (`OptionsInput`) demandent, l'écran décide, la vue (`OptionsView`) montre.

## L'écran a fini ; `next` nomme le suivant.
signal finished(next: StringName)

## Les options du jeu.
@export var options: OptionsDef = null

## Les réglages en cours.
var settings: GameSettings = null
## La ligne mise en avant.
var focused_row: StringName = &""

var _left: bool = false

@onready var _view: OptionsView = $View
@onready var _input: OptionsInput = $Input


func _ready() -> void:
	process_priority = ProcessOrder.FLOW
	for error: String in options.validate():
		push_error(error)
	settings = GameSettings.load_from(options)
	_view.setup(options.title, options.rows(), options.row_labels)
	_view.row_focused.connect(func(row: StringName) -> void: focused_row = row)
	_view.row_chosen.connect(choose)
	_input.previous_requested.connect(func() -> void: change(focused_row, false))
	_input.next_requested.connect(func() -> void: change(focused_row, true))
	_input.back_requested.connect(back)
	_refresh()
	_view.focus_row(options.rows()[0])


## Change la ligne `row`, vers la valeur suivante (`forward`) ou précédente, puis applique les réglages.
func change(row: StringName, forward: bool) -> void:
	if row == &"difficulte":
		settings.difficulty = _cycle(options.difficulties, settings.difficulty, forward)
	elif row == &"definition":
		settings.resolution = _cycle(options.resolutions, settings.resolution, forward)
	elif row == &"plein_ecran":
		settings.fullscreen = not settings.fullscreen
	elif settings.volumes.has(row):
		var step: float = options.volume_step if forward else -options.volume_step
		settings.volumes[row] = clampf(snappedf(settings.volumes[row] + step, options.volume_step), 0.0, 1.0)
	else:
		return
	SettingsApplier.apply(settings)
	_refresh()


## Valide la ligne `row` : « Retour » revient, les autres passent à leur valeur suivante.
func choose(row: StringName) -> void:
	if row == &"retour":
		back()
	else:
		change(row, true)


## Enregistre les réglages et revient à l'écran d'où l'on vient (une seule fois).
func back() -> void:
	if _left:
		return
	_left = true
	settings.save_to(options)
	finished.emit(options.back_screen)


## Le texte de la valeur de la ligne `row`.
func value_text(row: StringName) -> String:
	if row == &"difficulte":
		return options.difficulty_labels[settings.difficulty]
	if row == &"definition":
		return "%d × %d" % [settings.resolution.x, settings.resolution.y]
	if row == &"plein_ecran":
		return options.on_label if settings.fullscreen else options.off_label
	if settings.volumes.has(row):
		var total: int = roundi(1.0 / options.volume_step)
		var full: int = roundi(settings.volumes[row] / options.volume_step)
		return options.volume_full_mark.repeat(full) + options.volume_empty_mark.repeat(total - full)
	return ""


func _refresh() -> void:
	for row: StringName in options.rows():
		_view.show_value(row, value_text(row))


func _cycle(values: Array, current: Variant, forward: bool) -> Variant:
	var index: int = values.find(current)
	if index < 0:
		return values[0]
	var shift: int = 1 if forward else values.size() - 1
	return values[(index + shift) % values.size()]
