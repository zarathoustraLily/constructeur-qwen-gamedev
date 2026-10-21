extends CanvasLayer
## Le chef d'orchestre (singleton GameFlow) : c'est lui, et lui seul, qui charge les scènes du jeu. Il reçoit la
## séquence (start(), appelé par la scène de démarrage 2_sequence/boot.tscn), en tire l'ordre des niveaux avec sa
## graine, et charge le premier niveau de cet ordre. Chaque étape respecte le contrat Step
## (1_core/step/step.gd) : quand elle émet finished, il charge la suivante. Après un niveau vient l'intermède de la
## séquence, s'il y en a un, puis le niveau suivant de l'ordre ; après le dernier, le premier ; « retry » recharge
## l'étape en cours. Chaque changement passe par un fondu au noir (le voile, Veil), une pause, puis le retour de
## l'image. Le joueur (le nœud du groupe « player ») est gardé de côté pendant le changement : l'étape suivante le
## reprend (take_player), avec ce qu'il a gagné. Sur un « retry », il n'est pas gardé : l'étape repart à neuf.

## Émis quand une étape vient d'être chargée.
signal step_started(step: Step)

## Durée du fondu au noir, et du retour de l'image, en secondes.
@export var fade_time: float = 1.0
## Pause au noir entre les deux, en secondes.
@export var pause_time: float = 0.5

## La séquence jouée.
var sequence: Sequence
## L'ordre des niveaux pour cette partie.
var order: Array[PackedScene] = []
## Rang dans l'ordre du niveau en cours (ou du dernier joué, pendant l'intermède).
var level_index: int = -1
## L'étape en cours.
var current_step: Step

var _current_scene: PackedScene
var _carried_player: Node3D

@onready var _veil: ColorRect = $Veil


## Reçoit la séquence du jeu, tire l'ordre des niveaux et charge le premier ; l'image revient du noir.
func start(new_sequence: Sequence) -> void:
	if new_sequence == null or new_sequence.steps.is_empty():
		push_error("GameFlow.start : séquence vide")
		return
	sequence = new_sequence
	order.assign(sequence.steps)
	if sequence.shuffle:
		_shuffle(order, sequence.random_seed)
	level_index = 0
	_load(order[0])
	create_tween().tween_property(_veil, "color:a", 0.0, fade_time).from(1.0)


## Le joueur gardé de côté pendant le dernier changement, ou null ; l'étape qui le reprend l'enlève d'ici.
func take_player() -> Node3D:
	var player := _carried_player
	_carried_player = null
	return player


# Mélange de Fisher et Yates, avec une graine : un même ordre pour une même graine.
static func _shuffle(scenes: Array[PackedScene], seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index: int in range(scenes.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var kept := scenes[index]
		scenes[index] = scenes[other]
		scenes[other] = kept


# Remplace la scène courante par une instance de `scene`, et écoute sa fin.
func _load(scene: PackedScene) -> void:
	var step := scene.instantiate() as Step
	if step == null:
		push_error("GameFlow : la scène %s ne respecte pas le contrat Step" % scene.resource_path)
		return
	var tree := get_tree()
	var previous := tree.current_scene
	if previous != null:
		# Retirée de l'arbre d'abord : une étape rechargée garde son nom, au lieu d'être renommée à côté de l'ancienne.
		previous.get_parent().remove_child(previous)
		previous.queue_free()
	tree.root.add_child(step)
	tree.current_scene = step
	current_step = step
	_current_scene = scene
	step.finished.connect(_on_step_finished, CONNECT_ONE_SHOT)
	step_started.emit(step)


# Fondu au noir, joueur gardé de côté (s'il le faut), changement d'étape, pause, retour de l'image.
func _transition(scene: PackedScene, keep_player: bool) -> void:
	var player: Node3D = null
	if keep_player:
		player = get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(_veil, "color:a", 1.0, fade_time)
	tween.tween_callback(_swap.bind(scene, player))
	tween.tween_interval(pause_time)
	tween.tween_property(_veil, "color:a", 0.0, fade_time)


func _swap(scene: PackedScene, player: Node3D) -> void:
	if player != null and is_instance_valid(player):
		# Hors de l'arbre, le joueur survit à la libération du niveau quitté.
		player.get_parent().remove_child(player)
		_carried_player = player
	_load(scene)


func _on_step_finished(outcome: StringName) -> void:
	if outcome == &"retry":
		_transition(_current_scene, false)
		return
#@ 13+
	if sequence.interlude != null and _current_scene != sequence.interlude:
		_transition(sequence.interlude, true)
		return
#@ all
	level_index = (level_index + 1) % order.size()
	_transition(order[level_index], true)
