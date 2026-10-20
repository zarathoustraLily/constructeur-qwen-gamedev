extends Node3D
## Caméra du joueur, en orbite autour du kart : la souris ou le stick droit font regarder autour ; sans
## action pendant `camera_reset_delay` secondes, elle revient derrière le kart en mouvement. Sous l'eau,
## elle passe à l'environnement sous-marin.

## Kart suivi.
@export var kart : Kart
## Caméra pilotée.
@export var camera : Camera3D
## Sensibilité de la souris.
@export var look_sensitivity : float = 0.1
## Environnement utilisé quand la caméra passe sous l'eau.
@export var under_water_environment : Environment
## Vrai quand la souris est capturée et pilote la caméra.
var input_active : bool = false
## Délai (s) sans action avant que la caméra revienne derrière le kart.
@export var camera_reset_delay : float = 2.5
## Vitesse de rotation au stick droit, en radians/seconde stick à fond
@export var stick_look_speed : float = 2.5
## Zone morte du stick droit.
const STICK_DEADZONE := 0.2
var _camera_reset_cooldown : float = 0
## Océan de la scène, lu pour savoir si la caméra est sous l'eau.
var ocean_node : Ocean
## Vrai quand la caméra est sous la surface.
var is_under_water : bool = false

## Capture la souris (`value` vrai) pour piloter la caméra, ou la libère.
func set_mouse(value: bool) -> void:
	input_active = value;
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if input_active else Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	if !ocean_node:
		ocean_node = get_tree().get_first_node_in_group("ocean")

	set_mouse(true);
	#set_mouse(false);
			#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _input(event: InputEvent) -> void:
	var mouvement := event as InputEventMouseMotion
	if mouvement and input_active:
		rotation.y += -mouvement.relative.x * 0.025 * look_sensitivity;
		rotation.x += -mouvement.relative.y * 0.025 * look_sensitivity;
		rotation.x = clamp(rotation.x, -0.4 * PI, 0.4 * PI)
		_camera_reset_cooldown = camera_reset_delay
		
		
func _process(delta: float) -> void:	
	if ocean_node:
		var pos: Vector3 = camera.global_position;
		var water_level: float = ocean_node.get_wave_height(pos, 2, 2)
		var under_water : bool = pos.y < water_level
		if is_under_water != under_water:
			if under_water:
				camera.environment = under_water_environment
			else:
				camera.environment = null
			
		is_under_water = under_water
	
	if input_active:
		var stick := _get_look_stick()
		if stick != Vector2.ZERO:
			rotation.y += -stick.x * stick_look_speed * delta
			rotation.x += -stick.y * stick_look_speed * delta
			rotation.x = clamp(rotation.x, -0.4 * PI, 0.4 * PI)
			_camera_reset_cooldown = camera_reset_delay

	_camera_reset_cooldown -= delta
	if _camera_reset_cooldown < 0 && kart.velocity.length() > 1.0:
		var wish_basis := kart.global_basis
		var t: float = 1 -pow(0.3, 2 * delta)
		global_basis = global_basis.orthonormalized().slerp(wish_basis.orthonormalized(), t)

# Lu à chaque frame : un stick maintenu immobile n'envoie plus d'événements,
# donc le gérer dans _input ne faisait tourner la caméra que pendant que le stick bougeait.
func _get_look_stick() -> Vector2:
	for device in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
		if stick.length() > STICK_DEADZONE:
			return stick
	return Vector2.ZERO
