class_name LevelBase
extends Step
## Base de tous les niveaux. Un niveau hérite de level_base.tscn et pose à la main, dans
## l'éditeur, ses ennemis sous World/Enemies et son décor sous World. Le code lit ce qui est posé :
## le niveau est fini quand plus aucun nœud du groupe « enemies » ne vit.

## Délai avant de passer à la suite (victoire) ou de rejouer (défaite).
const END_DELAY := 1.5

@export var budget: LevelBudget

var _ending: bool = false

@onready var player: Player = $World/Player
@onready var projectiles: Node3D = $World/Projectiles
@onready var hud: Hud = $Hud


func _ready() -> void:
	player.weapon.projectile_parent = projectiles
	for enemy in enemies():
		var weapon := enemy.get_node_or_null(^"Weapon") as WeaponComponent
		if weapon != null:
			weapon.projectile_parent = projectiles
	hud.show_health(player.health.current_health)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)


func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(n: Node) -> bool: return is_ancestor_of(n))


func _on_enemy_killed(_enemy: Node3D, _points: int) -> void:
	if enemies().is_empty():
		_end(&"done")


func _on_player_died() -> void:
	player.set_physics_process(false)
	_end(&"retry" if GameState.lose_life() else &"restart")


func _end(outcome: StringName) -> void:
	if _ending:
		return
	_ending = true
	Trace.event(self, "fin du niveau : %s" % outcome)
	get_tree().create_timer(END_DELAY).timeout.connect(finish.bind(outcome))
