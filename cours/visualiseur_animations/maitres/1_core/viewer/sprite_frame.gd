class_name SpriteFrame extends RefCounted
## Une image d'une animation 2D : où la prendre dans sa page, et où la poser dans le cadre de l'animation. Une image
## vide (page -1) ne montre rien : l'optimiseur en écrit pour garder le rythme d'une animation.

## L'indice de la page dans SpriteAnimation.pages, ou -1 pour une image vide.
var page: int = -1
## La zone de l'image dans sa page, en pixels de la page.
var region: Rect2i = Rect2i()
## Le coin haut-gauche de l'image dans le cadre, en pixels du cadre.
var offset: Vector2i = Vector2i.ZERO
## La taille de l'image dans le cadre, en pixels du cadre : plus grande que la zone quand l'optimiseur l'a réduite.
var size: Vector2i = Vector2i.ZERO


## Vrai pour une image qui ne montre rien.
func is_empty() -> bool:
	return page < 0 or region.size.x <= 0 or region.size.y <= 0


## Combien de pixels du cadre fait un pixel de la page (2 pour une image réduite de moitié).
func scale_factor() -> float:
	return 1.0 if is_empty() else float(size.x) / float(region.size.x)
