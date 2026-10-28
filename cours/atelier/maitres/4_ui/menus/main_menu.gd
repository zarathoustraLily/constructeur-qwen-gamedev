class_name MainMenu extends Control
#@ 1
## Le menu principal : Jouer, Options, Quitter. Il se pilote à la souris, au clavier et à la manette (croix ou
#@ 2+
## Le menu principal : Jouer, Options, Commandes, Quitter. Il se pilote à la souris, au clavier et à la manette (croix ou
#@ all
## stick pour choisir, A pour valider) ; le focus boucle du dernier bouton au premier. Il ne décide rien : il dit
## ce que le joueur demande, et la scène principale agit.

## Le joueur veut lancer la partie.
signal start_requested
## Le joueur veut ouvrir les options.
signal options_requested
#@ 2+
## Le joueur veut remapper les boutons de la manette.
signal controls_requested
#@ all
## Le joueur veut quitter le jeu.
signal quit_requested

@onready var _play: Button = $Center/Buttons/Play
@onready var _options: Button = $Center/Buttons/Options
#@ 2+
@onready var _controls: Button = $Center/Buttons/Controls
#@ all
@onready var _quit: Button = $Center/Buttons/Quit


func _ready() -> void:
	_play.pressed.connect(func() -> void: start_requested.emit())
	_options.pressed.connect(func() -> void: options_requested.emit())
#@ 2+
	_controls.pressed.connect(func() -> void: controls_requested.emit())
#@ all
	_quit.pressed.connect(func() -> void: quit_requested.emit())
	MenuFocus.chain(buttons(), true)


## Les boutons du menu, de haut en bas.
func buttons() -> Array[Control]:
#@ 1
	return [_play, _options, _quit]
#@ 2+
	return [_play, _options, _controls, _quit]
#@ all


## Montre le menu et donne le focus au premier bouton utilisable : sans focus, la manette ne peut rien choisir.
func open() -> void:
	show()
	var first: Control = MenuFocus.first_focusable(buttons())
	if first != null:
		first.grab_focus()
