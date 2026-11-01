class_name Flipbook extends RefCounted
## Le rangement d'un flipbook : des images sur une planche, de gauche à droite, puis de haut en bas. Le shader `flipbook_view.gdshader`
## fait le même calcul.


## La case de l'image `index` sur la planche.
static func cell(index: int, columns: int) -> Vector2i:
	return Vector2i(index % columns, floori(float(index) / columns))


## Le rectangle de l'image `index`, en coordonnées de texture.
static func uv_rect(index: int, columns: int, rows: int) -> Rect2:
	var size: Vector2 = Vector2(1.0 / columns, 1.0 / rows)
	return Rect2(Vector2(cell(index, columns)) * size, size)


## L'image à montrer au temps `time`, en flottant : sa partie entière est l'image, sa partie fractionnaire le mélange avec la suivante.
## Sans boucle, la dernière image reste.
static func frame_at(time: float, frames_per_second: float, count: int, looping: bool) -> float:
	var frame: float = time * frames_per_second
	if looping:
		return fmod(frame, float(count))
	return minf(frame, float(count - 1))
