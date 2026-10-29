class_name DefeatScreen extends Control
## L'écran de chute : un voile sombre et un mot, qui apparaissent en fondu quand le héros tombe, pendant que le niveau
## attend de recommencer.

## Le temps du fondu, en secondes (posé par l'interface).
var fade_time: float = 1.2

@onready var _word: Label = $Word


func _ready() -> void:
	visible = false
	modulate.a = 0.0


func _process(delta: float) -> void:
	advance(delta)


## Commence le fondu avec le mot `text`.
func show_defeat(text: String) -> void:
	_word.text = text
	modulate.a = 0.0
	visible = true


## Fait passer `delta` secondes sur le fondu.
func advance(delta: float) -> void:
	if visible and modulate.a < 1.0:
		modulate.a = minf(modulate.a + delta / fade_time, 1.0) if fade_time > 0.0 else 1.0


## Le mot affiché.
func shown_text() -> String:
	return _word.text
