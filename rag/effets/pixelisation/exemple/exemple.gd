extends Node
## Exemple : pixelisation de l'écran. Un dégradé horizontal remplit l'écran ; un ColorRect par-dessus relit l'image
## (hint_screen_texture) par blocs. Sur une ligne, on compte les changements de couleur entre pixels voisins à
## l'intérieur des blocs de 8 pixels : sans l'effet, avec des blocs de 1 (l'image reste intacte), puis de 8.

const PIXELISATION: Shader = preload("res://exemple/pixelisation.gdshader")

var _voile: ColorRect


func _ready() -> void:
	var degrade := Gradient.new()
	degrade.set_color(0, Color.BLACK)
	degrade.set_color(1, Color.WHITE)
	var texture := GradientTexture2D.new()
	texture.gradient = degrade
	texture.width = 256
	texture.height = 4
	var fond := TextureRect.new()
	fond.texture = texture
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	_voile = ColorRect.new()
	_voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	var materiau := ShaderMaterial.new()
	materiau.shader = PIXELISATION
	_voile.material = materiau
	_voile.visible = false
	add_child(_voile)
	var sans := await _changements()
	_voile.visible = true
	pixeliser(materiau, 1.0)
	var blocs_de_1 := await _changements()
	pixeliser(materiau, 8.0)
	var blocs_de_8 := await _changements()
	if sans > 0 and blocs_de_1 == sans and blocs_de_8 == 0:
		print("EXEMPLE VERIFIE : %d changements de couleur à l'intérieur des blocs de 8 pixels sans l'effet, %d avec des blocs de 1, %d avec des blocs de 8"
				% [sans, blocs_de_1, blocs_de_8])
	else:
		push_error("changements : %d sans, %d blocs de 1, %d blocs de 8" % [sans, blocs_de_1, blocs_de_8])
	get_tree().quit()


## Taille des blocs, en pixels de l'écran ; 1 laisse l'image intacte.
func pixeliser(materiau: ShaderMaterial, taille: float) -> void:
	materiau.set_shader_parameter(&"taille", taille)


func _changements() -> int:
	for _image: int in 2:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var y := int(image.get_height() * 0.5)
	var n := 0
	for x: int in range(1, image.get_width()):
		if x % 8 != 0 and not image.get_pixel(x, y).is_equal_approx(image.get_pixel(x - 1, y)):
			n += 1  # un changement hors du début d'un bloc
	return n
