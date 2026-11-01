extends Control
## Un barrage qui cède, à l'écran : chaque particule d'eau est un point sur une image. L'écran ne calcule rien lui-même.

## Les réglages de l'eau.
@export var settings: FlipSettings
## La couleur d'une particule, selon sa vitesse.
@export var calm_color: Color = Color(0.1, 0.35, 0.8)
## La couleur d'une particule rapide.
@export var fast_color: Color = Color(0.8, 0.95, 1.0)
## La vitesse qui donne `fast_color`, en cases par seconde.
@export_range(1.0, 100.0, 0.5) var fast_speed: float = 30.0

## Le côté d'une case à l'écran, en pixels de l'image.
const CELL := 4

var _solver: FlipSolver
var _image: Image
@onready var _view: TextureRect = $View


func _ready() -> void:
	_solver = FlipSolver.new(settings)
	_solver.add_block(Vector2(0.0, settings.height * 0.2), Vector2(settings.width * 0.4, settings.height - 1.0), 0.5)
	_image = Image.create(settings.width * CELL, settings.height * CELL, false, Image.FORMAT_RGB8)
	_view.texture = ImageTexture.create_from_image(_image)


func _physics_process(delta: float) -> void:
	_solver.step(delta)
	_paint()
	(_view.texture as ImageTexture).update(_image)


## Redessine l'image : un point par particule, plus clair si elle va vite.
func _paint() -> void:
	_image.fill(Color.BLACK)
	for i: int in _solver.positions.size():
		var pixel: Vector2i = Vector2i(((_solver.positions[i] + Vector2(0.5, 0.5)) * CELL).floor())
		var color: Color = calm_color.lerp(fast_color, minf(_solver.velocities[i].length() / fast_speed, 1.0))
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < _image.get_width() and pixel.y < _image.get_height():
			_image.set_pixelv(pixel, color)
