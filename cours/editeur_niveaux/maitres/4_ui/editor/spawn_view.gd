class_name SpawnView
extends Control
## Le départ du héros et les points d'apparition, dessinés par-dessus la vue : le héros en vert, chaque point de la
## couleur de son rôle avec son initiale, le point choisi cerclé. Le calque laisse passer la souris à la vue ; il ne se
## montre qu'en mode « Apparitions ».

## La couleur de chaque rôle de point.
const ROLE_COLORS: Dictionary[String, Color] = {
	"melee": Color(0.95, 0.35, 0.3), "distance": Color(0.3, 0.55, 1.0), "tous": Color(0.75, 0.45, 0.95)}
## L'initiale affichée sur chaque rôle de point.
const ROLE_LETTERS: Dictionary[String, String] = {"melee": "C", "distance": "D", "tous": "T"}
## La couleur du départ du héros.
const HERO_COLOR: Color = Color(0.3, 0.9, 0.4)
## Le rayon d'un point, en pixels.
const RADIUS: float = 9.0

var _transform: ViewTransform
var _input: SpawnInput
var _document: RoomDocument


## Dessine les apparitions de `document`, au cadrage `transform`, avec le point choisi et l'aperçu de `input`.
func setup(document: RoomDocument, transform: ViewTransform, input: SpawnInput) -> void:
	_document = document
	_transform = transform
	_input = input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_document.changed.connect(queue_redraw)
	_transform.changed.connect(queue_redraw)
	_input.overlay_changed.connect(queue_redraw)


func _draw() -> void:
	if _document == null or not _document.is_open():
		return
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var hero: Vector2 = _transform.world_to_screen(_input.shown_hero())
	draw_circle(hero, RADIUS, HERO_COLOR)
	draw_string(font, hero + Vector2(-RADIUS / 2.0, RADIUS / 2.0), "H", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	if _input.chosen == SpawnInput.HERO:
		draw_arc(hero, RADIUS * 1.6, 0.0, TAU, 24, HERO_COLOR, 2.0)
	var roles: PackedStringArray = _document.room_value(&"spawn_roles")
	var points: PackedVector3Array = _input.shown_spawns()
	for index: int in points.size():
		var screen: Vector2 = _transform.world_to_screen(points[index])
		var role: String = roles[index] if index < roles.size() else "tous"
		var color: Color = ROLE_COLORS.get(role, Color.WHITE)
		draw_circle(screen, RADIUS, color)
		draw_string(font, screen + Vector2(-RADIUS / 2.0, RADIUS / 2.0), ROLE_LETTERS.get(role, "?"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if index == _input.chosen:
			draw_arc(screen, RADIUS * 1.6, 0.0, TAU, 24, color, 2.0)
