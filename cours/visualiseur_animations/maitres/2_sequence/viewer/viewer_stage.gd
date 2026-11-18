class_name ViewerStage extends Node3D
## La scène où le visualiseur montre un asset : un sol, une lumière, la caméra et les deux sujets (un modèle 3D, une
## animation 2D), dont un seul sert à la fois. Elle charge l'asset choisi avec son fichier d'accompagnement et lance
## son premier clip : « pause » s'il en a une, sinon le premier dans l'ordre.

## Le clip lancé en premier quand l'asset en a un de ce nom.
const FIRST_CLIP: String = "pause"

## Vrai pour avancer la lecture à la main (les tests).
@export var manual: bool = false

@onready var _camera: Camera3D = %Camera
@onready var _model: ModelView = %ModelView
@onready var _sprite: SpriteView = %SpriteView

var _active: Subject


func _ready() -> void:
	set_manual(manual)


## Lecture à la main (`value` vrai) ou au rythme du jeu, pour les deux sujets.
func set_manual(value: bool) -> void:
	manual = value
	_model.manual = value
	_sprite.manual = value


## Montre l'asset `entry` avec les réglages `config` ; rend l'erreur, vide si tout va bien (rien n'est alors montré).
func show_entry(entry: AssetEntry, config: ViewerConfig) -> String:
	clear()
	var sidecar: AssetSidecar = AssetSidecar.load_for(entry)
	if entry.is_3d():
		var loaded: LoadedModel = ModelLoader.load_model(entry.path)
		if not loaded.error.is_empty():
			return loaded.error
		_model.show_model(loaded, sidecar)
		_active = _model
	else:
		var sprites: SpriteSet = (SpriteLoader.load_atlas(entry.path) if entry.kind == AssetEntry.Kind.ATLAS_2D
				else SpriteLoader.load_frames(entry.path, sidecar.fps))
		if not sprites.error.is_empty():
			return sprites.error
		if not _sprite.show_sprites(sprites, sidecar, 1.0 / config.pixels_per_meter):
			return "aucune animation dans " + entry.path
		_active = _sprite
	var clips: Array[String] = _active.clips()
	if not clips.is_empty():
		_active.play(FIRST_CLIP if clips.has(FIRST_CLIP) else clips[0])
	return ""


## Retire l'asset montré.
func clear() -> void:
	_model.clear()
	_sprite.clear()
	_active = null


## Le sujet qui montre l'asset, null si aucun.
func subject() -> Subject:
	return _active


## La caméra de la scène.
func camera() -> Camera3D:
	return _camera
#@ 3+


## Tourne les sujets de `deg` degrés autour de la verticale (le sujet qui pivote en vue du jeu).
func set_subject_yaw(deg: float) -> void:
	_model.rotation.y = deg_to_rad(deg)
	_sprite.rotation.y = deg_to_rad(deg)


## Le pavé de l'asset montré, en mètres (vide sans asset).
func subject_bounds() -> AABB:
	if _active == _model:
		return _model.model.bounds()
	if _active == _sprite:
		return _sprite.frame_bounds()
	return AABB()
#@ all
