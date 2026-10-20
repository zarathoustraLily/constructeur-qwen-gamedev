class_name KartInput extends Node
## Adaptateur d'entrées du kart : le seul script du kart qui lit Input (règle ARC-04). Il traduit le
## clavier et la manette en commandes de conduite (DriveCommands), et fait vibrer la manette.
## Les actions et leurs zones mortes sont dans la carte des entrées du projet (project.godot, [input]) :
## gâchette droite, stick vers le haut ou W pour accélérer ; gâchette gauche, stick vers le bas ou S pour
## reculer ; stick gauche, croix ou A et D pour tourner ; bouton A ou Espace pour sauter ; bouton B ou
## Ctrl pour freiner. Les touches sont physiques : sur un clavier AZERTY, W et A sont Z et Q.

## Les commandes de la dernière lecture.
var commands: DriveCommands = DriveCommands.new()


## Lit les entrées de l'image et rend les commandes. Les gaz et le braquage passent par Input.get_vector :
## sous la zone morte, rien ; au-delà, la course restante est remise à l'échelle de 0 à 1.
func read() -> DriveCommands:
	var move: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	commands.steering = move.x
	commands.throttle = move.y
	commands.brake = Input.is_action_pressed("move_brake") \
		or Input.is_action_pressed("move_forward") and Input.is_action_pressed("move_backward")
	commands.jump = Input.is_action_just_pressed("move_jump")
	commands.jump_held = Input.is_action_pressed("move_jump")
	commands.jump_released = Input.is_action_just_released("move_jump")
#@ 13+
	commands.use_item = Input.is_action_just_pressed("use_item")
#@ all
	return commands


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
