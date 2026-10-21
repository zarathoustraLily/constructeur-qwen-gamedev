class_name PlayerInput extends Node
## Adaptateur d'entrées du joueur : le seul script du joueur qui lit Input (règle ARC-04). Il traduit le
## clavier, la souris et la manette en commandes (PlayerCommands), et fait vibrer la manette.
## Les actions et leurs zones mortes sont dans la carte des entrées du projet (project.godot, [input]) :
## stick gauche, croix ou W A S D pour marcher ; stick droit pour viser ; clic gauche, bouton X ou gâchette
## droite pour frapper ; Espace, bouton A ou gâchette gauche pour esquiver. Les touches sont physiques : sur un
## clavier AZERTY, W et A sont Z et Q.
## La visée suit le dernier appareil touché : à la souris, du personnage vers le pointeur ; à la manette, le
## stick droit, et au repos, aucune visée (le joueur frappe vers où il marche). Tant que la souris n'a pas bougé
## sur la fenêtre, elle ne vise pas : une fenêtre hors de l'écran, ou une souris oubliée sur le bureau, ne doit
## pas viser au hasard (et une partie rejouée vise pareil).

## Au-delà de cette inclinaison, un stick fait passer la visée à la manette ; en deçà, c'est du bruit.
const PAD_MOTION_THRESHOLD := 0.5

## Le personnage d'où part la visée à la souris : sa position à l'écran.
@export var body: Node3D

## Les commandes de la dernière lecture.
var commands: PlayerCommands = PlayerCommands.new()

var _from_pad: bool = false
var _mouse_seen: bool = false


func _ready() -> void:
	if body == null:
		push_error("PlayerInput : le personnage (body) manque")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_from_pad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > PAD_MOTION_THRESHOLD:
			_from_pad = true
	elif event is InputEventMouse or event is InputEventKey:
		_from_pad = false
		# Seul compte un vrai déplacement : au démarrage, Godot envoie un mouvement sans déplacement (relative nul).
		var motion := event as InputEventMouseMotion
		if motion != null and not motion.relative.is_zero_approx():
			_mouse_seen = true


## Lit les entrées de l'image et rend les commandes. Le déplacement et la visée au stick passent par
## Input.get_vector : sous la zone morte, rien ; au-delà, la course restante est remise à l'échelle de 0 à 1.
func read() -> PlayerCommands:
	commands.move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	commands.attack = Input.is_action_just_pressed("attack")
	commands.dash = Input.is_action_just_pressed("dash")
	commands.from_pad = _from_pad
	if _from_pad:
		commands.aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	elif _mouse_seen:
		commands.aim = aim_from_mouse(get_viewport().get_mouse_position())
	else:
		commands.aim = Vector2.ZERO
	return commands


## Visée à la souris pour un pointeur en `mouse_position` (pixels) : du personnage, vu par la caméra active,
## vers le pointeur. Nulle sans caméra ni personnage.
func aim_from_mouse(mouse_position: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or body == null:
		return Vector2.ZERO
	return mouse_position - camera.unproject_position(body.global_position)


## Fait vibrer chaque manette branchée selon `rumble` ; sans manette, rien.
func vibrate(rumble: Rumble) -> void:
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, rumble.weak_magnitude, rumble.strong_magnitude, rumble.duration)


## Noms des manettes branchées, dans l'ordre de leurs numéros.
func joypad_names() -> PackedStringArray:
	var names := PackedStringArray()
	for device: int in Input.get_connected_joypads():
		names.append(Input.get_joy_name(device))
	return names
