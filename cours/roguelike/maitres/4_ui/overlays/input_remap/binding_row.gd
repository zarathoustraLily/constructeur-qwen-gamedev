class_name BindingRow extends HBoxContainer
## Une ligne du menu des contrôles : le nom d'une action, puis deux boutons qui montrent ses liaisons, au clavier et
## à la souris, puis à la manette. Appuyer sur un bouton demande une nouvelle liaison pour cet appareil ; la ligne
## ne lie rien elle-même : le menu écoute capture_requested.

## Émis quand le joueur demande une nouvelle liaison de `bound_action` pour `device`.
signal capture_requested(bound_action: StringName, device: InputBindings.Device)

## L'action de la ligne.
var action: StringName

@onready var keyboard: Button = $Keyboard
@onready var pad: Button = $Pad
@onready var _title: Label = $Title


func _ready() -> void:
	keyboard.pressed.connect(func() -> void: capture_requested.emit(action, InputBindings.Device.KEYBOARD))
	pad.pressed.connect(func() -> void: capture_requested.emit(action, InputBindings.Device.PAD))


## Montre `new_action`, sous le nom `title`, avec ses liaisons actuelles.
func show_action(new_action: StringName, title: String) -> void:
	action = new_action
	_title.text = title
	refresh()


## Remet aux deux boutons les liaisons actuelles de l'action.
func refresh() -> void:
	keyboard.text = BindingNames.of_all(InputBindings.events_for(action, InputBindings.Device.KEYBOARD))
	pad.text = BindingNames.of_all(InputBindings.events_for(action, InputBindings.Device.PAD))


## Le bouton de `device`.
func button_for(device: InputBindings.Device) -> Button:
	return pad if device == InputBindings.Device.PAD else keyboard
