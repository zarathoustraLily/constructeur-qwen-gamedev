class_name LevelBase
extends Step
## Base de tous les niveaux : l'orchestrateur local du combat (ARC-10). Un niveau hérite de
## level_base.tscn et pose à la main ses ennemis sous World/Enemies et son décor sous World.
## Il fournit à chaque acteur ce dont il a besoin (cible, projectiles, effets : ARC-06), écoute leur
## vie et décide de la suite par appels directs : points, fin du niveau (SIM-07).
## Dépend de : rules, budget, projectiles et effet posés dans la scène ; GameState, Trace.

@export var rules: GameRules
@export var budget: LevelBudget
@export var player_projectile: PackedScene
@export var enemy_projectile: PackedScene
@export var hit_effect: PackedScene

var _ending: bool = false

@onready var player: Player = $World/Player
@onready var projectiles: Node3D = $World/Projectiles
@onready var effects: Node3D = $World/Effects
@onready var hud: Hud = $Hud


func _ready() -> void:
	if rules == null or player_projectile == null or enemy_projectile == null:
		push_error("LevelBase %s : rules, player_projectile ou enemy_projectile n'est pas posé" % name)
		return
	player.setup(player_projectile, projectiles)
	player.health.damaged.connect(func(_amount: int, current: int) -> void: hud.show_health(current))
	player.health.died.connect(_on_player_died)
	hud.show_health(player.health.current_health)
	for node in enemies():
		var drone := node as Drone
		if drone != null:
			drone.setup(player, enemy_projectile, projectiles, effects, hit_effect)
			drone.health.died.connect(_on_enemy_died.bind(drone))


## Les ennemis posés dans ce niveau (groupe « enemies »), morts compris jusqu'à leur disparition.
func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"enemies").filter(func(n: Node) -> bool: return is_ancestor_of(n))


## Les ennemis encore en vie.
func alive_enemies() -> Array[Node]:
	return enemies().filter(func(n: Node) -> bool:
		var health := n.get_node_or_null(^"Health") as HealthComponent
		return health != null and not health.is_dead())


func _on_enemy_died(drone: Drone) -> void:
	GameState.add_score(drone.stats.score_value)
	Trace.event(drone, "détruit, score +%d" % drone.stats.score_value)
	if alive_enemies().is_empty():
		_end(&"done")


func _on_player_died() -> void:
	player.set_physics_process(false)
	Trace.event(player, "joueur mort")
	_end(&"retry" if GameState.lose_life() else &"restart")


func _end(outcome: StringName) -> void:
	if _ending:
		return
	_ending = true
	Trace.event(self, "fin du niveau : %s" % outcome)
	# false : le délai s'arrête pendant la pause (SIM-08).
	get_tree().create_timer(rules.level_end_delay, false).timeout.connect(finish.bind(outcome))
