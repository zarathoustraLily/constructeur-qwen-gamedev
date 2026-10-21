#@ 11
extends Node3D
#@ 12+
extends Step
#@ all
## Le modèle commun des niveaux (level_template.tscn) : un sol et des murs en tuiles (GridMap) sur une région de
## navigation, le joueur, une vague d'ennemis (WaveObjective), une sortie (ExitPoint), la limite du monde sous le
## niveau, et l'éclairage global précalculé (VoxelGI). Chaque niveau en hérite et change ses grilles, sa
## navigation, son décor, ses trous, sa lumière et la place de la sortie.
## Le script fait le lien entre ces nœuds, qui ne se connaissent pas : il pose une barre de santé au-dessus de
## chaque personnage et envoie leurs dégâts à la couche des chiffres (DamageNumbers) ; vaincue, la vague ouvre la
## sortie.
#@ 11
## Vaincu, le joueur revient au départ avec toute sa santé ; la sortie atteinte, il y revient aussi et une
## vague du rang suivant commence : le chef d'orchestre, qui chargera le niveau suivant, n'est pas encore là.
#@ 12+
## Le niveau est une étape du déroulé (Step) : il ne charge jamais une autre scène. La sortie atteinte, il compte
## le niveau fini (GameState) et finit l'étape ; le chef d'orchestre (GameFlow) charge la suite. Vaincu, le joueur
## ramène le rang à 1 et le niveau demande à être rejoué (« retry »). Au départ, le niveau reprend le joueur que
## GameFlow a gardé de côté pendant le changement, avec ses améliorations, à la place du sien.
#@ all

## La barre de santé posée au-dessus de chaque personnage (4_ui/components/health_bar).
@export var health_bar_scene: PackedScene
## Couleur de la barre du joueur.
@export var player_bar_color: Color
## Place de la barre du joueur, par rapport à son centre.
@export var player_bar_offset: Vector3
## Couleur de la barre des ennemis.
@export var enemy_bar_color: Color
## Place de la barre des ennemis, par rapport à leur centre.
@export var enemy_bar_offset: Vector3

#@ 11
## Rang du niveau en cours, à partir de 1 : il fixe la taille de la vague.
var level_rank: int = 1

var _player_start: Vector3

@onready var _player: Player = $Player
#@ 12+
var _player: Player

#@ all
@onready var _damage_numbers: DamageNumbers = $DamageNumbers
@onready var _wave: WaveObjective = $WaveObjective
@onready var _exit: ExitPoint = $ExitPoint


func _ready() -> void:
	if health_bar_scene == null:
		push_error("Niveau : la scène de la barre de santé (health_bar_scene) manque")
		return
#@ 11
	_player_start = _player.global_position
	_player.health_component.defeated.connect(_respawn)
#@ 12+
	_player = _adopt_player()
	_player.health_component.defeated.connect(_on_player_defeated)
#@ all
	_decorate(_player, _player.health_component, player_bar_color, player_bar_offset)
	_wave.enemy_spawned.connect(func(enemy: Enemy) -> void:
		_decorate(enemy, enemy.health_component, enemy_bar_color, enemy_bar_offset))
	_wave.cleared.connect(_exit.unlock)
	_exit.reached.connect(_on_exit_reached)
#@ 11
	_wave.start(level_rank)
#@ 12+
	_wave.start(GameState.level)
#@ all


#@ 11
# Vaincu, le joueur revient à son point de départ, visible et avec toute sa santé, et la caméra tremble.
func _respawn() -> void:
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_player.visible = true
	_player.health_component.restore()
	_player.camera.quick_shake(1.0)
#@ 12+


# Le joueur gardé de côté par GameFlow prend la place de celui de la scène, au même endroit ; sinon, celui de la
# scène. Rend le joueur du niveau.
func _adopt_player() -> Player:
	var own := $Player as Player
	var carried := GameFlow.take_player() as Player
	if carried == null:
		return own
	carried.transform = own.transform
	# Hors de l'arbre, il peut partir tout de suite ; queue_free() le laisserait orphelin jusqu'à la fin de l'image.
	remove_child(own)
	own.free()
	carried.name = &"Player"
	add_child(carried)
	carried.process_mode = Node.PROCESS_MODE_INHERIT
	return carried


# Vaincu : retour au premier rang, et le niveau est rejoué depuis le début.
func _on_player_defeated() -> void:
	GameState.reset()
	finish(&"retry")
#@ all


# Pose une barre de santé au-dessus de `character` et envoie ses dégâts à la couche des chiffres.
func _decorate(character: Node3D, health: HealthComponent, color: Color, offset: Vector3) -> void:
#@ 12+
	# Le joueur repris d'un autre niveau a déjà sa barre.
	if not character.find_children("*", "HealthBar", false, false).is_empty():
		health.damage_taken.connect(_show_damage.bind(character))
		return
#@ all
	var bar := health_bar_scene.instantiate() as HealthBar
	bar.health_component = health
	bar.health_color = color
	bar.position = offset
	character.add_child(bar)
#@ 11
	health.damage_taken.connect(func(amount: float) -> void: _damage_numbers.show_damage(character.global_position, amount))
#@ 12+
	# Une méthode du niveau, et non une fonction anonyme : quand le niveau est libéré, Godot coupe la connexion, et
	# le joueur repris dans le niveau suivant ne parle plus à l'ancien.
	health.damage_taken.connect(_show_damage.bind(character))


func _show_damage(amount: float, character: Node3D) -> void:
	_damage_numbers.show_damage(character.global_position, amount)
#@ all


#@ 11
# La sortie atteinte : le joueur revient au départ, et une vague du rang suivant commence.
func _on_exit_reached() -> void:
	level_rank += 1
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_wave.start(level_rank)
#@ 12+
# La sortie atteinte : un niveau de plus est fini, et l'étape aussi.
func _on_exit_reached() -> void:
	GameState.finish_level()
	finish()
#@ all
