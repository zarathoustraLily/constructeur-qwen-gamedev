class_name UpgradeIcon extends PanelContainer
## La carte d'une amélioration dans la boutique : son titre, sa description (la valeur actuelle du joueur, puis la
## valeur après) et un bouton qui couvre la carte. Elle ne modifie rien : un clic, ou A à la manette quand elle a
## le focus, émet chosen, et la boutique applique l'amélioration. Avec le focus, la carte s'éclaire : à la manette,
## on voit laquelle on va prendre.

## Émis quand le joueur choisit cette amélioration.
signal chosen(upgrade: Upgrade)

## L'amélioration montrée.
var upgrade: Upgrade

@onready var button: TextureButton = $TextureButton
@onready var _title: RichTextLabel = $VBoxContainer/Title
@onready var _description: RichTextLabel = $VBoxContainer/Control/Description


func _ready() -> void:
	button.pressed.connect(func() -> void: chosen.emit(upgrade))
	button.focus_entered.connect(func() -> void: modulate = Color(1.4, 1.4, 1.4))
	button.focus_exited.connect(func() -> void: modulate = Color.WHITE)


## Montre `new_upgrade`, avec les valeurs de `target` (le joueur ; null : le seul bonus).
func show_upgrade(new_upgrade: Upgrade, target: Node) -> void:
	upgrade = new_upgrade
	_title.text = "[wave]%s[/wave]" % upgrade.title
	_description.text = upgrade.describe(target)
