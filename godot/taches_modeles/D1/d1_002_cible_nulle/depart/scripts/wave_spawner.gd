class_name WaveSpawner
extends Node2D
## Fait apparaître des vagues d'ennemis de plus en plus nombreuses.

signal wave_started(number: int, enemy_count: int)
signal wave_cleared(number: int)

@export var enemy_scene: PackedScene
@export var base_count: int = 2
@export var per_wave: int = 1
@export var spawn_radius: float = 160.0

var current_wave: int = 0
var alive: int = 0
var target: Node2D = null


## Nombre d'ennemis de la vague n (n ≥ 1).
func enemies_for_wave(number: int) -> int:
	return base_count + (number - 1) * per_wave


## Positions d'apparition, réparties régulièrement sur un cercle (déterministe).
func spawn_positions(count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in count:
		result.append(Vector2.RIGHT.rotated(TAU * i / count) * spawn_radius)
	return result


func start_next_wave() -> void:
	current_wave += 1
	var count: int = enemies_for_wave(current_wave)
	alive = 0
	for pos in spawn_positions(count):
		var enemy: Ghost = enemy_scene.instantiate()
		enemy.position = pos
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		alive += 1
	wave_started.emit(current_wave, count)


func _on_enemy_defeated() -> void:
	alive -= 1
	if alive == 0:
		wave_cleared.emit(current_wave)
