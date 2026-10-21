class_name EnemyView extends Node
## Présentation d'un ennemi : un coup reçu joue le son du coup ; vaincu, un écho blanc gagne son corps (le shader
## defeat_echo, posé en surcouche sur chaque maillage du modèle), puis le corps disparaît. La logique de
## l'ennemi ne connaît ni ses sons ni ses effets (règle ARC-03).

## L'ennemi montré.
@export var enemy: Enemy
## Son d'un coup reçu.
@export var hit_audio: AudioStreamPlayer3D
## Le modèle, que l'écho recouvre puis qui disparaît.
@export var model: Node3D
## Le matériau de l'écho (defeat_echo.gdshader) ; chaque ennemi vaincu en reçoit sa copie.
@export var echo_material: ShaderMaterial
## Durée de la montée de l'écho, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var echo_duration: float = 0.8

var _echo: ShaderMaterial


func _ready() -> void:
	if enemy == null or hit_audio == null or model == null or echo_material == null:
		push_error("EnemyView : une dépendance manque (enemy, hit_audio, model, echo_material)")
		return
	# La vue est un enfant de l'ennemi : elle est prête avant lui, dont les composants (@onready) ne sont pas
	# encore posés. On attend l'ennemi.
	if not enemy.is_node_ready():
		await enemy.ready
	enemy.health_component.damage_taken.connect(_on_damage_taken)
	enemy.defeated.connect(_on_defeated)


## Avancée de l'écho, de 0 à 1 ; 0 tant que l'ennemi n'est pas vaincu.
func echo_amount() -> float:
	return 0.0 if _echo == null else _echo.get_shader_parameter(&"dissolve_amount") as float


func _on_damage_taken(_amount: float) -> void:
	hit_audio.play()


func _on_defeated() -> void:
	# Une copie : un matériau partagé ferait monter l'écho de tous les ennemis à la fois.
	_echo = echo_material.duplicate() as ShaderMaterial
	_echo.set_shader_parameter(&"dissolve_amount", 0.0)
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _echo
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_echo, "shader_parameter/dissolve_amount", 1.0, echo_duration)
	tween.tween_callback(model.hide)
