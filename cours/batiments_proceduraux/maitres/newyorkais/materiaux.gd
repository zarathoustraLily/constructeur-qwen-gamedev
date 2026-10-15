@tool
extends RefCounted
## Matériaux de la tour new-yorkaise : pour chaque matière, un shader et ses réglages.
## {STATUS}
##
## Pourquoi un script à part : la géométrie et la matière sont deux métiers. Le script de la
## tour dit OÙ est la brique ; celui-ci dit à quoi elle RESSEMBLE.
##
## Mode d'emploi, côté tour :
##     _materials = Materials.new()
##     _materials.brick_color = brick_color          # 1. on règle
##     _materials.build()                            # 2. on fabrique
##     _mesh.box(taille, centre, _materials.brick)   # 3. on s'en sert
##
## Un ShaderMaterial, c'est un shader plus ses réglages.
#@ 6+ quiet
## Le même shader sert à plusieurs matériaux : la brique des étages et la pierre du socle
## sortent du même fichier .gdshader, avec d'autres nombres.
#@ 7+ quiet
## Les deux tours de verre aussi : un seul shader de mur-rideau, et deux jeux de nombres.
#@ 9+ quiet
## Et le couronnement : cuivre, acier, ventelles et bois sortent d'un même shader.
#@ all

const BRICK_SHADER: Shader = preload("{SHADER}_brique.gdshader")
#@ 4+
const WINDOW_SHADER: Shader = preload("{SHADER}_fenetre.gdshader")
#@ 7+
const CURTAIN_SHADER: Shader = preload("{SHADER}_mur_rideau.gdshader")
#@ 9+
const CROWN_SHADER: Shader = preload("{SHADER}_couronne.gdshader")
#@ 10+
const BRONZE_SHADER: Shader = preload("{SHADER}_bronze.gdshader")
#@ 13+
const FAR_SHADER: Shader = preload("{SHADER}_facade_lointaine.gdshader")
## Les teintes des bandeaux d'enseigne : la façade lointaine en prend la moyenne.
const Palette := preload("{DATA}_palette.gd")
#@ 9+
## Les matières du shader de couronnement : la valeur de son uniforme « finish ».
const FINISH_COPPER: int = 0
const FINISH_STEEL: int = 1
const FINISH_LOUVRES: int = 2
const FINISH_WOOD: int = 3
#@ all

# --- Réglages : la tour les remplit avant d'appeler build() -------------------

## Teinte de la brique.
var brick_color: Color = Color(0.62, 0.46, 0.36)
#@ 3+
## Encrassement des murs, de 0 (lavés) à 1 (noirs de suie).
var grime: float = 0.35
#@ 4+
## Teinte des châssis des fenêtres.
var frame_color: Color = Color(0.16, 0.17, 0.15)
#@ 5+
## Ce que le shader de fenêtre doit savoir pour placer le sol et le plafond des pièces : la
## hauteur d'un étage et celle de l'allège. Et la largeur d'une travée : un bureau en fait une,
## deux ou trois.
var floor_height: float = 3.66
var sill_height: float = 0.85
var bay_width: float = 2.0
#@ 6+
## Hauteur du rez-de-chaussée et de son allège, pour le hall.
var ground_height: float = 5.5
var ground_sill: float = 0.6
## Teinte de la pierre du socle.
var stone_color: Color = Color(0.78, 0.75, 0.68)
#@ 7+
## Famille de la tour : 1, verre et allèges (1961) ; 2, tout en verre (aujourd'hui).
var glass_style: int = 1
## Largeur d'un module de mur-rideau, et hauteur du parapet en haut de chaque gradin.
var module_width: float = 1.52
var parapet_height: float = 1.1
## Teintes du verre, des allèges et du métal.
var glass_tint: Color = Color(0.62, 0.74, 0.72)
var spandrel_color: Color = Color(0.12, 0.15, 0.16)
var metal_color: Color = Color(0.62, 0.63, 0.64)
#@ 11+
## Graine de la tour : décale les motifs et change le tirage des pièces derrière les vitres.
var variation_seed: int = 0
## Petits bois des fenêtres : carreaux du châssis du haut, puis du bas (colonnes, rangées).
var upper_lights: Vector2i = Vector2i(1, 1)
var lower_lights: Vector2i = Vector2i(1, 1)
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute.
var quality: int = 2
## Ce que la façade lointaine doit savoir : la taille des fenêtres des étages, le haut du socle.
var window_size: Vector2 = Vector2(1.2, 1.9)
var stone_top: float = 0.0
#@ all

# --- Matériaux : à lire après build() ---------------------------------------------

## Les murs de brique.
var brick: ShaderMaterial
#@ 6+
## La pierre du socle : le même shader que la brique, avec d'autres nombres.
var stone: ShaderMaterial
#@ all
## Le noyau sombre qu'on aperçoit par les baies, et les toits.
var core: StandardMaterial3D
#@ 4+
## Toutes les fenêtres : un seul matériau. Chaque fenêtre tire elle-même son châssis levé ou
## non, sa pièce, son store.
var window: ShaderMaterial
#@ 7+
## Le mur-rideau des tours de verre.
var curtain: ShaderMaterial
## Le dallage de la place.
var paving: ShaderMaterial
#@ 8+
## Le métal des ailettes, des chaperons et de la marquise des tours de verre.
var metal: StandardMaterial3D
#@ 8-9
## Le bronze de la marquise de la tour de brique.
var bronze: StandardMaterial3D
#@ 10+
## Le bronze de la marquise, de l'entrée et des portes tambour : poli à hauteur de main.
var bronze: ShaderMaterial
## Vitrines, portes vitrées, verre des portes tambour : le shader de la fenêtre, avec un cadre
## de bronze. La donnée de chaque instance dit quelle vitre dessiner.
var shop_window: ShaderMaterial
## Le buis des jardinières de la place.
var hedge: StandardMaterial3D
#@ 13+
## De loin, toute une façade de brique sur un rectangle.
var far_facade: ShaderMaterial
#@ 10+
#@ 8+
#@ 9+
## Le couronnement : cuivre, acier inoxydable, ventelles, bois du château d'eau.
var copper: ShaderMaterial
var steel: ShaderMaterial
var louvres: ShaderMaterial
var tank_wood: ShaderMaterial
## L'acier sombre du pied du château d'eau.
var dark_steel: StandardMaterial3D
## L'étanchéité des toits et des terrasses.
var roofing: StandardMaterial3D
## Le verre de la couronne de la tour tout en verre : le shader du mur-rideau, en mode couronne.
var crown_glass: ShaderMaterial
#@ all

#@ 10+

# Matériaux fabriqués à la demande, un par teinte.
var _plain_colors: Dictionary[Color, StandardMaterial3D] = {}
#@ all


## Fabrique tous les matériaux d'après les réglages.
func build() -> void:
#@ 11+
	# Décalage des motifs, tiré de la graine : deux tours voisines n'ont pas les mêmes briques ni
	# les mêmes taches aux mêmes endroits. Et la graine du tirage des pièces.
	var offset: Vector2 = Vector2(float(variation_seed) * 1.37, float(variation_seed) * 0.61)
	var seed_value: float = float(variation_seed)
#@ 2
	# Chaque clé du dictionnaire est le nom d'un « uniform » du fichier .gdshader.
	brick = _shader_material(BRICK_SHADER, {"brick_color": brick_color})
#@ 3+
	# La seconde teinte des briques suit la première, plus sombre et plus rouge : ce sont les
	# briques plus cuites.
	var brick_2: Color = Color(brick_color.r * 0.82, brick_color.g * 0.72, brick_color.b * 0.70)
	# Chaque clé du dictionnaire est le nom d'un « uniform » du fichier .gdshader.
	brick = _shader_material(BRICK_SHADER, {
		"brick_color": brick_color,
		"brick_color_2": brick_2,
		"grime": grime,
#@ 11+
		"pattern_offset": offset,
#@ 3+
	})
#@ 6+
	# La pierre : des blocs de 1,50 m sur 0,61 m (deux pieds de haut), sans rangs de boutisses,
	# un joint plus fin et plus clair, une teinte plus égale, aucun bloc plus cuit.
	stone = _shader_material(BRICK_SHADER, {
		"brick_size": Vector2(1.5, 0.61),
		"header_every": 0,
		"joint_width": 0.006,
		"joint_recess": 0.003,
		"bevel": 0.004,
		"brick_color": stone_color,
		"brick_color_2": Color(stone_color.r * 0.94, stone_color.g * 0.93, stone_color.b * 0.9),
		"joint_color": stone_color.lightened(0.15),
		"brick_variation": 0.25,
		"dark_bricks": 0.0,
		"grime": grime,
#@ 11+
		"pattern_offset": offset,
#@ 6+
	})
#@ 4

	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color})
#@ 5

	window = _shader_material(WINDOW_SHADER, {
		"frame_color": frame_color,
		"floor_height": floor_height,
		"sill_height": sill_height,
		"bay_width": bay_width,
	})
#@ 6+

	window = _shader_material(WINDOW_SHADER, {
		"frame_color": frame_color,
		"floor_height": floor_height,
		"sill_height": sill_height,
		"bay_width": bay_width,
		"ground_height": ground_height,
		"ground_sill": ground_sill,
#@ 11+
		"seed": seed_value,
		"upper_lights": upper_lights,
		"lower_lights": lower_lights,
#@ 6+
	})
#@ 7+

	# Le mur-rideau. Les deux tours de verre ont le même shader ; seuls les nombres changent.
	# En 1961, une allège opaque de plus d'un mètre à chaque étage, des meneaux épais, un verre
	# émaillé mat. Aujourd'hui, du verre du sol au plafond : il ne reste qu'une bande de verre
	# sombre devant la dalle et le faux plafond, aussi brillante que le reste.
	var all_glass: bool = glass_style == 2
	curtain = _shader_material(CURTAIN_SHADER, {
		"module_width": module_width,
		"mullion_width": 0.05 if all_glass else 0.07,
		"floor_height": floor_height,
		"ground_height": ground_height,
		"parapet_height": parapet_height,
		"sill_height": 0.0 if all_glass else 0.8,
		"head_band": 0.6 if all_glass else 0.45,
		"glass_spandrels": all_glass,
		"metal_color": metal_color,
		"spandrel_color": spandrel_color,
		"glass_tint": glass_tint,
		"reflectivity": 0.95 if all_glass else 0.85,
		# Les plateaux de bureaux d'une tour de verre sont plus profonds qu'en 1916.
		"room_depth": 12.0,
#@ 11+
		"seed": seed_value,
#@ 7+
	})
	# La place : encore le shader de brique, couché, avec des dalles de granit de 0,90 × 0,60 m.
	paving = _shader_material(BRICK_SHADER, {
		"brick_size": Vector2(0.9, 0.6),
		"header_every": 0,
		"joint_width": 0.008,
		"joint_recess": 0.002,
		"brick_color": Color(0.60, 0.59, 0.57),
		"brick_color_2": Color(0.52, 0.51, 0.50),
		"joint_color": Color(0.40, 0.40, 0.40),
		"brick_variation": 0.4,
		"dark_bricks": 0.0,
		"grime": grime,
		"streaks": 0.0,
		"ground_dirt": 0.0,
	})
#@ all

	# Ce qui n'a pas besoin de shader : un matériau uni ordinaire.
	core = _plain(Color(0.06, 0.06, 0.07), 0.9, 0.0)
#@ 8+
	metal = _plain(metal_color, 0.35, 0.8)
#@ 8-9
	bronze = _plain(Color(0.42, 0.30, 0.18), 0.4, 0.85)
#@ 10+
	bronze = _shader_material(BRONZE_SHADER, {})
	hedge = _plain(Color(0.14, 0.27, 0.11), 0.9, 0.0)
	# Les vitres du rez-de-chaussée : le matériau des fenêtres, copié, avec un cadre de bronze et
	# des pièces plus profondes. duplicate() copie aussi tous les réglages du shader.
	shop_window = window.duplicate() as ShaderMaterial
	shop_window.set_shader_parameter("frame_color", Color(0.30, 0.22, 0.14))
	shop_window.set_shader_parameter("room_depth", 9.0)
	shop_window.set_shader_parameter("open_share", 0.0)
#@ 9+
	dark_steel = _plain(Color(0.12, 0.12, 0.13), 0.5, 0.6)
	roofing = _plain(Color(0.20, 0.20, 0.21), 0.95, 0.0)

	# Le couronnement : un shader, quatre matières.
	copper = _shader_material(CROWN_SHADER, {"finish": FINISH_COPPER, "base_color": Color(0.70, 0.42, 0.22), "pitch": 0.45})
	steel = _shader_material(CROWN_SHADER, {"finish": FINISH_STEEL, "base_color": Color(0.76, 0.77, 0.79), "pitch": 0.3})
	louvres = _shader_material(CROWN_SHADER, {"finish": FINISH_LOUVRES, "base_color": metal_color, "pitch": 0.15})
	tank_wood = _shader_material(CROWN_SHADER, {"finish": FINISH_WOOD, "base_color": Color(0.46, 0.39, 0.31), "pitch": 0.12})
	# La couronne de verre : le mur-rideau, mêmes réglages, en mode couronne.
	crown_glass = curtain.duplicate() as ShaderMaterial
	crown_glass.set_shader_parameter("crown", true)
#@ 13+

	# La façade lointaine : les mêmes nombres que la brique, la pierre et la fenêtre, pour que de
	# loin elle ait leur teinte moyenne. Les bandeaux d'enseigne y ont la moyenne des teintes de
	# la palette.
	var fascia: Color = Color(0.0, 0.0, 0.0)
	for color: Color in Palette.FASCIA_COLORS:
		fascia += color / float(Palette.FASCIA_COLORS.size())
	far_facade = _shader_material(FAR_SHADER, {
		"wall_color": brick_color,
		"wall_color_2": brick_2,
		"stone_color": stone_color,
		"stone_color_2": Color(stone_color.r * 0.94, stone_color.g * 0.93, stone_color.b * 0.9),
		"grime": grime,
		"pattern_offset": offset,
		"stone_top": stone_top,
		"bay_width": bay_width,
		"window_size": window_size,
		"sill_height": sill_height,
		"floor_height": floor_height,
		"ground_height": ground_height,
		"frame_color": frame_color,
		"upper_lights": upper_lights,
		"lower_lights": lower_lights,
		"fascia_color": fascia,
		"seed": seed_value,
	})
	set_quality(quality)
#@ 9+
#@ 5+


#@ 5-6
## 0 : jour, 1 : nuit, pour toutes les fenêtres de la tour.
func set_night(value: float) -> void:
	window.set_shader_parameter("night", value)
#@ 7-8
## 0 : jour, 1 : nuit, pour toutes les fenêtres et tous les murs-rideaux de la tour.
func set_night(value: float) -> void:
	for material: ShaderMaterial in [window, curtain]:
		material.set_shader_parameter("night", value)
#@ 9+
#@ 9
## 0 : jour, 1 : nuit, pour les fenêtres, les murs-rideaux et le couronnement.
func set_night(value: float) -> void:
	for material: ShaderMaterial in [window, curtain, crown_glass, copper, steel]:
		material.set_shader_parameter("night", value)
#@ 10+
#@ 10-12
## 0 : jour, 1 : nuit, pour les fenêtres, les vitrines, les murs-rideaux et le couronnement.
func set_night(value: float) -> void:
	for material: ShaderMaterial in [window, shop_window, curtain, crown_glass, copper, steel]:
		material.set_shader_parameter("night", value)
#@ 13+
## 0 : jour, 1 : nuit, pour les fenêtres, les vitrines, les murs-rideaux, le couronnement et
## les façades lointaines.
func set_night(value: float) -> void:
	for material: ShaderMaterial in [window, shop_window, curtain, crown_glass, copper, steel, far_facade]:
		material.set_shader_parameter("night", value)


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Les murs (brique, pierre,
## dallage) calculent moins de bruit ; les vitres dessinent moins de choses dans leurs pièces.
func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	for material: ShaderMaterial in [brick, stone, paving, window, shop_window, curtain, crown_glass, far_facade]:
		if material != null:
			material.set_shader_parameter("quality", quality)
#@ 10+


## Peinture d'une teinte donnée : bandeaux d'enseigne. Un matériau par teinte, fabriqué à la
## première demande : deux boutiques de même teinte partagent le leur.
func lacquer(color: Color) -> StandardMaterial3D:
	if not _plain_colors.has(color):
		_plain_colors[color] = _plain(color, 0.45, 0.1)
	return _plain_colors[color]
#@ 9+


## Projecteurs du couronnement : posés à la hauteur « base », ils éclairent sur « reach »
## mètres vers le haut. « energy » : leur force, 0 pour les éteindre.
func set_floodlights(base: float, reach: float, energy: float) -> void:
	for material: ShaderMaterial in [copper, steel]:
		material.set_shader_parameter("flood_base", base)
		material.set_shader_parameter("flood_reach", maxf(reach, 1.0))
		material.set_shader_parameter("flood_energy", energy)


## Hauteur du fond de la cuve du château d'eau : ses cerclages se resserrent vers le bas, là où
## l'eau pousse le plus fort ; le shader du bois a besoin de savoir où la cuve commence.
func set_tank_base(y: float) -> void:
	tank_wood.set_shader_parameter("tank_base", y)
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
