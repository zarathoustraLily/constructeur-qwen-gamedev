class_name AssetDef
extends Resource
## Un asset du catalogue : une région d'une planche d'images, et ce qu'il faut pour la poser dans une salle (sa taille en
## mètres, son point d'ancrage, son calque par défaut). Une chose de la salle désigne son asset par `id`.

## Identifiant de l'asset, en snake_case, jamais renommé : les salles le citent.
@export var id: StringName = &""
## La planche d'images qui contient l'asset.
@export var atlas: Texture2D
## La région de l'asset dans la planche, en pixels.
@export var region: Rect2i = Rect2i()
## La taille de l'asset posé à l'échelle 1, en mètres : largeur en x, profondeur en z.
@export var size_m: Vector2 = Vector2.ONE
## Le point de l'image posé sur la position de la chose, de (0, 0) en haut à gauche à (1, 1) en bas à droite.
@export var anchor: Vector2 = Vector2(0.5, 0.5)
## La catégorie (sol, détail, obstacle, avant-plan, porte), qui range la palette.
@export var category: StringName = &""
## Le calque où l'éditeur pose l'asset quand on l'ajoute.
@export var default_layer: StringName = &""
## Des mots de recherche.
@export var tags: PackedStringArray = PackedStringArray()


## Les erreurs de l'asset, une phrase par erreur ; vide s'il est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var label: String = "asset %s" % id
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : identifiant en snake_case requis" % label)
	if atlas == null:
		errors.append("%s : planche requise" % label)
	elif region.size.x <= 0 or region.size.y <= 0 \
			or not Rect2i(0, 0, atlas.get_width(), atlas.get_height()).encloses(region):
		errors.append("%s : région hors de la planche" % label)
	if size_m.x <= 0.0 or size_m.y <= 0.0:
		errors.append("%s : taille positive requise" % label)
	if anchor.x < 0.0 or anchor.x > 1.0 or anchor.y < 0.0 or anchor.y > 1.0:
		errors.append("%s : ancre hors de [0, 1]" % label)
	return errors
