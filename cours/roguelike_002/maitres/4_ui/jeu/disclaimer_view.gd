class_name DisclaimerView extends Control
## La vue de l'avertissement : le titre et le texte au centre, la consigne en bas, qui n'apparaît que quand on peut
## passer l'écran, et qui respire alors doucement. Elle ne décide rien : l'écran lui donne les textes, le rythme de la
## respiration, puis à chaque image l'opacité et si la consigne se montre.

var _pulse_s: float = 0.0
var _low_alpha: float = 0.0
var _pulse: Tween = null

@onready var _title_label: Label = $Contenu/Titre
@onready var _body_label: Label = $Contenu/Texte
@onready var _hint_label: Label = $Consigne


## Affiche les textes ; la consigne reste cachée. Elle respirera en `pulse_s` secondes, jusqu'à l'opacité `low_alpha`.
func show_texts(title: String, body: String, hint: String, pulse_s: float, low_alpha: float) -> void:
	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_hint_label.visible = false
	_pulse_s = pulse_s
	_low_alpha = low_alpha


## Montre l'opacité de l'écran (de 0 à 1) et, quand `can_skip` devient vrai, la consigne qui respire.
func render(opacity: float, can_skip: bool) -> void:
	modulate.a = opacity
	if can_skip and not _hint_label.visible:
		_hint_label.visible = true
		_start_pulse()


## Vrai quand la consigne se voit.
func hint_shown() -> bool:
	return _hint_label.visible


## Le texte montré.
func shown_body() -> String:
	return _body_label.text


func _start_pulse() -> void:
	if _pulse_s <= 0.0:
		return
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_hint_label, "modulate:a", _low_alpha, _pulse_s)
	_pulse.tween_property(_hint_label, "modulate:a", 1.0, _pulse_s)
