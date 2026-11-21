class_name StudioView extends Control
## La vue de l'écran du studio : un fond noir, la marque et le nom de la boîte au centre, la barre de chargement en
## bas. Elle ne décide rien : l'écran lui donne le nom, puis, à chaque image, l'opacité et l'avancée du chargement.

@onready var _centre: Control = $Centre
@onready var _name_label: Label = $Centre/Nom
@onready var _bar: ProgressBar = $Barre


## Affiche le nom de la boîte.
func show_name(text: String) -> void:
	_name_label.text = text


## Montre l'opacité de la marque et du nom, et l'avancée du chargement (de 0 à 1).
func render(opacity: float, progress: float) -> void:
	_centre.modulate.a = opacity
	_bar.modulate.a = opacity
	_bar.value = progress


## L'opacité montrée.
func shown_opacity() -> float:
	return _centre.modulate.a


## L'avancée montrée par la barre.
func shown_progress() -> float:
	return _bar.value


## Le nom montré.
func shown_name() -> String:
	return _name_label.text
