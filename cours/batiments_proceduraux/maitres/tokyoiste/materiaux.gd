@tool
extends RefCounted
## Matériaux de l'immeuble tokyoïte : pour chaque matière, un shader et ses réglages.
## {STATUS}
##
## Pourquoi un script à part : la géométrie et la matière sont deux métiers. Le script de
## l'immeuble dit OÙ est le carrelage ; celui-ci dit à quoi il RESSEMBLE.
##
## Mode d'emploi, côté immeuble :
##     _materials = Materials.new()
##     _materials.tile_color = tile_color       # 1. on règle
##     _materials.build()                       # 2. on fabrique
##     _mesh.box(taille, centre, _materials.facade)  # 3. on s'en sert
##
## Un ShaderMaterial, c'est un shader plus ses réglages.
#@ 9+ quiet
## Le même shader sert à plusieurs matériaux : le béton des murs latéraux et celui des
## ouvrages du toit sortent du même fichier .gdshader, avec d'autres nombres.
#@ all

const TILE_SHADER: Shader = preload("{SHADER}_carrelage.gdshader")
#@ 4+
const WINDOW_SHADER: Shader = preload("{SHADER}_fenetre.gdshader")
#@ 7+
const RAILING_SHADER: Shader = preload("{SHADER}_garde_corps.gdshader")
#@ 9+
const CONCRETE_SHADER: Shader = preload("{SHADER}_beton.gdshader")
#@ 10+
const SHUTTER_SHADER: Shader = preload("{SHADER}_rideau.gdshader")
const SIGN_SHADER: Shader = preload("{SHADER}_enseigne.gdshader")
#@ 11+

## Revêtements de la façade sur rue.
const CLADDING_TILE: int = 0
const CLADDING_CONCRETE: int = 1
const CLADDING_PAINT: int = 2
#@ all

# --- Réglages : l'immeuble les remplit avant d'appeler build() ----------------

#@ 2-10
## Teinte du carrelage.
var tile_color: Color = Color(0.80, 0.78, 0.72)
#@ 11+
## Teinte du revêtement de façade : carrelage, béton ou peinture.
var tile_color: Color = Color(0.80, 0.78, 0.72)
## Revêtement de la façade : CLADDING_TILE, CLADDING_CONCRETE ou CLADDING_PAINT.
var cladding: int = CLADDING_TILE
## Taille d'un carreau, joint compris, et décalage d'un rang sur deux (0.5 : joints croisés).
var tile_size: Vector2 = Vector2(0.235, 0.068)
var tile_stagger: float = 0.5
#@ 3+
## Encrassement des murs, de 0 (lavés) à 1 (très sales).
var grime: float = 0.3
#@ 4+
## Teinte des menuiseries d'aluminium.
var frame_color: Color = Color(0.62, 0.63, 0.64)
#@ 5
## Hauteur de l'allège des fenêtres : le shader en a besoin pour placer le sol de la pièce.
var sill_height: float = 0.9
#@ 11+
## Graine de l'immeuble : décale les motifs et change le tirage des pièces.
var variation_seed: int = 0
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute.
var quality: int = 2
#@ all

# --- Matériaux : à lire après build() -------------------------------------------

#@ 2-10
## Revêtement de la façade sur rue : le carrelage.
var facade: ShaderMaterial
#@ 11+
## Revêtement de la façade sur rue : carrelage, béton ou peinture, selon « cladding ».
var facade: ShaderMaterial
#@ 2-8
## Murs latéraux et volume arrière : un mortier uni.
var side: StandardMaterial3D
#@ 9+
## Murs latéraux, volume arrière et ouvrages du toit : du béton.
var side: ShaderMaterial
## Dalles et petits ouvrages : un béton plus lisse, sans reprises de bétonnage.
var concrete: ShaderMaterial
## Étanchéité du toit-terrasse.
var roofing: StandardMaterial3D
## Résine du réservoir d'eau.
var tank: StandardMaterial3D
#@ 4+
## Toutes les fenêtres des étages : un seul matériau, la pièce est choisie par instance.
var window: ShaderMaterial
#@ 7+
## Garde-corps et grilles : un seul matériau, le motif est choisi par instance.
var railing: ShaderMaterial
## Aluminium nu : mains courantes, appuis, couvertines.
var aluminium: StandardMaterial3D
## Carrosserie des climatiseurs.
var appliance: StandardMaterial3D
#@ 8+
## Tuyaux de descente d'eau.
var pipe: StandardMaterial3D
#@ 10+
## Vitrines et portes du rez-de-chaussée : même shader, pièce plus profonde, menuiserie de la
## teinte donnée à chaque instance.
var shop_window: ShaderMaterial
## Rideaux métalliques.
var shutter: ShaderMaterial
## Enseignes et distributeurs.
var signage: ShaderMaterial
## Acier sombre : caissons d'enseigne, potences, coffres de rideau.
var dark_metal: StandardMaterial3D
## Papier rouge d'une lanterne : il s'éclaire la nuit.
var lantern: StandardMaterial3D
#@ all

#@ 10+
# Matériaux fabriqués à la demande, un par teinte : deux devantures brunes partagent le leur.
var _plain_colors: Dictionary[Color, StandardMaterial3D] = {}
#@ all


## Fabrique tous les matériaux d'après les réglages.
func build() -> void:
#@ 11+
	# Décalage des motifs, tiré de la graine : deux immeubles voisins n'ont pas les mêmes
	# carreaux ni les mêmes taches aux mêmes endroits.
	var offset: Vector2 = Vector2(float(variation_seed) * 1.37, float(variation_seed) * 0.61)
#@ 3+
	# La seconde teinte des carreaux suit la première, un peu plus sombre et plus chaude.
	var tile_2: Color = Color(tile_color.r * 0.875, tile_color.g * 0.86, tile_color.b * 0.83)
#@ 2-10
	# Chaque clé du dictionnaire est le nom d'un « uniform » du fichier .gdshader.
	facade = _shader_material(TILE_SHADER, {
		"tile_color": tile_color,
#@ 3-10
		"tile_color_2": tile_2,
		"grime": grime,
#@ 2-10
	})
#@ 11+
	# Chaque clé du dictionnaire est le nom d'un « uniform » du fichier .gdshader.
	if cladding == CLADDING_TILE:
		facade = _shader_material(TILE_SHADER, {
			"tile_color": tile_color,
			"tile_color_2": tile_2,
			"tile_size": tile_size,
			"stagger": tile_stagger,
			# Un petit carreau a un joint plus fin.
			"joint_width": 0.008 if tile_size.y > 0.05 else 0.005,
			"grime": grime,
			"pattern_offset": offset,
		})
	else:
		# Béton brut, ou enduit peint : le même shader, sans l'empreinte du coffrage.
		var raw: bool = cladding == CLADDING_CONCRETE
		facade = _shader_material(CONCRETE_SHADER, {
			"concrete_color": Color(0.62, 0.62, 0.60) if raw else tile_color,
			"formwork": 1.0 if raw else 0.0,
			"grime": grime,
			"streaks": 0.5 if raw else 0.35,
			"pattern_offset": offset,
		})
#@ 4+

#@ 4
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color})
#@ 5
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color, "sill_height": sill_height})
#@ 6-10
	# La hauteur de l'allège ne passe plus par le matériau : chaque fenêtre donne la sienne au
	# shader, par la donnée de son instance.
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color})
#@ 11+
	# « seed » change le tirage des pièces derrière les fenêtres.
	var seed_value: float = float(variation_seed)
	window = _shader_material(WINDOW_SHADER, {"frame_color": frame_color, "seed": seed_value})
#@ 10+
	shop_window = _shader_material(WINDOW_SHADER, {
#@ 11+
		"seed": seed_value,
#@ 10+
		"frame_color_from_instance": true,
		"room_depth": 6.0,
		"ceiling_height": 2.9,
		"dressing": 0.0,
	})
#@ 7+

	railing = _shader_material(RAILING_SHADER, {"metal_color": frame_color})
#@ 9+

	# Le béton des murs latéraux, puis le même shader avec d'autres nombres pour les dalles.
	side = _shader_material(CONCRETE_SHADER, {
		"grime": minf(grime + 0.1, 1.0),
#@ 11+
		"pattern_offset": offset,
#@ 9+
	})
	concrete = _shader_material(CONCRETE_SHADER, {
		"lift_height": 0.0,
		"panel_variation": 0.2,
		"grime": grime,
#@ 11+
		"pattern_offset": offset,
#@ 9+
	})
#@ 10+

	shutter = _shader_material(SHUTTER_SHADER, {"grime": 0.3 + 0.5 * grime})
	signage = _shader_material(SIGN_SHADER, {})
#@ all

	# Ce qui n'a pas besoin de shader : un matériau uni ordinaire.
#@ 2-8
	side = _plain(Color(0.60, 0.60, 0.58), 0.95, 0.0)
#@ 7+
	aluminium = _plain(Color(frame_color.r, frame_color.g, frame_color.b), 0.4, 0.7)
	appliance = _plain(Color(0.80, 0.80, 0.76), 0.6, 0.0)
#@ 8+
	pipe = _plain(Color(0.47, 0.48, 0.48), 0.6, 0.0)
#@ 9+
	roofing = _plain(Color(0.34, 0.40, 0.36), 0.9, 0.0)
	tank = _plain(Color(0.84, 0.82, 0.72), 0.5, 0.0)
#@ 10+
	dark_metal = _plain(Color(0.10, 0.10, 0.11), 0.5, 0.5)
	lantern = _plain(Color(0.72, 0.08, 0.06), 0.8, 0.0)
	lantern.emission_enabled = true
	lantern.emission = Color(0.9, 0.10, 0.05)
	lantern.emission_energy_multiplier = 0.0
#@ 13+
	set_quality(quality)


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Seuls les murs ont ce
## réglage : ils couvrent presque toute la façade, donc presque tous les pixels.
func set_quality(level: int) -> void:
	quality = clampi(level, 0, 2)
	for material: ShaderMaterial in [facade, side, concrete]:
		if material != null:
			material.set_shader_parameter("quality", quality)
#@ 5+


#@ 5-9
## 0 : jour, 1 : nuit, pour toutes les fenêtres de l'immeuble.
func set_night(value: float) -> void:
	window.set_shader_parameter("night", value)
#@ 10+
## 0 : jour, 1 : nuit : les fenêtres, les enseignes, les lanternes.
func set_night(value: float) -> void:
	for material: ShaderMaterial in [window, shop_window, signage]:
		if material != null:
			material.set_shader_parameter("night", value)
	if lantern != null:
		lantern.emission_energy_multiplier = 1.4 * value


## Métal laqué ou panneau uni d'une teinte donnée : habillages de devanture, toiles.
func lacquer(color: Color) -> StandardMaterial3D:
	if not _plain_colors.has(color):
		_plain_colors[color] = _plain(color, 0.5, 0.2)
	return _plain_colors[color]
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
