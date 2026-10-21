class_name PlayerView extends Node
## Présentation du joueur : elle écoute ses signaux et joue les effets et les sons. Une esquive (dashed) tourne
## la traînée vers la direction de l'esquive, la fait apparaître puis s'effacer (animation « dash »), et joue le
## son. La logique du joueur ne connaît ni ses sons ni ses effets (règle ARC-03).
#@ 6+
## Quand l'épée touche une cible (struck), la caméra tremble.
#@ 9+
## Touché (damage_taken de sa santé), le joueur voit l'écran rougir un instant, la caméra trembler, entend le coup,
## et la manette vibre.
#@ all

## Le joueur montré.
@export var player: Player
## Le support de la traînée, tourné vers la direction de l'esquive.
@export var dash_root: Node3D
## Joue l'animation « dash » de la traînée (le seuil d'effacement de son shader, de 0 à 1).
@export var dash_animation: AnimationPlayer
## Son de l'esquive.
@export var dash_audio: AudioStreamPlayer3D
#@ 6+
## La zone de coup de l'épée.
@export var sword: AttackComponent
#@ 9+
## Le voile rouge posé sur tout l'écran, transparent au repos.
@export var damage_tint: ColorRect
## Son d'un coup reçu.
@export var damage_audio: AudioStreamPlayer3D
## Vibration d'un coup reçu (5_data/input/hit_rumble.tres).
@export var hit_rumble: Rumble
#@ all


func _ready() -> void:
	if player == null or dash_root == null or dash_animation == null or dash_audio == null:
		push_error("PlayerView : une dépendance manque (player, dash_root, dash_animation, dash_audio)")
		return
	player.dashed.connect(_on_dashed)
#@ 6+
	if sword != null:
		sword.struck.connect(_on_sword_struck)
#@ all
#@ 9+
	# La vue est un enfant du joueur : prête avant lui, elle attend ses composants (@onready).
	if not player.is_node_ready():
		await player.ready
	player.health_component.damage_taken.connect(_on_damage_taken)
#@ all


func _on_dashed(direction: Vector3) -> void:
	dash_audio.play()
	dash_root.look_at(dash_root.global_position + direction, Vector3.UP)
	dash_animation.stop()
	dash_animation.play(&"dash")
#@ 6+


func _on_sword_struck(_target: Object) -> void:
	if sword.shake_on_damage:
		player.camera.quick_shake(player.settings.hit_shake)
#@ all
#@ 9+


func _on_damage_taken(_amount: float) -> void:
	player.camera.quick_shake(player.settings.damage_shake)
	if damage_tint != null:
		var tween := create_tween()
		tween.tween_property(damage_tint, "color", Color(Color.RED, 0.0), 0.2).from(Color(Color.RED, 0.5))
	if damage_audio != null:
		damage_audio.play()
	if hit_rumble != null and player.input != null:
		player.input.vibrate(hit_rumble)
#@ all
