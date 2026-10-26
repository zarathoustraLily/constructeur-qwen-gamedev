class_name GameOverMenu
extends CanvasLayer
## Menu de fin de partie, jouable à la manette : à l'ouverture, le premier bouton prend le focus ; la croix et le
## stick le déplacent (ui_up, ui_down), A ou Entrée valide (ui_accept). Il ne décide de rien : il émet un signal par
## choix, le déroulé (2_sequence/) y répond. Entrées : open().

signal retry_requested
signal menu_requested
signal quit_requested

@onready var retry_button: Button = $Center/Box/Retry
@onready var menu_button: Button = $Center/Box/Menu
@onready var quit_button: Button = $Center/Box/Quit


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(retry_requested.emit)
	menu_button.pressed.connect(menu_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)


func open() -> void:
	visible = true
	retry_button.grab_focus()  # sans focus, la manette ne peut rien choisir
