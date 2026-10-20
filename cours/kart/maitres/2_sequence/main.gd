extends Node3D
## Scène principale. À chaque image physique, l'adaptateur d'entrées du kart (KartInput) traduit le clavier
## et la manette en commandes de conduite, et l'affichage (InputDisplay) les montre ; un saut fait vibrer la
## manette (jump_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.

## Vibration jouée à chaque saut (5_data/input/jump_rumble.tres).
@export var jump_rumble: Rumble

@onready var _input: KartInput = $KartInput
@onready var _display: InputDisplay = $InputDisplay


func _ready() -> void:
	if jump_rumble == null:
		push_error("Main : la vibration du saut (jump_rumble) manque")


func _physics_process(_delta: float) -> void:
	var commands := _input.read()
	if commands.jump and jump_rumble != null:
		_input.vibrate(jump_rumble)
	_display.show_commands(commands, _input.joypad_names())
