extends SceneTree
## Quel moteur physique ce projet emploie-t-il ?


func _initialize() -> void:
	print("physics/3d/physics_engine = ", ProjectSettings.get_setting("physics/3d/physics_engine"))
	quit()
