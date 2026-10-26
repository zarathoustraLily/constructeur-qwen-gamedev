extends Node
## Exemple : vignette de dégâts. Un ColorRect plein écran, dans un CanvasLayer au-dessus du jeu, porte le shader.
## `suivre_sante` règle la force d'après la vie : à vie nulle, les coins sont rouges et le centre reste libre ; à pleine
## vie, plus rien ne se voit.

const VIGNETTE: Shader = preload("res://exemple/vignette.gdshader")


func _ready() -> void:
	var calque := CanvasLayer.new()
	add_child(calque)
	var voile := ColorRect.new()
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE  # le voile ne doit pas bloquer les clics du jeu
	var materiau := ShaderMaterial.new()
	materiau.shader = VIGNETTE
	voile.material = materiau
	calque.add_child(voile)
	var fond := RenderingServer.get_default_clear_color()
	suivre_sante(materiau, 0.0)
	var image := await _image()
	var coin := image.get_pixel(2, 2)
	var centre := image.get_pixel(int(image.get_width() * 0.5), int(image.get_height() * 0.5))
	suivre_sante(materiau, 1.0)
	var coin_pleine_vie := (await _image()).get_pixel(2, 2)
	var rouge := coin.r > coin.g + 0.3
	if rouge and absf(centre.r - fond.r) < 0.05 and absf(coin_pleine_vie.r - fond.r) < 0.05:
		print("EXEMPLE VERIFIE : vie nulle, coin (%.2f, %.2f, %.2f) et centre (%.2f, %.2f, %.2f) égal au fond ; pleine vie, coin %.2f de rouge"
				% [coin.r, coin.g, coin.b, centre.r, centre.g, centre.b, coin_pleine_vie.r])
	else:
		push_error("coin %s, centre %s, coin à pleine vie %s" % [coin, centre, coin_pleine_vie])
	get_tree().quit()


## La force suit la santé : nulle à pleine vie, entière à vie nulle (`part_de_vie` entre 0 et 1).
func suivre_sante(materiau: ShaderMaterial, part_de_vie: float) -> void:
	materiau.set_shader_parameter(&"force", 1.0 - clampf(part_de_vie, 0.0, 1.0))


func _image() -> Image:
	for _i: int in 2:
		await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
