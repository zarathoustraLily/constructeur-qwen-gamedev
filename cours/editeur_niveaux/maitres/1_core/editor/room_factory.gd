class_name RoomFactory
extends RefCounted
## La fabrique des salles neuves. Une salle reçoit à sa création un identifiant tiré de son nom (minuscules, sans accents,
## des tirets bas à la place des espaces et des signes), unique dans le projet ; cet identifiant est aussi le nom de son
## fichier, et ne change plus jamais : renommer une salle ne change que son nom affiché. Une salle neuve a son contour
## de collision, le départ du héros au milieu du bord bas, et rien d'autre.

## L'identifiant d'une salle dont le nom ne donne rien d'utilisable.
const FALLBACK_ID: String = "salle"
## La distance entre le départ du héros et le bord bas d'une salle neuve, en mètres.
const HERO_MARGIN_M: float = 2.0

var _not_word: RegEx = RegEx.create_from_string("[^a-z0-9]+")


## Un identifiant tiré de `display_name`, absent de `existing` (« _2 », « _3 »… si besoin).
func id_from_name(display_name: String, existing: PackedStringArray) -> StringName:
	var base: String = _not_word.sub(AssetSearch.normalize(display_name), "_", true).strip_edges().trim_prefix("_") \
			.trim_suffix("_")
	if base.is_empty():
		base = FALLBACK_ID
	var candidate: String = base
	var rank: int = 1
	while existing.has(candidate):
		rank += 1
		candidate = "%s_%d" % [base, rank]
	return StringName(candidate)


## Une salle neuve d'identifiant `room_id`, de nom `display_name`, de taille `size_m` (mètres), avec les calques `layers`.
static func new_room(room_id: StringName, display_name: String, size_m: Vector2,
		layers: PackedStringArray) -> RoomData:
	var room: RoomData = RoomData.new()
	room.id = room_id
	room.display_name = display_name
	room.size_m = size_m
	room.layers = layers
	room.collisions = [PackedVector2Array([Vector2.ZERO, Vector2(size_m.x, 0.0), size_m, Vector2(0.0, size_m.y)])]
	room.hero_start = Vector3(size_m.x / 2.0, 0.0, maxf(size_m.y - HERO_MARGIN_M, 0.0))
	return room
