class_name WaveObjective extends Node3D
## L'objectif d'un niveau : une vague d'ennemis. start() en prépare autant que la courbe de difficulté le dit pour
## le rang du niveau, puis les fait apparaître un à un (un Timer : first_delay, puis interval), chacun d'une sorte
## tirée parmi enemy_scenes, à une place tirée au hasard puis posée sur la navigation. Chaque ennemi apparu est
## signalé (enemy_spawned) : le niveau le décore. Quand le dernier est vaincu, la vague l'est aussi (cleared).
## Tous les tirages passent par une graine : une même partie fait la même vague.

## Émis quand un ennemi vient d'apparaître.
signal enemy_spawned(enemy: Enemy)
## Émis quand le dernier ennemi de la vague est vaincu.
signal cleared

## Réglages de la vague (5_data/levels/wave.tres).
@export var settings: WaveSettings
## Les sortes d'ennemis possibles ; c'est le niveau qui les donne (une donnée ne connaît pas les acteurs).
@export var enemy_scenes: Array[PackedScene] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _waiting: Array[Enemy] = []
var _alive: Array[Enemy] = []

@onready var _timer: Timer = $SpawnTimer


func _ready() -> void:
	if settings == null or enemy_scenes.is_empty():
		push_error("WaveObjective : une dépendance manque (settings, enemy_scenes)")
		return
	_rng.seed = settings.random_seed
	_timer.timeout.connect(_spawn_next)


## Prépare la vague du niveau de rang `rank` et lance les apparitions.
func start(rank: int) -> void:
	for _index: int in settings.enemy_count(rank):
		var scene := enemy_scenes[_rng.randi_range(0, enemy_scenes.size() - 1)]
		var enemy := scene.instantiate() as Enemy
		enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
		_waiting.append(enemy)
		_alive.append(enemy)
	_timer.start(settings.first_delay)


## Ennemis encore à vaincre, apparus ou non.
func remaining() -> int:
	return _alive.size()


func _notification(what: int) -> void:
	# Les ennemis pas encore apparus n'ont pas de parent : ils partent avec la vague (sinon, quitter le niveau
	# avant la fin de la vague les laisserait en mémoire).
	if what == NOTIFICATION_PREDELETE:
		for enemy: Enemy in _waiting:
			if is_instance_valid(enemy):
				enemy.free()


func _spawn_next() -> void:
	if _waiting.is_empty():
		return
	var enemy: Enemy = _waiting.pop_front()
	enemy.position = _spawn_position()
	add_child(enemy)
	enemy.rng.seed = _rng.randi()
	enemy_spawned.emit(enemy)
	if not _waiting.is_empty():
		_timer.start(settings.interval)


# Une place tirée dans le carré de la vague, posée sur la navigation (le point le plus proche), à hauteur d'ennemi.
func _spawn_position() -> Vector3:
	var extent := settings.spawn_extent
	var candidate := global_position + Vector3(_rng.randf_range(-extent, extent), 0.0, _rng.randf_range(-extent, extent))
	var point := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, candidate)
	return to_local(Vector3(point.x, global_position.y + settings.spawn_height, point.z))


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive.erase(enemy)
	if _alive.is_empty():
		cleared.emit()
