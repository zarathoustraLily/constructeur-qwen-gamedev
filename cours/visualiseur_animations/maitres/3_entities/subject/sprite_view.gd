class_name SpriteView extends Subject
## Une animation 2D (SpriteSet) montrée par un Sprite3D, tourné vers la caméra autour de la verticale. Le cadre de
## l'animation se pose par le milieu de son bord bas, sur l'origine : un personnage peint tient debout sur le sol.
## Chaque image se place dans le cadre là où l'optimiseur l'a prise (son coin, sa taille d'origine) : une image rognée
## ou réduite ne bouge pas à l'écran. Une animation « additif » (une lumière sur fond noir) s'ajoute à ce qui est
## derrière elle.

## Vrai pour avancer la lecture à la main (advance), faux pour qu'elle suive le jeu.
@export var manual: bool = false

## Les animations montrées ; null avant show_sprites.
var sprites: SpriteSet
## La taille d'un pixel du cadre, en mètres.
var meters_per_pixel: float = 0.01

var _sidecar: AssetSidecar = AssetSidecar.new()
var _sprite: Sprite3D
var _additive: StandardMaterial3D
var _time: float = 0.0


func _ready() -> void:
	process_priority = ProcessOrder.PLAYBACK


func _process(delta: float) -> void:
	if not manual and sprites != null and not _clip.is_empty():
		advance(delta)


## Montre `sprite_set`, avec les boucles de `sidecar`, à `pixel_meters` mètres par pixel ; faux sans animation.
func show_sprites(sprite_set: SpriteSet, sidecar: AssetSidecar, pixel_meters: float) -> bool:
	clear()
	if sprite_set.animations.is_empty():
		return false
	sprites = sprite_set
	_sidecar = sidecar
	meters_per_pixel = pixel_meters
	if _sprite == null:
		_sprite = Sprite3D.new()
		_sprite.name = "Sprite"
		_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_sprite.shaded = false
		_sprite.double_sided = true
		_sprite.region_enabled = true
		add_child(_sprite)
	_sprite.material_override = _additive_material() if sprite_set.blend == "additif" else null
	_sprite.visible = false
	return true


## Les noms des animations, triés.
func clips() -> Array[String]:
	if sprites == null:
		var none: Array[String] = []
		return none
	return sprites.clips()


## Le temps écoulé dans l'animation en cours.
func position_s() -> float:
	return _time


## Avance la lecture de `seconds` secondes.
func advance(seconds: float) -> void:
	_time += seconds
	_apply()


## L'indice de l'image montrée, -1 sans animation.
func frame_index() -> int:
	if sprites == null or not sprites.animations.has(_clip):
		return -1
	return sprites.animations[_clip].frame_at(_time, _sidecar.loops_clip(_clip))


## Le Sprite3D qui montre l'image (null avant la première animation).
func sprite() -> Sprite3D:
	return _sprite


## Le pavé du cadre de l'animation en cours, en mètres (pour cadrer la caméra).
func frame_bounds() -> AABB:
	if sprites == null or not sprites.animations.has(_clip):
		return AABB()
	var size: Vector2 = Vector2(sprites.animations[_clip].frame_size) * meters_per_pixel
	return AABB(Vector3(-size.x * 0.5, 0.0, -0.05), Vector3(size.x, size.y, 0.1))


## Retire l'animation montrée.
func clear() -> void:
	super.clear()
	sprites = null
	_time = 0.0
	if _sprite != null:
		_sprite.visible = false


func _start(_clip_name: String, at: float) -> void:
	_time = at
	_apply()


## Pose l'image du temps en cours : sa page, sa zone, sa taille de pixel et sa place dans le cadre.
func _apply() -> void:
	var index: int = frame_index()
	if index < 0 or _sprite == null:
		return
	var animation: SpriteAnimation = sprites.animations[_clip]
	var frame: SpriteFrame = animation.frames[index]
	_sprite.visible = not frame.is_empty()
	if frame.is_empty():
		return
	var scale_factor: float = frame.scale_factor()
	_sprite.texture = sprites.pages[frame.page]
	_sprite.region_rect = Rect2(frame.region)
	_sprite.pixel_size = meters_per_pixel * scale_factor
	# Le milieu de l'image, dans le cadre posé par le milieu de son bord bas ; Sprite3D.offset est en pixels de la
	# page, et son y monte.
	var center_x: float = frame.offset.x + frame.size.x * 0.5 - animation.frame_size.x * 0.5
	var center_y: float = animation.frame_size.y - frame.offset.y - frame.size.y * 0.5
	_sprite.offset = Vector2(center_x, center_y) / scale_factor
	if _additive != null and _sprite.material_override == _additive:
		_additive.albedo_texture = _sprite.texture


func _additive_material() -> StandardMaterial3D:
	if _additive == null:
		_additive = StandardMaterial3D.new()
		_additive.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_additive.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_additive.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_additive.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		_additive.cull_mode = BaseMaterial3D.CULL_DISABLED
		_additive.no_depth_test = false
	return _additive
