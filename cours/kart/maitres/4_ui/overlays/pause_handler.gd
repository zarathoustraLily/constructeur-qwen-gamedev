extends Node

## Gère l'ouverture du menu de re-mapping (F1 / Start) et la sortie du jeu (Échap).
## À placer comme child de la scène principale (main.tscn).

@onready var _remap_menu: InputRemapMenu = $InputRemapMenu

func _ready() -> void:
	# Le menu met le jeu en pause : ce node doit continuer à recevoir F1 / Start / Échap.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not _remap_menu:
		return

	# F1 : ouvre / ferme le menu (annule la capture en cours si besoin)
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_F1 or event.physical_keycode == KEY_F1):
		_toggle_or_cancel()
		get_viewport().set_input_as_handled()
		return

	# Start (manette) : ouvre / ferme le menu, ou annule la capture en cours
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		_toggle_or_cancel()
		get_viewport().set_input_as_handled()
		return

	# B (manette) : ferme le menu (pendant une capture, B est assigné par le menu avant d'arriver ici)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		if _remap_menu.is_open() and not _remap_menu.is_capturing():
			_remap_menu.close()
			get_viewport().set_input_as_handled()
		return

	# Échap : annule la capture, sinon ferme le menu, sinon quitte le jeu
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		if _remap_menu.is_capturing():
			_remap_menu._cancel_binding()
		elif _remap_menu.is_open():
			_remap_menu.close()
		else:
			GameFlow.quitter()
		get_viewport().set_input_as_handled()

func _toggle_or_cancel() -> void:
	if _remap_menu.is_capturing():
		_remap_menu._cancel_binding()
	else:
		_remap_menu.toggle()
