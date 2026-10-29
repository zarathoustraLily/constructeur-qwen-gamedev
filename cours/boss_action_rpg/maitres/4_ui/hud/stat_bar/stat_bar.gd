class_name StatBar extends Control
## Une jauge (vie, endurance, chaleur, vie du boss) : le remplissage montre la valeur ; après une perte, une traîne claire
## garde l'ancienne valeur un instant puis la rejoint, pour qu'on lise ce qu'un coup vient d'enlever ; un gain remonte
## d'un coup, traîne comprise. Elle ne sait rien de ce qu'elle mesure : on lui donne la valeur et son maximum.

## La couleur du remplissage.
@export var fill_color: Color = Color(0.55, 0.08, 0.06)
## La couleur de la traîne.
@export var trail_color: Color = Color(0.85, 0.7, 0.3)
## Le fond de la jauge.
@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.6)
## Le cadre de la jauge.
@export var border_color: Color = Color(0.8, 0.75, 0.6, 0.5)

## Après une perte, le temps pendant lequel la traîne attend, en secondes (posé par l'interface).
var trail_delay: float = 0.6
## La vitesse de la traîne, en part de la jauge par seconde (posée par l'interface).
var trail_speed: float = 0.6
## La part remplie, de 0 à 1.
var ratio: float = 1.0
## La part de la traîne, de 0 à 1 : jamais sous la part remplie.
var trail_ratio: float = 1.0

var _wait: float = 0.0


func _process(delta: float) -> void:
	advance(delta)


## Pose la valeur `current` sur `maximum` : une perte fait attendre la traîne, un gain la remonte avec la valeur.
func set_values(current: float, maximum: float) -> void:
	var part: float = clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	if part < ratio:
		_wait = trail_delay
	trail_ratio = maxf(trail_ratio, part)
	ratio = part
	queue_redraw()


## Pose la valeur `current` sur `maximum` d'un coup, traîne comprise : le premier branchement n'est pas une perte.
func snap(current: float, maximum: float) -> void:
	ratio = clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	trail_ratio = ratio
	_wait = 0.0
	queue_redraw()


## Fait passer `delta` secondes : la traîne attend, puis rejoint la part remplie.
func advance(delta: float) -> void:
	var left: float = delta
	if _wait > 0.0:
		var waited: float = minf(left, _wait)
		_wait -= waited
		left -= waited
	if left > 0.0 and trail_ratio > ratio:
		trail_ratio = maxf(trail_ratio - trail_speed * left, ratio)
		queue_redraw()


func _draw() -> void:
	var zone: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(zone, back_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * trail_ratio, size.y)), trail_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color)
	draw_rect(zone, border_color, false, 1.0)
