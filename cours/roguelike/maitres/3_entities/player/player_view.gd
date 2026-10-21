class_name PlayerView extends Node
## Présentation du joueur : elle écoute ses signaux et joue les effets et les sons. Une esquive (dashed) tourne
## la traînée vers la direction de l'esquive, la fait apparaître puis s'effacer (animation « dash »), et joue le
## son. La logique du joueur ne connaît ni ses sons ni ses effets (règle ARC-03).

## Le joueur montré.
@export var player: Player
## Le support de la traînée, tourné vers la direction de l'esquive.
@export var dash_root: Node3D
## Joue l'animation « dash » de la traînée (le seuil d'effacement de son shader, de 0 à 1).
@export var dash_animation: AnimationPlayer
## Son de l'esquive.
@export var dash_audio: AudioStreamPlayer3D


func _ready() -> void:
	if player == null or dash_root == null or dash_animation == null or dash_audio == null:
		push_error("PlayerView : une dépendance manque (player, dash_root, dash_animation, dash_audio)")
		return
	player.dashed.connect(_on_dashed)


func _on_dashed(direction: Vector3) -> void:
	dash_audio.play()
	dash_root.look_at(dash_root.global_position + direction, Vector3.UP)
	dash_animation.stop()
	dash_animation.play(&"dash")
