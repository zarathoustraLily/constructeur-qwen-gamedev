extends Step
## La boutique, l'intermède entre deux niveaux : offer_count améliorations tirées parmi upgrades, avec une graine
## et le rang du niveau (une même partie, une même boutique), présentées pour le joueur que GameFlow garde de côté.
## La première carte a le focus : la manette choisit comme la souris (croix, puis A). Le choix appliqué au joueur,
## l'étape finit, une seule fois.

## Les améliorations possibles (5_data/upgrades/).
@export var upgrades: Array[Upgrade] = []
## Nombre d'améliorations proposées.
@export var offer_count: int = 0
## La carte d'une amélioration (4_ui/components/upgrade_icon).
@export var icon_scene: PackedScene
## Graine du tirage, à laquelle s'ajoute le rang du niveau.
@export var random_seed: int = 0

var _player: Node
var _chosen: bool = false

@onready var _row: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer


func _ready() -> void:
	if icon_scene == null or upgrades.is_empty():
		push_error("Boutique : une dépendance manque (icon_scene, upgrades)")
		return
	_player = GameFlow.carried_player()
	var pool: Array[Upgrade] = upgrades.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed + GameState.level
	for _offer: int in mini(offer_count, pool.size()):
		var upgrade: Upgrade = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		var icon := icon_scene.instantiate() as UpgradeIcon
		_row.add_child(icon)
		icon.show_upgrade(upgrade, _player)
		icon.chosen.connect(_on_chosen)
	(_row.get_child(0) as UpgradeIcon).button.grab_focus.call_deferred()


## Les améliorations proposées, dans l'ordre des cartes.
func offers() -> Array[Upgrade]:
	var shown: Array[Upgrade] = []
	for icon: Node in _row.get_children():
		shown.append((icon as UpgradeIcon).upgrade)
	return shown


func _on_chosen(upgrade: Upgrade) -> void:
	if _chosen:
		return
	_chosen = true
	if _player != null:
		upgrade.apply(_player)
	finish()
