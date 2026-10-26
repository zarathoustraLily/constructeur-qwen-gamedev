extends Node2D
## Exemple minimal de SmartShape2D (3.3.2, GDScript) : une forme 2D fermée (un terrain de plateforme) dessinée par
## ses points, dont le plugin tire le polygone de collision.

var _forme: SS2D_Shape
var _polygone: CollisionPolygon2D
var _image: int = 0


func _ready() -> void:
	_forme = SS2D_Shape.new()
	var points := _forme.get_point_array()  # en 3.x, les points se manipulent par le tableau de points
	for p: Vector2 in [Vector2(0, 0), Vector2(200, 0), Vector2(200, 100), Vector2(0, 100)]:
		points.add_point(p)
	points.close_shape()
	var sol := StaticBody2D.new()
	_polygone = CollisionPolygon2D.new()
	sol.add_child(_polygone)
	add_child(sol)
	add_child(_forme)
	_forme.collision_polygon_node_path = _forme.get_path_to(_polygone)
	_forme.collision_update_mode = SS2D_Shape.CollisionUpdateMode.Runtime  # sinon, collision calculée dans l'éditeur seulement
	_forme.bake_collision()


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image < 3:
		return
	var n := _polygone.polygon.size()
	if _forme.get_point_array().is_shape_closed() and n >= 4:
		print("EXEMPLE VERIFIE : forme fermée de %d points, polygone de collision de %d sommets"
				% [_forme.get_point_array().get_point_count(), n])
	else:
		push_error("fermée : %s, sommets de collision : %d" % [_forme.get_point_array().is_shape_closed(), n])
	get_tree().quit()
