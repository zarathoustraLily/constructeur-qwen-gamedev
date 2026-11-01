extends Control
## L'écran de démonstration : il montre le fluide dans une image. Il ne calcule rien lui-même.
#@ 5+
## Une source verse de la matière et pousse le fluide, à chaque image ; le clic le pousse à la souris.
#@ all

#@ 5+
## Les réglages du fluide.
@export var settings: FluidSettings
#@ 10+
## Les réglages du feu.
@export var fire: FireSettings
## Du noir au blanc, en passant par le rouge : les couleurs de la température.
@export var ramp: Gradient
#@ 5+
#@ all

#@ 1-4
var _field: FluidField
#@ 5+
var _solver: FluidSolver
#@ all
@onready var _view: TextureRect = $View


func _ready() -> void:
#@ 1-4
	_field = FluidField.new(64, 64)
	_field.add_disc(32.0, 32.0, 16.0, 1.0)
	_view.texture = ImageTexture.create_from_image(FluidImage.gray(_field, 1.0))
#@ 5+
	_solver = FluidSolver.new(settings)
#@ 6-9
	_solver.walls.add_box(24, 20, 40, 22)
#@ 10+
	_solver.fire = fire
#@ 5+
	_view.texture = ImageTexture.create_from_image(_shown())
#@ all
#@ 5+


func _physics_process(delta: float) -> void:
	var middle: float = settings.width * 0.5
	var bottom: float = settings.height - 6.0
#@ 5-9
	_solver.density.add_disc(middle, bottom, 5.0, 30.0 * delta)
	_solver.add_force(middle, bottom, 5.0, 0.0, -40.0 * delta)
#@ 10+
	_solver.fuel.add_disc(middle, bottom, 6.0, 40.0 * delta)
	_solver.temperature.add_disc(middle, bottom, 6.0, 6.0 * delta)
#@ 5+
	_solver.step(delta)
	(_view.texture as ImageTexture).update(_shown())


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or motion.button_mask == 0:
		return
	var scale_x: float = settings.width / _view.size.x
	var scale_y: float = settings.height / _view.size.y
	_solver.add_force(motion.position.x * scale_x, motion.position.y * scale_y, 6.0, motion.relative.x, motion.relative.y)


## L'image du fluide.
func _shown() -> Image:
#@ 5-9
	return FluidImage.gray(_solver.density, 1.0)
#@ 10+
	return FluidImage.colored(_solver.temperature, ramp, 3.0)
#@ all
