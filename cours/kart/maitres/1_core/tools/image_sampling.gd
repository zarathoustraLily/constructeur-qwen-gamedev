@tool
class_name ImageSampling
## Lecture d'une image comme d'une texture : la couleur en un point UV (de 0 à 1), interpolée entre les quatre
#@ 6-7
## pixels voisins. Le semeur de détails y lit le masque du terrain, dans l'éditeur (d'où `@tool`).
#@ 8+
## pixels voisins. Le semeur de détails y lit le masque du terrain, dans l'éditeur (d'où `@tool`) ; l'océan,
## celui de l'île.
#@ all
#@ 8+

## Plus grande coordonnée UV que lit centered() : juste sous 1, dans le dernier pixel.
const LAST_UV := 0.99999
#@ all


## Couleur de `image` en `uv` (de 0 à 1), interpolée entre les quatre pixels voisins ; noir hors de l'image.
## Sur le bord droit et le bord bas, le dernier pixel sert de voisin : la lecture ne sort jamais de l'image.
static func bilinear(image: Image, uv: Vector2) -> Color:
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return Color.BLACK
	uv *= Vector2(image.get_size())
	var px: Vector2 = floor(uv)
	var frac := uv - px
	var x := int(px.x)
	var y := int(px.y)
	var right := mini(x + 1, image.get_width() - 1)
	var below := mini(y + 1, image.get_height() - 1)
	var top: Color = lerp(image.get_pixel(x, y), image.get_pixel(right, y), frac.x)
	var bottom: Color = lerp(image.get_pixel(x, below), image.get_pixel(right, below), frac.x)
	return lerp(top, bottom, frac.y)
#@ 8+


## Couleur de `image` au point `point` (m) d'un carré de côtés `size` (m), centré sur l'origine, que l'image
## couvre. Hors du carré, la couleur du bord le plus proche : comme une texture sans répétition
## (`repeat_disable`) lue par un shader.
static func centered(image: Image, point: Vector2, size: Vector2) -> Color:
	var uv := point / size + Vector2(0.5, 0.5)
	return bilinear(image, uv.clamp(Vector2.ZERO, Vector2.ONE * LAST_UV))
#@ all
