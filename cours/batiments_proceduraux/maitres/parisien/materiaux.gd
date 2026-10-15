@tool
extends RefCounted
## Matériaux de l'immeuble parisien : pour chaque matière, un shader et ses réglages.
## {STATUS}
##
## Pourquoi un script à part : la géométrie et la matière sont deux métiers. Le script de
## l'immeuble dit OÙ est la pierre ; celui-ci dit à quoi elle RESSEMBLE.
##
## Mode d'emploi, côté immeuble :
##     _materials = Materials.new()
##     _materials.stone_color = stone_color     # 1. on règle
##     _materials.build()                       # 2. on fabrique
##     _mesh.box(taille, centre, _materials.stone)   # 3. on s'en sert
##
## Un ShaderMaterial, c'est un shader plus ses réglages.
#@ 6+ quiet
## Le même shader sert à plusieurs matériaux : la pierre lisse des étages et la pierre à
## refends du soubassement sortent du même fichier .gdshader, avec d'autres nombres.
#@ all

const STONE_SHADER: Shader = preload("{SHADER}_pierre.gdshader")
#@ 4+
const WINDOW_SHADER: Shader = preload("{SHADER}_fenetre.gdshader")
#@ 7+
const RAILING_SHADER: Shader = preload("{SHADER}_ferronnerie.gdshader")
#@ 9+
const ZINC_SHADER: Shader = preload("{SHADER}_zinc.gdshader")
#@ 10+
const WOOD_SHADER: Shader = preload("{SHADER}_bois.gdshader")
const AWNING_SHADER: Shader = preload("{SHADER}_store.gdshader")
#@ all

# --- Réglages : l'immeuble les remplit avant d'appeler build() ----------------

## Teinte de la pierre.
var stone_color: Color = Color(0.85, 0.76, 0.62)
#@ 3+
## Encrassement de la pierre, de 0 (ravalée) à 1 (noire de suie).
var soot: float = 0.25
#@ 4+
## Teinte des menuiseries de fenêtre.
var frame_color: Color = Color(0.86, 0.86, 0.83)
#@ 6+
## Hauteur d'une assise de pierre.
var course_height: float = 0.38
## Soubassement à refends.
var rusticated: bool = true
#@ 7+
## Motif des garde-corps : 0 barreaux, 1 volutes, 2 croisillons.
var railing_motif: int = 1
#@ 9+
## Luminosité du zinc du toit.
var zinc_brightness: float = 1.0
#@ 10+
## Teinte de la porte d'entrée.
var door_color: Color = Color(0.05, 0.16, 0.24)
#@ 11+
## Graine de l'immeuble : décale les motifs et change le tirage des pièces.
var variation_seed: int = 0
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute.
var quality: int = 2
#@ all

# --- Matériaux : à lire après build() -------------------------------------------

## Pierre des étages.
var stone: ShaderMaterial
#@ 6+
## Pierre du soubassement : à refends, un peu plus sale.
var stone_base: ShaderMaterial
#@ 4+
## Fenêtre d'appartement.
var window: ShaderMaterial
#@ 7+
## Garde-corps de fer.
var railing: ShaderMaterial
#@ 9+
var zinc: ShaderMaterial
## Fenêtre de lucarne : petite pièce basse sous le comble.
var dormer_window: ShaderMaterial
## Terre cuite des mitrons de cheminée.
var clay: StandardMaterial3D
#@ 10+
## Bois peint de la porte d'entrée.
var door_wood: ShaderMaterial
## Vitrine d'une devanture de bois : grande pièce nue, menuiserie de la teinte de la boutique.
var shop_window: ShaderMaterial
## Vitrine pleine surface : une seule glace, un cadre de métal fin.
var showcase_window: ShaderMaterial
## Grilles d'imposte au-dessus d'une porte : croisillons ou éventail, sans frise.
var grille: ShaderMaterial
var fan_grille: ShaderMaterial
var dark_glass: StandardMaterial3D
var iron: StandardMaterial3D
var brass: StandardMaterial3D
#@ all
## Enduit du volume arrière et des pignons.
var plaster: StandardMaterial3D

#@ 10+
# Matériaux fabriqués à la demande, un par teinte : deux boutiques vertes partagent le leur.
var _painted_wood: Dictionary[Color, ShaderMaterial] = {}
var _plain_colors: Dictionary[Color, StandardMaterial3D] = {}
var _awnings: Dictionary[Color, ShaderMaterial] = {}
#@ all


## Fabrique tous les matériaux d'après les réglages.
func build() -> void:
#@ 11+
	# Décalage des motifs, tiré de la graine : deux immeubles voisins n'ont pas les mêmes
	# pierres ni les mêmes feuilles de zinc aux mêmes endroits.
	var offset: Vector2 = Vector2(float(variation_seed) * 1.37, float(variation_seed) * 0.61)
#@ 3+
	# La seconde teinte des blocs et celle des joints suivent la pierre : une façade très claire
	# garde des joints clairs, une façade grise des joints gris.
	var stone_2: Color = Color(stone_color.r * 0.906, stone_color.g * 0.868, stone_color.b * 0.823)
	var joint: Color = Color(stone_color.r * (0.62 / 0.85), stone_color.g * (0.57 / 0.76), stone_color.b * (0.49 / 0.62))
#@ all
	# Chaque clé du dictionnaire est le nom d'un « uniform » du fichier .gdshader.
	stone = _shader_material(STONE_SHADER, {
		"stone_color": stone_color,
#@ 3+
		"stone_color_2": stone_2,
		"joint_color": joint,
		"soot": soot,
#@ 6+
		"course_height": course_height,
#@ 11+
		"pattern_offset": offset,
#@ all
	})
#@ 6+
	# Même shader, autres nombres : assises plus hautes, blocs plus longs, refends, plus de suie.
	stone_base = _shader_material(STONE_SHADER, {
		"stone_color": stone_color,
		"stone_color_2": stone_2,
		"joint_color": joint,
		"course_height": course_height + 0.03,
		"block_length": 1.3,
		"refend_amount": 1.0 if rusticated else 0.0,
		"soot": minf(soot + 0.1, 1.0),
#@ 11+
		"pattern_offset": offset,
#@ 6+
	})
#@ 4+

#@ 4-10
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color})
#@ 11+
	# « seed » change le tirage des pièces derrière les fenêtres.
	var seed_value: float = float(variation_seed)
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color, "seed": seed_value})
#@ 9+
	dormer_window = _shader_material(WINDOW_SHADER, {
		"frame_color": frame_color,
#@ 11+
		"seed": seed_value,
#@ 9+
		"pane_rows": 2,
		"room_depth": 3.0,
		"ceiling_height": 2.4,
		"sill_height": 0.9,
		"lit_ratio_night": 0.4,
	})
#@ 10+
	shop_window = _shader_material(WINDOW_SHADER, {
#@ 11+
		"seed": seed_value,
		"furnished": false,
#@ 10+
		"frame_color_from_instance": true,
		"pane_rows": 2,
		"room_depth": 7.0,
		"ceiling_height": 3.8,
		"curtains": 0.0,
		"lit_ratio_night": 0.3,
	})
	showcase_window = _shader_material(WINDOW_SHADER, {
#@ 11+
		"seed": seed_value,
		"furnished": false,
		"dirt": 0.12,
#@ 10+
		"frame_color_from_instance": true,
		"two_leaves": false,
		"pane_rows": 1,
		"frame_width": 0.04,
		"room_depth": 8.0,
		"ceiling_height": 3.8,
		"curtains": 0.0,
		"lit_ratio_night": 0.6,
	})
#@ 7+

	railing = _shader_material(RAILING_SHADER, {"motif": railing_motif})
#@ 10+
	grille = _shader_material(RAILING_SHADER, {"motif": 2, "frieze": false, "module_width": 0.4, "bar_width": 0.012})
	fan_grille = _shader_material(RAILING_SHADER, {"motif": 3, "frieze": false, "bar_width": 0.014})
#@ 9+

#@ 9-10
	zinc = _shader_material(ZINC_SHADER, {"brightness": zinc_brightness})
#@ 11+
	zinc = _shader_material(ZINC_SHADER, {"brightness": zinc_brightness, "pattern_offset": offset})
#@ 10+
	door_wood = painted_wood(door_color)
#@ all

	# Ce qui n'a pas besoin de shader : un matériau uni ordinaire.
	plaster = _plain(Color(0.50, 0.47, 0.42), 0.95, 0.0)
#@ 9+
	clay = _plain(Color(0.55, 0.27, 0.16), 0.85, 0.0)
#@ 10+
	dark_glass = _plain(Color(0.02, 0.025, 0.03), 0.08, 0.0)
	iron = _plain(Color(0.035, 0.04, 0.04), 0.5, 0.6)
	brass = _plain(Color(0.72, 0.56, 0.24), 0.35, 0.9)
#@ 13+
	set_quality(quality)


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Seule la pierre a ce réglage :
## elle couvre presque toute la façade, donc presque tous les pixels.
func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	for material: ShaderMaterial in [stone, stone_base]:
		if material != null:
			material.set_shader_parameter("quality", quality)
#@ 5+


## 0 : jour, 1 : nuit, pour toutes les fenêtres de l'immeuble.
func set_night(value: float) -> void:
#@ 5-8
	window.set_shader_parameter("night", value)
#@ 9
	for material: ShaderMaterial in [window, dormer_window]:
		if material != null:
			material.set_shader_parameter("night", value)
#@ 10+
	for material: ShaderMaterial in [window, shop_window, showcase_window, dormer_window]:
		if material != null:
			material.set_shader_parameter("night", value)
#@ 10+


## Bois peint d'une teinte donnée, sans joints de planches : menuiserie de porte ou de devanture.
func painted_wood(color: Color) -> ShaderMaterial:
	if not _painted_wood.has(color):
		_painted_wood[color] = _shader_material(WOOD_SHADER, {
			"paint": 1.0,
			"paint_color": color,
			"plank_width": 0.6,
			"gap_width": 0.0,
			"gap_depth": 0.0,
			"paint_wear": 0.0,
		})
	return _painted_wood[color]


## Métal laqué ou panneau uni d'une teinte donnée : cadres et bandeaux des vitrines modernes.
func lacquer(color: Color) -> StandardMaterial3D:
	if not _plain_colors.has(color):
		_plain_colors[color] = _plain(color, 0.45, 0.3)
	return _plain_colors[color]


## Toile de store d'une teinte donnée.
func awning(color: Color) -> ShaderMaterial:
	if not _awnings.has(color):
		_awnings[color] = _shader_material(AWNING_SHADER, {"fabric_color": color})
	return _awnings[color]
#@ all


## Un ShaderMaterial : le shader, puis ses réglages, donnés un par un par leur nom.
func _shader_material(shader: Shader, parameters: Dictionary[String, Variant]) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	for key: String in parameters:
		material.set_shader_parameter(key, parameters[key])
	return material


## Matériau uni ordinaire.
func _plain(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
