class_name FlaskCounter extends Control
## Les fioles qui restent : une fiole dessinée (corps rond, col, liquide ambré) et leur nombre ; sans fiole, le dessin
## s'éteint. On lui donne le compte, elle ne sait rien du héros.

## La couleur du liquide.
@export var liquid_color: Color = Color(0.95, 0.6, 0.15)
## La couleur du verre.
@export var glass_color: Color = Color(0.8, 0.8, 0.75, 0.8)

## Les fioles qui restent.
var charges: int = 0

@onready var _count: Label = $Count


## Pose le compte : `charges` sur `maximum`.
func set_charges(count: int, _maximum: int) -> void:
	charges = count
	_count.text = str(count)
	modulate.a = 1.0 if count > 0 else 0.45
	queue_redraw()


func _draw() -> void:
	var rayon: float = size.x * 0.32
	var centre: Vector2 = Vector2(size.x * 0.5, size.y - rayon - 4.0)
	draw_rect(Rect2(centre.x - rayon * 0.3, centre.y - rayon * 2.1, rayon * 0.6, rayon * 1.3), glass_color)
	draw_circle(centre, rayon, glass_color)
	if charges > 0:
		draw_circle(centre, rayon * 0.82, liquid_color)
