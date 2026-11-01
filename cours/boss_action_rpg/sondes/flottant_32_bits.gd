extends SceneTree
## Un Vector3 garde-t-il 0,6 tel quel ?


func _initialize() -> void:
	var v: Vector3 = Vector3(0.6, 0.0, 0.0)
	print("x vaut %.10f ; x == 0.6 : %s ; is_equal_approx : %s" % [v.x, v.x == 0.6, is_equal_approx(v.x, 0.6)])
	quit()
