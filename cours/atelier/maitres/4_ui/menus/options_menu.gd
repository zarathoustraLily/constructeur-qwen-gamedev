class_name OptionsMenu extends Control
## Les options : le volume de la musique et celui des effets, chacun sur un curseur de 0 à 100 % avec son
## libellé. La croix ou le stick choisit une ligne et déplace le curseur ; B ou Échap ferme le menu. Le menu
## montre et émet des valeurs ; c'est la scène principale qui les donne au service audio.

## Le joueur a déplacé le curseur du bus `bus` ; `linear` : le nouveau volume, de 0 à 1.
signal volume_changed(bus: StringName, linear: float)
## Le joueur ferme les options.
signal closed

## Les réglages des curseurs.
@export var settings: MenuSettings

@onready var _music: HSlider = $Center/Rows/Music/Slider
@onready var _music_value: Label = $Center/Rows/Music/Value
@onready var _sfx: HSlider = $Center/Rows/Sfx/Slider
@onready var _sfx_value: Label = $Center/Rows/Sfx/Value
@onready var _back: Button = $Center/Rows/Back


func _ready() -> void:
	for slider: HSlider in [_music, _sfx]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = settings.volume_step
	_music.value_changed.connect(func(value: float) -> void: _on_slider(AudioManager.MUSIC, _music_value, value))
	_sfx.value_changed.connect(func(value: float) -> void: _on_slider(AudioManager.SFX, _sfx_value, value))
	_back.pressed.connect(func() -> void: closed.emit())
	MenuFocus.chain([_music, _sfx, _back], false)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


## Place les curseurs sur `music` et `sfx` (de 0 à 1) et met leurs libellés à jour, sans émettre
## volume_changed : ce sont les valeurs actuelles, pas un choix du joueur.
func show_volumes(music: float, sfx: float) -> void:
	_music.set_value_no_signal(music)
	_sfx.set_value_no_signal(sfx)
	_music_value.text = Volume.percent_text(music)
	_sfx_value.text = Volume.percent_text(sfx)


## Montre le menu, le focus sur le premier curseur.
func open() -> void:
	show()
	_music.grab_focus()


func _on_slider(bus: StringName, label: Label, value: float) -> void:
	label.text = Volume.percent_text(value)
	volume_changed.emit(bus, value)
