@tool
extends Node3D
## Un quartier d'affaires de Manhattan : une avenue, des rues transversales, des îlots, et une
## tour sur chaque terrain.
## {STATUS}
##
## La trame est celle du plan de 1811 : une avenue de 100 pieds du sud au nord, des rues de
## 60 pieds d'est en ouest, des îlots de 200 pieds entre deux rues. Les largeurs de rue sont
## comptées d'un alignement à l'autre : elles comprennent les trottoirs.
##
## Chaque îlot porte, de chaque côté de l'avenue :
##   - un terrain sur l'avenue, entre deux rues : sa tour regarde l'avenue ;
##   - derrière lui, un terrain traversant, d'une rue à l'autre : sa tour regarde la rue au nord.
## Chaque tour est le script de l'étape, avec une graine à elle : sa famille (brique de 1916,
## verre de 1961, tout en verre d'aujourd'hui), son couronnement, ses proportions et ses
## teintes sont tirés. Le quartier ne fait que poser des terrains et leur donner leurs rues ;
## chaque tour applique elle-même son règlement.
##
## Au sol : la chaussée, les trottoirs et leurs bordures, les passages piétons, des
## lampadaires, des feux, une cheminée de vapeur et une entrée de métro.
##
## Repère : l'avenue court le long de z, le nord vers -Z ; x = 0 est son axe. Unité : le mètre.
## Limites : un seul sens de lecture des tours (pas de terrain d'angle sur deux avenues), pas
## de voitures, pas de piétons. Les cotes des trottoirs et du mobilier sont plausibles, elles ne
## sont pas relevées.
#@ 13+ quiet
##
## Niveaux de détail (étape 013) : le quartier donne ses distances à toutes ses tours, et range
## son mobilier de la même façon. Ce qui tient debout (lampadaires, feux, cheminée, métro)
## disparaît au-delà de la distance lointaine ; ce qui est à plat (chaussée, trottoirs, bandes
## des passages piétons) reste, mais ne porte pas d'ombre : elle tomberait sous lui.
#@ all

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Tower := preload("{MESH}.gd")
const Palette := preload("{DATA}_palette.gd")
const BRICK_SHADER: Shader = preload("{SHADER}_brique.gdshader")

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Hauteur de la bordure du trottoir.
const CURB: float = 0.15
## Lampadaire : hauteur du mât, saillie de la crosse.
const LAMP_HEIGHT: float = 9.0
const LAMP_REACH: float = 2.2
## Passages piétons : largeur et pas des bandes blanches, longueur des bandes.
const STRIPE: float = 0.6
const STRIPE_PITCH: float = 1.2
const CROSSWALK: float = 3.0

@export_group("Trame")
## Nombre d'îlots le long de l'avenue.
@export_range(1, 8, 1) var block_count: int = 4
## Largeur de l'avenue et des rues, d'un alignement à l'autre, et profondeur d'un îlot.
@export_range(10.0, 50.0, 0.01, "suffix:m") var avenue_width: float = Palette.AVENUE_WIDTH
@export_range(10.0, 40.0, 0.01, "suffix:m") var street_width: float = Palette.STREET_WIDTH
@export_range(30.0, 120.0, 0.01, "suffix:m") var block_depth: float = Palette.BLOCK_DEPTH
## Largeur des trottoirs, pris dans la largeur des rues.
@export_range(2.0, 8.0, 0.01, "suffix:m") var sidewalk_width: float = Palette.SIDEWALK_WIDTH

@export_group("Terrains")
## Profondeur des terrains sur l'avenue, de l'alignement de l'avenue vers l'intérieur de l'îlot.
@export_range(20.0, 80.0, 0.5, "suffix:m") var avenue_lot_depth: float = 45.0
## Largeur des terrains traversants, derrière eux. 0 : pas de second rang.
@export_range(0.0, 80.0, 0.5, "suffix:m") var through_lot_width: float = 40.0

@export_group("Tirages")
## La graine du quartier : chaque tour en tire la sienne.
@export var district_seed: int = 0
#@ 13+

@export_group("Niveaux de détail")
## Les distances des niveaux de détail, données à toutes les tours (voir le script de la tour).
## Le mobilier de la rue disparaît au-delà de la distance lointaine.
@export_range(0.0, 300.0, 1.0, "suffix:m") var near_distance: float = 60.0
@export_range(0.0, 1000.0, 1.0, "suffix:m") var far_distance: float = 250.0
## Chaque gradin de chaque tour pose une boîte d'occultation.
@export var occluders: bool = true
#@ all

## Empreinte des variables au moment de la dernière construction.
var _signature: int = 0
## 0 : jour, 1 : nuit. Gardé pour le redonner aux tours et aux lampes après une reconstruction.
var _night: float = 0.0
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Gardée de la même façon.
var _quality: int = 2
#@ all
var _root: Node3D
var _mesh: MeshBuilder
## Les matériaux du sol et du mobilier, fabriqués à chaque construction.
var _asphalt: StandardMaterial3D
var _sidewalk: ShaderMaterial
var _paint: StandardMaterial3D
var _iron: StandardMaterial3D
var _lamp: StandardMaterial3D
var _signal: StandardMaterial3D
var _steam: StandardMaterial3D
var _globe: StandardMaterial3D


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	if _current_signature() != _signature:
		rebuild()


## 0 : jour, 1 : nuit : les tours, les lampadaires, les globes du métro.
func set_night(value: float) -> void:
	_night = value
	if _root == null:
		return
	for child: Node in _root.get_children():
		if child.has_method("set_night"):
			child.call("set_night", value)
	if _lamp != null:
		_lamp.emission_energy_multiplier = 3.0 * value
		_globe.emission_energy_multiplier = 0.5 + 2.5 * value
#@ 13+


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Le quartier la donne à ses tours
## et au shader des trottoirs, sans rien reconstruire.
func set_quality(level: int) -> void:
	_quality = level
	if _sidewalk != null:
		_sidewalk.set_shader_parameter("quality", level)
	if _root == null:
		return
	for child: Node in _root.get_children():
		if child.has_method("set_quality"):
			child.call("set_quality", level)
#@ all


## Démonte le quartier et le remonte d'après les variables courantes.
func rebuild() -> void:
	_signature = _current_signature()
	for child: Node in get_children(true):
		if child.name == GENERATED_NAME:
			remove_child(child)
			child.queue_free()
	_root = Node3D.new()
	_root.name = GENERATED_NAME
	add_child(_root, false, Node.INTERNAL_MODE_BACK)
	_make_materials()
	_mesh = MeshBuilder.new()
#@ 13+
	_mesh.near_distance = near_distance
	_mesh.far_distance = far_distance
#@ all
	_build_ground()
	_mesh.commit(_root)
	_place_towers()
	set_night(_night)
#@ 13+
	set_quality(_quality)
#@ all


# --- La trame -----------------------------------------------------------------------

## Le pas de la trame le long de l'avenue : un îlot et une rue.
func _pitch() -> float:
	return block_depth + street_width


## Bord sud de l'îlot « block » (le premier est au sud) ; son bord nord est block_depth plus loin
## vers -Z. Le premier îlot commence à une demi-rue au sud de z = 0 + block_depth.
func _block_south(block: int) -> float:
	return block_depth + 0.5 * street_width - float(block) * _pitch()


## Axe de la rue au nord de l'îlot « block ».
func _street_north(block: int) -> float:
	return _block_south(block) - block_depth - 0.5 * street_width


## Distance de l'axe de l'avenue au fond des terrains, de chaque côté.
func _lots_depth() -> float:
	return avenue_lot_depth + through_lot_width


# --- Les tours --------------------------------------------------------------------

## Pose une tour sur chaque terrain. Une tour est un nœud qui porte le script de la tour : on
## règle ses variables, on la place, et elle se construit elle-même en entrant dans la scène.
func _place_towers() -> void:
	var index: int = 0
	for block: int in range(block_count):
		var south: float = _block_south(block)
		var middle: float = south - 0.5 * block_depth
		for side: float in [-1.0, 1.0]:
			# Le terrain sur l'avenue. Sa façade de devant est l'alignement de l'avenue ; la tour
			# est tournée d'un quart de tour pour la regarder. Ses deux rues latérales sont les
			# rues transversales ; derrière lui, le terrain traversant.
			var front: Vector3 = Vector3(side * 0.5 * avenue_width, 0.0, middle)
			var tower: Node3D = _new_tower(index, block_depth, avenue_lot_depth)
			tower.set("street_front", avenue_width)
			tower.set("street_left", street_width)
			tower.set("street_right", street_width)
			tower.set("street_back", 0.0 if through_lot_width > 0.0 else street_width)
			tower.transform = Transform3D(Basis(Vector3.UP, -side * 0.5 * PI), front)
			_root.add_child(tower)
			index += 1
			if through_lot_width <= 0.0:
				continue
			# Le terrain traversant, d'une rue transversale à l'autre. Sa façade de devant regarde
			# la rue au nord : la tour est tournée d'un demi-tour.
			var lot_x: float = side * (0.5 * avenue_width + avenue_lot_depth + 0.5 * through_lot_width)
			var through: Node3D = _new_tower(index, through_lot_width, block_depth)
			through.set("street_front", street_width)
			through.set("street_back", street_width)
			through.set("street_left", 0.0)
			through.set("street_right", 0.0)
			through.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(lot_x, 0.0, south - block_depth))
			_root.add_child(through)
			index += 1


## Une tour neuve, de graine propre, sur un terrain de « width » de façade et « depth » de
## profondeur. Tout ce que la graine sait choisir lui est laissé.
func _new_tower(index: int, width: float, depth: float) -> Node3D:
	var tower: Node3D = Tower.new()
	tower.name = "Tour%02d" % index
	tower.set("lot_width", width)
	tower.set("lot_depth", depth)
	tower.set("variation_seed", district_seed * 1000 + index * 17 + 1)
	tower.set("family_choice", 0)
	tower.set("crown_choice", 0)
	tower.set("window_lights", 0)
	tower.set("random_massing", true)
	tower.set("random_colors", true)
#@ 13+
	tower.set("near_distance", near_distance)
	tower.set("far_distance", far_distance)
	tower.set("occluders", occluders)
#@ all
	return tower


# --- Le sol -------------------------------------------------------------------------

## Les matériaux du sol et du mobilier. Le trottoir : des dalles de béton de cinq pieds sur cinq
## (une cote plausible, pas relevée), dessinées par le shader de la brique, couché.
func _make_materials() -> void:
	_asphalt = _plain(Color(0.13, 0.13, 0.14), 0.92)
	_sidewalk = ShaderMaterial.new()
	_sidewalk.shader = BRICK_SHADER
	var flag: float = 5.0 * Palette.FOOT
	for key: String in ["brick_size", "header_every", "joint_width", "joint_recess", "brick_color", "brick_color_2", "joint_color", "brick_variation", "dark_bricks", "grime", "streaks", "ground_dirt"]:
		var value: Variant = {
			"brick_size": Vector2(flag, flag), "header_every": 0, "joint_width": 0.01, "joint_recess": 0.003,
			"brick_color": Color(0.62, 0.61, 0.58), "brick_color_2": Color(0.55, 0.54, 0.52), "joint_color": Color(0.35, 0.35, 0.34),
			"brick_variation": 0.35, "dark_bricks": 0.0, "grime": 0.45, "streaks": 0.0, "ground_dirt": 0.0,
		}[key]
		_sidewalk.set_shader_parameter(key, value)
	_paint = _plain(Color(0.86, 0.86, 0.82), 0.7)
	_iron = _plain(Color(0.10, 0.12, 0.11), 0.5)
	_iron.metallic = 0.6
	# Les lampes et les globes du métro s'allument la nuit : un matériau émissif, dont on règle
	# la force dans set_night().
	_lamp = _plain(Color(0.9, 0.85, 0.7), 0.4)
	_lamp.emission_enabled = true
	_lamp.emission = Color(1.0, 0.82, 0.55)
	_signal = _plain(Color(0.75, 0.62, 0.10), 0.5)
	_steam = _plain(Color(0.92, 0.42, 0.10), 0.6)
	_globe = _plain(Color(0.20, 0.55, 0.30), 0.3)
	_globe.emission_enabled = true
	_globe.emission = Color(0.25, 0.85, 0.40)


## Chaussée, trottoirs, passages piétons, mobilier.
func _build_ground() -> void:
	var half: float = 0.5 * avenue_width + _lots_depth() + 40.0
	var north: float = _street_north(block_count - 1) - 0.5 * street_width - 40.0
	var south: float = _block_south(0) + street_width + 40.0
#@ 13+
	# La chaussée et les trottoirs : dans toutes les zones, sans ombre portée.
	_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
	# La chaussée : une grande dalle sombre, une bordure plus bas que les trottoirs.
	_mesh.box(Vector3(2.0 * half, 0.3, south - north), Vector3(0.0, -CURB - 0.15, 0.5 * (south + north)), _asphalt)
#@ 12
	for block: int in range(block_count):
		var block_south: float = _block_south(block)
		for side: float in [-1.0, 1.0]:
			# Le trottoir : l'îlot, élargi de la largeur d'un trottoir du côté de l'avenue et des
			# deux rues. Les tours sont posées dessus ; sa tranche fait la bordure.
			var inner: float = 0.5 * avenue_width - sidewalk_width
			var outer: float = 0.5 * avenue_width + _lots_depth() + 20.0
			var size: Vector3 = Vector3(outer - inner, CURB, block_depth + 2.0 * sidewalk_width)
			_mesh.box(size, Vector3(side * 0.5 * (inner + outer), -0.5 * CURB, block_south - 0.5 * block_depth), _sidewalk)
			_build_lamps(side, block_south)
		_build_crosswalks(_street_north(block))
		if block == 0:
			_build_crosswalks(_block_south(0) + 0.5 * street_width)
	_build_steam_stack(Vector3(3.0, -CURB, _block_south(0) - 45.0))
	_build_subway(Vector3(0.5 * avenue_width - 0.5 * sidewalk_width - 0.3, 0.0, _block_south(0) - 55.0))
#@ 13+
	for block: int in range(block_count):
		var block_south: float = _block_south(block)
		for side: float in [-1.0, 1.0]:
			# Le trottoir : l'îlot, élargi de la largeur d'un trottoir du côté de l'avenue et des
			# deux rues. Les tours sont posées dessus ; sa tranche fait la bordure.
			var inner: float = 0.5 * avenue_width - sidewalk_width
			var outer: float = 0.5 * avenue_width + _lots_depth() + 20.0
			var size: Vector3 = Vector3(outer - inner, CURB, block_depth + 2.0 * sidewalk_width)
			_mesh.box(size, Vector3(side * 0.5 * (inner + outer), -0.5 * CURB, block_south - 0.5 * block_depth), _sidewalk)
	# Ces grandes dalles ont leurs propres nœuds : la boîte commune d'un commit() les engloberait
	# avec le mobilier, et les distances du mobilier se compteraient depuis le centre du quartier.
	_mesh.commit(_root)

	# Le mobilier, îlot par îlot : chaque îlot a sa boîte, ses distances se comptent depuis son
	# centre. Ce qui tient debout porte une ombre ; les bandes peintes, non.
	for block: int in range(block_count):
		var block_south: float = _block_south(block)
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
		for side: float in [-1.0, 1.0]:
			_build_lamps(side, block_south)
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
		_build_crosswalks(_street_north(block))
		if block == 0:
			_build_crosswalks(_block_south(0) + 0.5 * street_width)
		_mesh.commit(_root)
	# La cheminée et le métro, chacun avec sa boîte.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
	_build_steam_stack(Vector3(3.0, -CURB, _block_south(0) - 45.0))
	_mesh.commit(_root)
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
	_build_subway(Vector3(0.5 * avenue_width - 0.5 * sidewalk_width - 0.3, 0.0, _block_south(0) - 55.0))
#@ all


## Les deux passages piétons d'un carrefour : l'un traverse l'avenue au sud de la rue, l'autre
## au nord ; et deux autres traversent la rue, dans le prolongement des trottoirs de l'avenue.
## Des bandes blanches parallèles à la circulation.
func _build_crosswalks(street_z: float) -> void:
	var roadway: float = 0.5 * avenue_width - sidewalk_width
	var street_roadway: float = 0.5 * street_width - sidewalk_width
	for end: float in [-1.0, 1.0]:
		var z: float = street_z + end * (street_roadway + 0.6 + 0.5 * CROSSWALK)
		var count: int = floori(2.0 * roadway / STRIPE_PITCH)
		for stripe: int in range(count):
			var x: float = -roadway + (float(stripe) + 0.5) * (2.0 * roadway / float(count))
			_mesh.box(Vector3(STRIPE, 0.01, CROSSWALK), Vector3(x, -CURB + 0.005, z), _paint)
	for side: float in [-1.0, 1.0]:
		var x: float = side * (roadway + 0.3 + 0.5 * CROSSWALK)
		var count: int = floori(2.0 * street_roadway / STRIPE_PITCH)
		for stripe: int in range(count):
			var z: float = street_z - street_roadway + (float(stripe) + 0.5) * (2.0 * street_roadway / float(count))
			_mesh.box(Vector3(CROSSWALK, 0.01, STRIPE), Vector3(x, -CURB + 0.005, z), _paint)


## Lampadaires le long de l'avenue, au bord du trottoir, tous les 30 m environ : un mât, une
## crosse qui avance au-dessus de la chaussée, une lanterne qui s'allume la nuit.
func _build_lamps(side: float, block_south: float) -> void:
	var curb_x: float = side * (0.5 * avenue_width - sidewalk_width + 0.5)
	var count: int = maxi(1, roundi(block_depth / 30.0))
	for index: int in range(count):
		var z: float = block_south - (float(index) + 0.5) * block_depth / float(count)
		_mesh.cone(Vector3(curb_x, 0.5 * LAMP_HEIGHT, z), 0.12, 0.07, LAMP_HEIGHT, _iron, Basis.IDENTITY, 8)
		_mesh.box(Vector3(LAMP_REACH, 0.12, 0.12), Vector3(curb_x - side * 0.5 * LAMP_REACH, LAMP_HEIGHT - 0.1, z), _iron)
		_mesh.box(Vector3(0.7, 0.18, 0.35), Vector3(curb_x - side * LAMP_REACH, LAMP_HEIGHT - 0.25, z), _lamp)
	# Un feu de circulation au coin nord de l'îlot, tourné vers l'avenue.
	var corner: Vector3 = Vector3(curb_x, 0.0, block_south - block_depth - 0.6)
	_mesh.cone(corner + Vector3(0.0, 2.2, 0.0), 0.09, 0.09, 4.4, _iron, Basis.IDENTITY, 8)
	_mesh.box(Vector3(0.35, 1.0, 0.3), corner + Vector3(0.0, 4.0, 0.0), _signal)


## La cheminée de vapeur, rayée orange et blanc, plantée sur la chaussée : le réseau de vapeur
## de Manhattan évacue par là sa vapeur, au-dessus des têtes.
func _build_steam_stack(base: Vector3) -> void:
	_mesh.cone(base + Vector3(0.0, 1.1, 0.0), 0.38, 0.32, 2.2, _steam, Basis.IDENTITY, 12)
	for y: float in [0.6, 1.4]:
		_mesh.cone(base + Vector3(0.0, y + 0.15, 0.0), 0.39 - 0.03 * y, 0.38 - 0.03 * y, 0.3, _paint, Basis.IDENTITY, 12)


## Une entrée de métro sur le trottoir : la trémie de l'escalier, bordée d'une rambarde de
## fonte, et deux globes verts sur leurs poteaux, allumés jour et nuit.
func _build_subway(center: Vector3) -> void:
	var size: Vector2 = Vector2(1.8, 5.0)
	# La trémie : un trou sombre dans le trottoir, figuré par une dalle noire à peine plus haute.
	_mesh.box(Vector3(size.x, 0.02, size.y), center + Vector3(0.0, 0.01, 0.0), _iron)
	for x: float in [-0.5, 0.5]:
		_mesh.box(Vector3(0.06, 1.0, size.y), center + Vector3(x * size.x, 0.5, 0.0), _iron)
	_mesh.box(Vector3(size.x, 1.0, 0.06), center + Vector3(0.0, 0.5, 0.5 * size.y), _iron)
	for x: float in [-0.5, 0.5]:
		var post: Vector3 = center + Vector3(x * size.x, 0.0, -0.5 * size.y)
		_mesh.cone(post + Vector3(0.0, 1.2, 0.0), 0.05, 0.05, 2.4, _iron, Basis.IDENTITY, 8)
		_mesh.cone(post + Vector3(0.0, 2.55, 0.0), 0.2, 0.2, 0.3, _globe, Basis.IDENTITY, 12)


# --- Outils -----------------------------------------------------------------------

func _plain(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


## Empreinte de toutes les variables exportées, comme pour la tour.
func _current_signature() -> int:
	var values: Array[Variant] = []
	var properties: Array[Dictionary] = (get_script() as Script).get_script_property_list()
	for index: int in range(properties.size()):
		var usage: int = properties[index]["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			values.append(get(properties[index]["name"]))
	return hash(values)
