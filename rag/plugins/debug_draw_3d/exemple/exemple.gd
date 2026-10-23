extends Node3D
## Exemple minimal de Debug Draw 3D (1.7.3, GDExtension) : dessiner, pour déboguer, une boîte, un rayon et une
## sphère en 3D et un texte à l'écran, depuis n'importe quel script, sans créer de nœud.

const IMAGES: int = 10

var _image: int = 0


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.0, 6.0)
	add_child(camera)


func _physics_process(_delta: float) -> void:
	_image += 1
	# Un appel par image et par forme ; « duration » (dernier argument) les garde affichées plus longtemps.
	DebugDraw3D.draw_box(Vector3.ZERO, Quaternion.IDENTITY, Vector3.ONE, Color.YELLOW)
	DebugDraw3D.draw_ray(Vector3.ZERO, Vector3.FORWARD, 3.0, Color.RED)
	DebugDraw3D.draw_sphere(Vector3(0.0, 1.0, 0.0), 0.5, Color.CYAN)
	DebugDraw2D.set_text("image", _image)
	if _image < IMAGES:
		return
	var stats := DebugDraw3D.get_render_stats()
	if DebugDraw3D.is_debug_enabled() and stats.instances + stats.lines + stats.instances_physics + stats.lines_physics > 0:
		print("EXEMPLE VERIFIE : %d instances et %d lignes en cours (physique : %d et %d)"
				% [stats.instances, stats.lines, stats.instances_physics, stats.lines_physics])
	else:
		push_error("rien dessiné : %d instances, %d lignes" % [stats.instances, stats.lines])
	get_tree().quit()
