extends Node3D
## Le modèle commun des niveaux (level_template.tscn) : un sol et des murs en tuiles (GridMap) sur une région de
## navigation, le joueur, une vague d'ennemis (WaveObjective), une sortie (ExitPoint), la limite du monde sous le
## niveau, et l'éclairage global précalculé (VoxelGI). Chaque niveau en hérite et change ses grilles, sa
## navigation, son décor, ses trous, sa lumière et la place de la sortie.
## Le script fait le lien entre ces nœuds, qui ne se connaissent pas : il pose une barre de santé au-dessus de
## chaque personnage et envoie leurs dégâts à la couche des chiffres (DamageNumbers) ; vaincue, la vague ouvre la
## sortie. Vaincu, le joueur revient au départ avec toute sa santé ; la sortie atteinte, il y revient aussi et une
## vague du rang suivant commence : le chef d'orchestre, qui chargera le niveau suivant, n'est pas encore là.

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

## Rang du niveau en cours, à partir de 1 : il fixe la taille de la vague.
var level_rank: int = 1

var _player_start: Vector3

@onready var _player: Player = $Player
@onready var _damage_numbers: DamageNumbers = $DamageNumbers
@onready var _wave: WaveObjective = $WaveObjective
@onready var _exit: ExitPoint = $ExitPoint


func _ready() -> void:
	if health_bar_scene == null:
		push_error("Niveau : la scène de la barre de santé (health_bar_scene) manque")
		return
	_player_start = _player.global_position
	_player.health_component.defeated.connect(_respawn)
	_decorate(_player, _player.health_component, player_bar_color, player_bar_offset)
	_wave.enemy_spawned.connect(func(enemy: Enemy) -> void:
		_decorate(enemy, enemy.health_component, enemy_bar_color, enemy_bar_offset))
	_wave.cleared.connect(_exit.unlock)
	_exit.reached.connect(_on_exit_reached)
	_wave.start(level_rank)


# Vaincu, le joueur revient à son point de départ, visible et avec toute sa santé, et la caméra tremble.
func _respawn() -> void:
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_player.visible = true
	_player.health_component.restore()
	_player.camera.quick_shake(1.0)


# Pose une barre de santé au-dessus de `character` et envoie ses dégâts à la couche des chiffres.
func _decorate(character: Node3D, health: HealthComponent, color: Color, offset: Vector3) -> void:
	var bar := health_bar_scene.instantiate() as HealthBar
	bar.health_component = health
	bar.health_color = color
	bar.position = offset
	character.add_child(bar)
	health.damage_taken.connect(func(amount: float) -> void: _damage_numbers.show_damage(character.global_position, amount))


# La sortie atteinte : le joueur revient au départ, et une vague du rang suivant commence.
func _on_exit_reached() -> void:
	level_rank += 1
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_wave.start(level_rank)
