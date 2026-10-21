class_name PauseMenu extends CanvasLayer
## Le menu de pause : la pause (Échap, ou Start à la manette) fige le jeu et l'ouvre ; une seconde fois, elle le
## ferme. On y reprend la partie, on ouvre le menu des contrôles, ou on quitte le jeu. Le menu tourne pendant la
## pause (process_mode ALWAYS, posé dans la scène) ; le jeu est figé (SceneTree.paused). B ou Échap reviennent en
## arrière : du menu des contrôles à la pause, de la pause à la partie. Chaque niveau en porte un, et lui donne
## les réglages des liaisons.

## Les actions qu'on peut lier et leur fichier de sauvegarde (5_data/input/bindings.tres), posés par le niveau.
@export var bindings: BindingSettings

@onready var _screen: Control = $Screen
@onready var _panel: Control = $Screen/Panel
@onready var _resume: Button = $Screen/Panel/VBoxContainer/Resume
@onready var _controls: Button = $Screen/Panel/VBoxContainer/Controls
@onready var _quit: Button = $Screen/Panel/VBoxContainer/Quit
@onready var _remap: InputRemapMenu = $Screen/InputRemapMenu


func _ready() -> void:
	_screen.hide()
	if bindings == null:
		push_error("PauseMenu : les réglages des liaisons (bindings) ne sont pas posés")
		return
	_remap.setup(bindings)
	_resume.pressed.connect(resume)
	_controls.pressed.connect(_open_controls)
	_quit.pressed.connect(func() -> void: get_tree().quit())
	_remap.closed.connect(_on_remap_closed)


# Le menu des contrôles, un enfant, voit chaque entrée avant ce script et garde celles dont il se sert.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if is_open():
			resume()
		else:
			pause()
	elif is_open() and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		resume()


## Vrai quand le menu est ouvert, et le jeu figé.
func is_open() -> bool:
	return _screen.visible


## Fige le jeu et ouvre le menu, le focus sur « Reprendre » : la manette choisit comme la souris.
func pause() -> void:
	get_tree().paused = true
	_screen.show()
	_panel.show()
	_remap.hide()
	_resume.grab_focus()


## Ferme le menu et relance le jeu.
func resume() -> void:
	_screen.hide()
	get_tree().paused = false


func _open_controls() -> void:
	_panel.hide()
	_remap.open()


func _on_remap_closed() -> void:
	_panel.show()
	_controls.grab_focus()
