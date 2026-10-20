class_name InputDisplay extends Control
## Affichage des commandes de conduite, pour vérifier le clavier et la manette : jauges des gaz et de la
## direction (de -1 à 1), état du frein et du saut, manettes branchées. Il ne lit pas les entrées : la
## scène lui donne à chaque image les commandes déjà traduites (show_commands).

@onready var _throttle: ProgressBar = $Panel/Rows/Throttle
@onready var _steering: ProgressBar = $Panel/Rows/Steering
@onready var _buttons: Label = $Panel/Rows/Buttons
@onready var _pads: Label = $Panel/Rows/Pads


## Montre `commands` ; `pads` : les noms des manettes branchées.
func show_commands(commands: DriveCommands, pads: PackedStringArray) -> void:
	_throttle.value = commands.throttle
	_steering.value = commands.steering
	_buttons.text = "Frein : %s   Saut : %s" % [_yes_no(commands.brake), _yes_no(commands.jump_held)]
	_pads.text = "Aucune manette branchée" if pads.is_empty() else "Manette : " + ", ".join(pads)


func _yes_no(value: bool) -> String:
	return "oui" if value else "non"
