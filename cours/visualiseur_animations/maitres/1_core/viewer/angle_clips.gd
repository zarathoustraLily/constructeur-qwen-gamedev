class_name AngleClips extends RefCounted
## Les animations faites pour un angle de vue. Un clip nommé « <base>_angle_<degrés> » (salut_angle_0,
## salut_angle_90…) ne sert que vu sous cet angle ; le visualiseur prend la variante dont l'angle est le plus proche de
## la caméra, comme le jeu le fera. Un clip sans « _angle_ » sert sous tous les angles.
## Pas de « @ » dans le nom : l'import glTF de Godot 4.7.2 le remplace par « _ » (mesuré : salut@90 arrive en
## salut_90), qu'on ne distinguerait plus d'un deuxième coup d'une attaque (attaque_2).
## L'angle est celui de la caméra autour du sujet, qui regarde +Z : 0 le voit de face, 90 de son côté gauche (la
## caméra du côté +X), 180 de dos, 270 de son côté droit.

## Le séparateur entre le nom de base et l'angle.
const SEPARATOR: String = "_angle_"
## Un tour complet, en degrés.
const FULL_TURN: float = 360.0


## L'angle `deg` ramené entre 0 et 360 degrés.
static func normalize(deg: float) -> float:
	return fposmod(deg, FULL_TURN)


## Le nom de base de `clip` : salut pour salut_angle_90, course pour course.
static func base_of(clip: String) -> String:
	var at: int = clip.rfind(SEPARATOR)
	if at < 0 or not clip.substr(at + SEPARATOR.length()).is_valid_int():
		return clip
	return clip.substr(0, at)


## L'angle de `clip`, ou -1 pour un clip qui sert sous tous les angles.
static func angle_of(clip: String) -> int:
	var at: int = clip.rfind(SEPARATOR)
	if at < 0 or not clip.substr(at + SEPARATOR.length()).is_valid_int():
		return -1
	return posmod(clip.substr(at + SEPARATOR.length()).to_int(), 360)


## Les noms de base de `clips`, triés, chacun une fois.
static func bases(clips: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for clip: String in clips:
		var base: String = base_of(clip)
		if not names.has(base):
			names.append(base)
	names.sort()
	return names


## Les angles des variantes de `base` dans `clips`, triés ; vide si `base` n'a pas de variante.
static func angles(clips: Array[String], base: String) -> Array[int]:
	var found: Array[int] = []
	for clip: String in clips:
		if base_of(clip) == base and angle_of(clip) >= 0:
			found.append(angle_of(clip))
	found.sort()
	return found


## Le clip à jouer pour `base` vu sous l'angle `view_deg` : la variante d'angle le plus proche (à égalité, le plus
## petit angle), sinon `base` lui-même s'il existe, sinon une chaîne vide.
static func pick(clips: Array[String], base: String, view_deg: float) -> String:
	var best: String = ""
	var best_gap: float = INF
	for angle: int in angles(clips, base):
		var gap: float = absf(fposmod(float(angle) - view_deg + 180.0, 360.0) - 180.0)
		if gap < best_gap:
			best_gap = gap
			best = base + SEPARATOR + str(angle)
	if not best.is_empty():
		return _exact(clips, best, base)
	return base if clips.has(base) else ""


## Le vrai nom de la variante (salut_angle_090 s'écrit aussi salut_angle_90 : on rend celui du fichier).
static func _exact(clips: Array[String], wanted: String, base: String) -> String:
	if clips.has(wanted):
		return wanted
	var angle: int = angle_of(wanted)
	for clip: String in clips:
		if base_of(clip) == base and angle_of(clip) == angle:
			return clip
	return wanted
