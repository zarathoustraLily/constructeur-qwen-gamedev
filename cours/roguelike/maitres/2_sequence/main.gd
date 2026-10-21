extends Node3D
#@ 1
## Scène principale. À chaque image physique, l'adaptateur d'entrées (PlayerInput) traduit le clavier, la
## souris et la manette en commandes, et l'affichage (InputDisplay) les montre ; la flèche au pied du
## personnage montre la visée (à défaut, la marche), tournée selon la caméra ; un coup fait vibrer la manette
## (attack_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.
#@ 2-3
## Scène principale : le joueur sur une estrade, au milieu d'un grand sol. À chaque image physique, la scène
## montre les commandes du joueur (InputDisplay), et un coup fait vibrer la manette (attack_rumble). La scène
## fait le lien : le joueur et l'affichage ne se connaissent pas.
#@ 4+
## Scène principale : le niveau de test du jeu d'origine, en tuiles (GridMap), avec un trou ; sous le niveau, la
#@ 4-5
## limite du monde (WorldBoundary). Le joueur qui y tombe revient à son point de départ, et sa caméra tremble.
#@ 6+
## limite du monde (WorldBoundary), qui vide la santé de qui y tombe. Vaincu, le joueur revient à son point de
## départ avec toute sa santé, et sa caméra tremble : pas encore de chef d'orchestre pour recharger le niveau.
#@ 7
## Deux ennemis au corps à corps l'y attendent ; ils suivent la navigation du niveau (NavigationRegion3D, son
## maillage de navigation précalculé).
#@ 8+
## Deux ennemis au corps à corps et un ennemi à distance l'y attendent ; ils suivent la navigation du niveau
## (NavigationRegion3D, son maillage de navigation précalculé).
#@ 4+
## À chaque image physique, la scène montre les commandes du joueur (InputDisplay), et un coup fait vibrer la
## manette (attack_rumble). La scène fait le lien : le joueur, la limite et l'affichage ne se connaissent pas.
#@ all

## Vibration jouée à chaque coup (5_data/input/attack_rumble.tres).
@export var attack_rumble: Rumble

#@ 1
@onready var _input: PlayerInput = $PlayerInput
#@ 2+
@onready var _player: Player = $Player
#@ 4-5
@onready var _boundary: WorldBoundary = $WorldBoundary
#@ all
@onready var _display: InputDisplay = $InputDisplay
#@ 1
@onready var _aim_pivot: Node3D = $Hero/AimPivot
@onready var _camera: Camera3D = $Hero/CameraRoot/Camera3D
#@ 4+

var _player_start: Vector3
#@ all


func _ready() -> void:
	if attack_rumble == null:
		push_error("Main : la vibration du coup (attack_rumble) manque")
#@ 4+
	_player_start = _player.global_position
#@ 4-5
	_boundary.body_fell.connect(_on_body_fell)
#@ 6+
	_player.health_component.defeated.connect(_respawn)
#@ all


func _physics_process(_delta: float) -> void:
#@ 1
	var commands := _input.read()
	if commands.attack and attack_rumble != null:
		_input.vibrate(attack_rumble)
	_display.show_commands(commands, _input.joypad_names())
	var aim := commands.move if commands.aim.is_zero_approx() else commands.aim
	_aim_pivot.visible = not aim.is_zero_approx()
	if _aim_pivot.visible:
		# Une direction de l'écran devient une direction du sol, tournée comme la caméra autour de la verticale.
		var direction := Vector3(aim.x, 0.0, aim.y).rotated(Vector3.UP, _camera.global_rotation.y)
		_aim_pivot.look_at(_aim_pivot.global_position + direction, Vector3.UP)
#@ 2+
	# La scène passe avant le joueur, son enfant : elle montre les commandes qu'il a lues à l'image d'avant.
	var commands := _player.commands
	if commands.attack and attack_rumble != null:
		_player.input.vibrate(attack_rumble)
	_display.show_commands(commands, _player.input.joypad_names())
#@ all
#@ 4-5


# Pas encore de santé : le joueur tombé revient à son point de départ, et la caméra tremble.
func _on_body_fell(body: Node3D) -> void:
	if body != _player:
		return
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_player.camera.quick_shake(1.0)
#@ all
#@ 6+


# Vaincu, le joueur revient à son point de départ, visible et avec toute sa santé, et la caméra tremble.
func _respawn() -> void:
	_player.global_position = _player_start
	_player.velocity = Vector3.ZERO
	_player.visible = true
	_player.health_component.restore()
	_player.camera.quick_shake(1.0)
#@ all
