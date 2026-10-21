extends PlayerState
## Un coup d'épée. Trois nœuds portent ce script, un par coup de l'enchaînement (taille, estoc, tourbillon) ;
## chacun a ses réglages (AttackSettings, dans 5_data/player/attacks/). Le coup dure le temps de son animation,
## puis la course reprend. Un coup demandé pendant le coup s'enchaîne au coup suivant, une fois passé
## queue_time. L'esquive peut interrompre les coups qui le permettent. Pendant le coup, l'arme frappe tout ce que
## sa zone touche, quand l'animation l'active.

## Les réglages du coup.
@export var attack: AttackSettings
## La zone de coup de l'arme.
@export var attack_component: AttackComponent
## L'état de course.
@export var run_state: PlayerState
## L'état d'esquive.
@export var dash_state: PlayerState
## Le coup suivant de l'enchaînement ; vide pour le dernier.
@export var next_attack: PlayerState

var _queued: bool = false
var _aim: Vector3 = Vector3.ZERO

@onready var _queue_timer: Timer = $QueueTimer


func _ready() -> void:
	_queue_timer.timeout.connect(_on_queue_timeout)


## Lance l'animation du coup et vise : vers la visée, à défaut vers la marche, à défaut droit devant.
func enter(_previous_state: StringName) -> void:
	_queued = false
	attack_component.reset_exceptions()
	player.animation_tree.change_immediate(attack.animation)
	player.animation_tree.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	_queue_timer.start(attack.queue_time)
	_aim = player.get_aim_direction()


## Note un coup demandé, laisse l'esquive interrompre si le coup le permet, frappe, et avance un peu.
func physics_update(_delta: float) -> void:
	if player.commands.attack:
		_queued = true
	if attack.dash_cancel and player.commands.dash and player.can_dash():
		finished.emit(dash_state.name)
		return
	player.velocity = player.get_movement_direction() * attack.movement_speed
	attack_component.deal_damage(Damage.scaled(attack.damage, player.damage_stat),
		player.model.global_basis.z * attack.knockback)
	# Une « durée » de 1 s : le modèle se tourne d'un coup vers la visée (il fait 1 - exp(-turn_rate) du chemin).
	player.look_toward_direction(_aim, 1.0)
	player.move_and_slide()


## Coupe le délai d'enchaînement et l'écoute de la fin de l'animation : un coup interrompu ne doit plus agir.
func exit() -> void:
	_queue_timer.stop()
	if player.animation_tree.animation_finished.is_connected(_on_animation_finished):
		player.animation_tree.animation_finished.disconnect(_on_animation_finished)


func _on_animation_finished(_animation_name: StringName) -> void:
	finished.emit(run_state.name)


func _on_queue_timeout() -> void:
	if next_attack != null and _queued:
		finished.emit(next_attack.name)
