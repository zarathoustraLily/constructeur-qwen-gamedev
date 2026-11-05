class_name Room3DView
extends RoomRenderer
## La salle telle que le jeu la montre : une chose = un `Sprite3D` couché sur le sol (`FlatLayout`), qui affiche la région
## de son asset dans la planche, à sa couleur, posé par son point d'ancrage. Le jeu et la vue rendue de l'éditeur s'en
## servent tous les deux : ce que l'éditeur montre est ce que le jeu affichera. Une chose inactive est cachée en jeu ;
## l'éditeur peut la montrer en transparence (`show_inactive`).

## L'opacité d'une chose inactive, quand l'éditeur les montre.
const INACTIVE_ALPHA: float = 0.35

var _sprites: Dictionary[int, Sprite3D] = {}


## Construit les sprites de `room`, d'après le catalogue `catalog` (les anciens sont retirés).
func build(room: RoomData, catalog: AssetCatalogDef) -> void:
	for sprite: Sprite3D in _sprites.values():
		remove_child(sprite)
		sprite.free()
	_sprites.clear()
	for index: int in room.thing_count():
		var asset: AssetDef = catalog.find(StringName(room.thing_assets[index]))
		if asset == null or asset.atlas == null:
			continue
		var sprite: Sprite3D = Sprite3D.new()
		sprite.texture = asset.atlas
		sprite.region_enabled = true
		sprite.region_rect = Rect2(asset.region)
		sprite.pixel_size = FlatLayout.pixel_size(asset)
		sprite.offset = FlatLayout.offset(asset)
		sprite.shaded = false
		sprite.double_sided = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.modulate = room.thing_colors[index]
		var active: bool = room.thing_active[index] == 1
		if not active:
			sprite.modulate.a *= INACTIVE_ALPHA
		sprite.visible = active or show_inactive
		sprite.set_meta(&"layer_index", catalog.layers.find(room.thing_layers[index]))
		sprite.set_meta(&"sort", room.thing_sort[index])
		sprite.set_meta(&"ratio", FlatLayout.depth_ratio(asset))
		add_child(sprite)
		_sprites[room.thing_ids[index]] = sprite
		place(room.thing_ids[index], room.thing_positions[index], room.thing_rotations[index], room.thing_scales[index])


## Pose la chose `thing_id` en `position` (mètres), tournée de `rotation_deg`, à l'échelle `scale`.
func place(thing_id: int, position_m: Vector3, rotation_deg: float, scale_factor: float) -> void:
	var sprite: Sprite3D = _sprites.get(thing_id)
	if sprite == null:
		return
	var lifted: Vector3 = Vector3(position_m.x, FlatLayout.height(sprite.get_meta(&"layer_index"),
			sprite.get_meta(&"sort"), position_m.y), position_m.z)
	sprite.transform = Transform3D(FlatLayout.basis(rotation_deg, scale_factor, sprite.get_meta(&"ratio")), lifted)


## Le sprite de la chose `thing_id`, ou null.
func sprite_of(thing_id: int) -> Node3D:
	return _sprites.get(thing_id)


## Le nombre de sprites de la salle.
func sprite_count() -> int:
	return _sprites.size()
