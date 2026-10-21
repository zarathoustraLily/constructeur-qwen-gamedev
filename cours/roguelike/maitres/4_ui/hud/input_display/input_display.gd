class_name InputDisplay extends Control
## Affichage des commandes du joueur, pour vérifier le clavier, la souris et la manette : jauges du
## déplacement (de -1 à 1 sur chaque axe), direction de la visée, nombre de coups et d'esquives demandés,
## appareil en cours et manettes branchées. Il ne lit pas les entrées : la scène lui donne à chaque image les
## commandes déjà traduites (show_commands).

## Coups demandés depuis le lancement.
var attacks: int = 0
## Esquives demandées depuis le lancement.
var dashes: int = 0

@onready var _move_x: ProgressBar = $Panel/Rows/MoveX
@onready var _move_y: ProgressBar = $Panel/Rows/MoveY
@onready var _aim: Label = $Panel/Rows/Aim
@onready var _buttons: Label = $Panel/Rows/Buttons
@onready var _device: Label = $Panel/Rows/Device
@onready var _pads: Label = $Panel/Rows/Pads


## Montre `commands` ; `pads` : les noms des manettes branchées.
func show_commands(commands: PlayerCommands, pads: PackedStringArray) -> void:
	_move_x.value = commands.move.x
	_move_y.value = commands.move.y
	if commands.aim.is_zero_approx():
		_aim.text = "Visée : aucune (vers la marche)"
	else:
		_aim.text = "Visée : %d°" % roundi(rad_to_deg(commands.aim.angle()))
	if commands.attack:
		attacks += 1
	if commands.dash:
		dashes += 1
	_buttons.text = "Coups : %d   Esquives : %d" % [attacks, dashes]
	_device.text = "Appareil : manette" if commands.from_pad else "Appareil : clavier et souris"
	_pads.text = "Aucune manette branchée" if pads.is_empty() else "Manette : " + ", ".join(pads)
