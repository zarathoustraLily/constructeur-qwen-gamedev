class_name Player extends Node3D
## Joueur : son kart, sa caméra et son inventaire. À chaque image, il partage la position du kart
## (GameState, océan, traces de pneus) et imprime les traces des roues au sol ; la commande « use_item »
## utilise un objet.

@onready var kart : Kart = $Kart
@onready var camera : Node3D = $CameraPivot
@onready var inventory : Inventory = $Inventory

## Océan de la scène ; par défaut, le premier du groupe « ocean ».
var ocean_node : Ocean
## Gestionnaire des traces de pneus ; par défaut, le premier du groupe « tire_marks ».
var tire_marks_node : Node


func _ready() -> void:
	if !ocean_node:
		ocean_node = get_tree().get_first_node_in_group("ocean")
	if !tire_marks_node:
		tire_marks_node = get_tree().get_first_node_in_group("tire_marks")

func _follow_camera(_delta: float) -> void:
	camera.global_position = kart.visual_parent.global_position + Vector3(0, 1, 0)

func _process(delta: float) -> void:
	_follow_camera(delta)
	
	GameState.player_position = kart.global_position
	
	if ocean_node:
		ocean_node.set_player_position(kart.global_position)
		# Les ondulations, le sillage et l'écume sont générés roue par roue (WheelSplashEffects)
	
	if tire_marks_node:
		tire_marks_node.set_player_position(kart.global_position)
		for wheel in kart.wheels:
			if wheel.is_grounded():
				tire_marks_node.add_tire(wheel.get_wheel_position(), 1.0, 9.0);
			else:
				tire_marks_node.add_tire(wheel.get_wheel_position(), 0.0, 0.0);


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_item"):
		inventory.use_item(self)

## Range `item` dans l'inventaire (refusé s'il est plein).
func add_item(item : ItemType) -> void:
	inventory.add_item(item)

## Position du kart.
func get_kart_position() -> Vector3:
	return kart.global_position

## Direction de lancer des objets : l'axe de la caméra, ramené à l'horizontale.
func get_item_direction() -> Vector3:
	var dir: Vector3 = camera.basis.z	
	return Vector3(dir.x, 0, dir.z).normalized()
