extends Node3D
#@ 1
## Scène principale. À chaque image physique, l'adaptateur d'entrées du kart (KartInput) traduit le clavier
## et la manette en commandes de conduite, et l'affichage (InputDisplay) les montre ; un saut fait vibrer la
## manette (jump_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.
#@ 2-3
## Scène principale : une aire d'essai (un sol, une rampe) et le kart. À chaque image physique, l'affichage
## (InputDisplay) montre les commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer
## la manette (jump_rumble). La scène fait le lien : le kart et l'affichage ne se connaissent pas.
#@ 4-5
## Scène principale : l'île et le kart. À chaque image physique, l'affichage (InputDisplay) montre les
## commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette (jump_rumble).
## La scène fait le lien : le kart et l'affichage ne se connaissent pas.
#@ 6+
## Scène principale : l'île et le kart. À chaque image physique, l'affichage (InputDisplay) montre les
## commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette (jump_rumble) ;
## la position du kart est recopiée dans GameState.player_position, que GameState passe au paramètre global
## de shader du même nom : l'herbe le lit pour s'écarter sous le kart. La scène fait le lien : le kart,
## l'affichage et les shaders ne se connaissent pas.
#@ all

## Vibration jouée à chaque saut (5_data/input/jump_rumble.tres).
@export var jump_rumble: Rumble

#@ 1
@onready var _input: KartInput = $KartInput
#@ 2+
@onready var _kart: Kart = $Kart
#@ all
@onready var _display: InputDisplay = $InputDisplay


func _ready() -> void:
	if jump_rumble == null:
		push_error("Main : la vibration du saut (jump_rumble) manque")
#@ 2+
	_kart.jumped.connect(_on_kart_jumped)
#@ all


func _physics_process(_delta: float) -> void:
#@ 1
	var commands := _input.read()
	if commands.jump and jump_rumble != null:
		_input.vibrate(jump_rumble)
	_display.show_commands(commands, _input.joypad_names())
#@ 2+
	# Un kart piloté par un script n'a pas d'adaptateur d'entrées : pas de manette à montrer.
	var pads := _kart.input.joypad_names() if _kart.input != null else PackedStringArray()
	_display.show_commands(_kart.commands, pads)
#@ 6+
	GameState.player_position = _kart.global_position
#@ 2+


func _on_kart_jumped() -> void:
	if jump_rumble != null and _kart.input != null:
		_kart.input.vibrate(jump_rumble)
#@ all
