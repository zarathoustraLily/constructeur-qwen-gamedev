class_name RoomData
extends Resource
## Une salle du jeu, telle que l'éditeur l'écrit et que le jeu la lit (`5_data/salles/<id>.tres`).
## Les choses posées sont rangées en tableaux compacts, un tableau par champ, tous de la même longueur : la chose n° i a
## l'identifiant `thing_ids[i]`, la position `thing_positions[i]`, et ainsi de suite. Une salle de plusieurs centaines
## de choses tient ainsi dans une seule ressource, sans une sous-ressource par chose, et se charge d'un bloc.
## Les champs qu'un autre outil a ajoutés à une chose, et que l'éditeur ne connaît pas, restent dans `thing_extras`,
## tels quels : l'éditeur les montre « non édités » et ne les réécrit jamais.

## Les rôles qu'un point d'apparition peut prendre.
const SPAWN_ROLES: Array[String] = ["melee", "distance", "tous"]
## Un tour complet, en degrés : une rotation va de 0 (compris) à un tour (exclu).
const FULL_TURN: float = 360.0
## Le nombre minimal de sommets d'une forme de collision.
const MIN_POLYGON_POINTS: int = 3

## Identifiant de la salle, en snake_case, jamais renommé.
@export var id: StringName = &""
## Nom affiché.
@export var display_name: String = ""
## Taille de la salle en mètres : largeur en x, profondeur en z.
@export var size_m: Vector2 = Vector2.ZERO
## Les calques, du plus bas au plus haut : une chose se dessine dans l'ordre de son calque, puis de son rang.
@export var layers: PackedStringArray = PackedStringArray()

@export_group("Choses")
## L'identifiant stable de chaque chose : il ne change jamais, même quand l'ordre des tableaux change.
@export var thing_ids: PackedInt32Array = PackedInt32Array()
## Le nom de chaque chose.
@export var thing_names: PackedStringArray = PackedStringArray()
## L'asset du catalogue que montre chaque chose.
@export var thing_assets: PackedStringArray = PackedStringArray()
## Le calque de chaque chose (un nom de `layers`).
@export var thing_layers: PackedStringArray = PackedStringArray()
## La position de chaque chose, en mètres (y vers le haut).
@export var thing_positions: PackedVector3Array = PackedVector3Array()
## La rotation de chaque chose autour de l'axe vertical, en degrés.
@export var thing_rotations: PackedFloat32Array = PackedFloat32Array()
## L'échelle de chaque chose (1 : la taille du catalogue).
@export var thing_scales: PackedFloat32Array = PackedFloat32Array()
## Le facteur de parallaxe de chaque chose (1 : au sol ; plus grand : plus près de la caméra).
@export var thing_parallax: PackedFloat32Array = PackedFloat32Array()
## Le décalage de teinte, de saturation et de valeur de chaque chose.
@export var thing_hsv: PackedVector3Array = PackedVector3Array()
## La couleur qui multiplie chaque chose.
@export var thing_colors: PackedColorArray = PackedColorArray()
## 1 si la chose est active, 0 si elle est cachée en jeu.
@export var thing_active: PackedByteArray = PackedByteArray()
## La hauteur de chaque chose au-dessus du sol, en mètres.
@export var thing_heights: PackedFloat32Array = PackedFloat32Array()
## L'identifiant de la chose à laquelle chaque chose est attachée, 0 si aucune.
@export var thing_parents: PackedInt32Array = PackedInt32Array()
## Le rang de chaque chose dans son calque : à calque égal, le plus grand se dessine par-dessus.
@export var thing_sort: PackedInt32Array = PackedInt32Array()
## Les champs inconnus de l'éditeur, par identifiant de chose : un objet JSON, gardé tel quel.
@export var thing_extras: Dictionary[int, String] = {}

@export_group("Collisions")
## Les formes infranchissables : un polygone par forme, en mètres (x, z) ; le premier est le contour de la salle.
@export var collisions: Array[PackedVector2Array] = []

@export_group("Apparitions")
## Où le héros entre dans la salle.
@export var hero_start: Vector3 = Vector3.ZERO
## Les points d'apparition des ennemis.
@export var spawn_positions: PackedVector3Array = PackedVector3Array()
## Le rôle de chaque point (`SPAWN_ROLES`) : quels ennemis peuvent y apparaître.
@export var spawn_roles: PackedStringArray = PackedStringArray()

@export_group("Rencontre")
## Les ennemis que la rencontre de cette salle peut tirer : des identifiants de `5_data/ennemis/`.
@export var encounter_pool: PackedStringArray = PackedStringArray()
## La profondeur de la salle dans la course : elle règle le plafond des vagues.
@export var encounter_depth: int = 0

@export_group("Effets")
## Les effets placés : des identifiants de `5_data/effets/`.
@export var effect_ids: PackedStringArray = PackedStringArray()
## La position de chaque effet placé, en mètres.
@export var effect_positions: PackedVector3Array = PackedVector3Array()


## Le nombre de choses de la salle.
func thing_count() -> int:
	return thing_ids.size()


## L'indice de la chose `thing_id` dans les tableaux, ou -1.
func index_of(thing_id: int) -> int:
	return thing_ids.find(thing_id)


## Les erreurs de la salle, une phrase par erreur ; vide si la salle est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("id : identifiant en snake_case requis")
	if size_m.x <= 0.0 or size_m.y <= 0.0:
		errors.append("size_m : largeur et profondeur positives requises")
	if layers.is_empty():
		errors.append("layers : au moins un calque requis")
	var lengths: Array[String] = _column_errors()
	errors.append_array(lengths)
	if lengths.is_empty():
		errors.append_array(_thing_errors())
	for index: int in collisions.size():
		if collisions[index].size() < MIN_POLYGON_POINTS:
			errors.append("collision %d : au moins %d sommets requis" % [index, MIN_POLYGON_POINTS])
#@ 10+
		elif not CollisionTools.is_simple(collisions[index]):
			errors.append("collision %d : des côtés se croisent" % index)
#@ all
	if spawn_roles.size() != spawn_positions.size():
		errors.append("spawn_roles : %d rôles pour %d points" % [spawn_roles.size(), spawn_positions.size()])
	for index: int in spawn_roles.size():
		if not SPAWN_ROLES.has(spawn_roles[index]):
			errors.append("apparition %d : rôle inconnu %s" % [index, spawn_roles[index]])
	if encounter_depth < 0:
		errors.append("encounter_depth : profondeur positive ou nulle requise")
	if effect_ids.size() != effect_positions.size():
		errors.append("effect_positions : %d positions pour %d effets" % [effect_positions.size(), effect_ids.size()])
	return errors


func _column_errors() -> Array[String]:
	var count: int = thing_ids.size()
	var sizes: Dictionary[String, int] = {
		"thing_names": thing_names.size(), "thing_assets": thing_assets.size(), "thing_layers": thing_layers.size(),
		"thing_positions": thing_positions.size(), "thing_rotations": thing_rotations.size(),
		"thing_scales": thing_scales.size(), "thing_parallax": thing_parallax.size(), "thing_hsv": thing_hsv.size(),
		"thing_colors": thing_colors.size(), "thing_active": thing_active.size(),
		"thing_heights": thing_heights.size(), "thing_parents": thing_parents.size(), "thing_sort": thing_sort.size(),
	}
	var errors: Array[String] = []
	for column: String in sizes:
		if sizes[column] != count:
			errors.append("%s : %d valeurs pour %d choses" % [column, sizes[column], count])
	return errors


func _thing_errors() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary[int, bool] = {}
	for thing_id: int in thing_ids:
		if thing_id <= 0:
			errors.append("thing_ids : identifiant %d, positif requis" % thing_id)
		elif seen.has(thing_id):
			errors.append("thing_ids : identifiant %d en double" % thing_id)
		seen[thing_id] = true
	for index: int in thing_ids.size():
		var label: String = "chose %d" % thing_ids[index]
		if not layers.has(thing_layers[index]):
			errors.append("%s : calque inconnu %s" % [label, thing_layers[index]])
		if thing_scales[index] <= 0.0:
			errors.append("%s : échelle positive requise" % label)
		if thing_rotations[index] < 0.0 or thing_rotations[index] >= FULL_TURN:
			errors.append("%s : rotation hors de [0, 360[" % label)
		if thing_active[index] > 1:
			errors.append("%s : actif vaut 0 ou 1" % label)
		var parent: int = thing_parents[index]
		if parent != 0 and (parent == thing_ids[index] or not seen.has(parent)):
			errors.append("%s : parent %d introuvable" % [label, parent])
	for thing_id: int in thing_extras:
		if not seen.has(thing_id):
			errors.append("thing_extras : chose %d introuvable" % thing_id)
			continue
		# JSON.parse_string écrirait son erreur dans la console ; une instance de JSON la garde pour elle.
		var parser: JSON = JSON.new()
		if parser.parse(thing_extras[thing_id]) != OK or not parser.data is Dictionary:
			errors.append("chose %d : champs inconnus illisibles" % thing_id)
	return errors
