class_name SpriteAnimation extends RefCounted
## Une animation 2D : ses images dans l'ordre, sa cadence, la taille de son cadre. Le cadre est le rectangle commun à
## toutes les images ; il se pose par le milieu de son bord bas, comme un personnage par ses pieds.

## Le nom de l'animation.
var name: String = ""
## Images par seconde.
var fps: float = 24.0
## La taille du cadre, en pixels.
var frame_size: Vector2i = Vector2i.ZERO
## Les images, dans l'ordre.
var frames: Array[SpriteFrame] = []


## La durée d'un passage, en secondes.
func length() -> float:
	return float(frames.size()) / fps


## L'indice de l'image montrée au temps `time` (secondes) : en boucle, on repart du début ; sinon on reste sur la
## dernière image.
func frame_at(time: float, looping: bool) -> int:
	if frames.is_empty():
		return -1
	var index: int = floori(maxf(time, 0.0) * fps)
	return posmod(index, frames.size()) if looping else mini(index, frames.size() - 1)
