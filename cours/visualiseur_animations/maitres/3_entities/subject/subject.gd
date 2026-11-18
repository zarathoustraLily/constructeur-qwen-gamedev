class_name Subject extends Node3D
## Ce que montre le visualiseur : un modèle 3D (ModelView) ou une animation 2D (SpriteView), posé à l'origine,
## qui regarde +Z. Les deux se jouent de la même façon : la liste des clips, jouer un clip depuis le début, avancer.
#@ 3+
## Les clips faits pour un angle de vue (AngleClips) : jouer un nom de base prend la variante la plus proche de
## l'angle de la caméra ; changer d'angle en cours de lecture passe à la nouvelle variante, au même instant.
#@ all

## Le clip en cours a changé (son nom complet, variante d'angle comprise).
signal clip_changed(clip: String)

var _clip: String = ""
#@ 3+
var _base: String = ""
var _view_deg: float = 0.0
#@ all


## Les noms complets des clips, triés.
func clips() -> Array[String]:
	return []


## Le clip en cours, vide si aucun.
func current_clip() -> String:
	return _clip


## Joue `clip` depuis le début ; faux si le sujet ne l'a pas.
func play(clip: String) -> bool:
	if not clips().has(clip):
		return false
	_clip = clip
#@ 3+
	_base = AngleClips.base_of(clip)
#@ all
	_start(clip, 0.0)
	clip_changed.emit(clip)
	return true


## Le temps écoulé dans le clip en cours, en secondes.
func position_s() -> float:
	return 0.0


## Avance la lecture de `seconds` secondes.
func advance(_seconds: float) -> void:
	pass


## Retire ce qui est montré.
func clear() -> void:
	_clip = ""
#@ 3+
	_base = ""


## Joue le clip `base` sous l'angle de vue en cours (sa variante la plus proche) ; faux s'il n'existe pas.
func play_base(base: String) -> bool:
	var clip: String = AngleClips.pick(clips(), base, _view_deg)
	if clip.is_empty() or not play(clip):
		return false
	_base = base
	return true


## Le nom de base du clip en cours.
func current_base() -> String:
	return _base


## Change l'angle de vue (OrbitRig.view_yaw) ; si une variante du clip en cours est plus proche, on y passe au
## même instant.
func set_view_angle(deg: float) -> void:
	_view_deg = AngleClips.normalize(deg)
	if _base.is_empty():
		return
	var clip: String = AngleClips.pick(clips(), _base, _view_deg)
	if clip.is_empty() or clip == _clip:
		return
	var at: float = position_s()
	_clip = clip
	_start(clip, at)
	clip_changed.emit(clip)


## L'angle de vue, en degrés.
func view_angle() -> float:
	return _view_deg
#@ all


## Lance `clip_name` à `at` secondes : à écrire par chaque forme de sujet.
func _start(_clip_name: String, _at: float) -> void:
	pass
