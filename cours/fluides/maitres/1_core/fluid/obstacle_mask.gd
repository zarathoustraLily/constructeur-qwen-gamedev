class_name ObstacleMask extends RefCounted
## Les murs d'une grille : une case est libre ou pleine. Le tour de la grille compte pour un mur fermé.

## La largeur de la grille, en cases.
var width: int = 0
## La hauteur de la grille, en cases.
var height: int = 0
## 1 pour une case pleine, ligne par ligne.
var solid: PackedByteArray = PackedByteArray()


func _init(columns: int, rows: int) -> void:
	width = columns
	height = rows
	solid.resize(columns * rows)
	solid.fill(0)


## Vrai si la case (x, y) est pleine, ou hors de la grille.
func is_solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return true
	return solid[y * width + x] != 0


## Remplit le rectangle de `first_x` à `last_x` et de `first_y` à `last_y`, bornes comprises.
func add_box(first_x: int, first_y: int, last_x: int, last_y: int) -> void:
	for y: int in range(maxi(first_y, 0), mini(last_y + 1, height)):
		for x: int in range(maxi(first_x, 0), mini(last_x + 1, width)):
			solid[y * width + x] = 1


## Arrête la vitesse (`u`, `v`) contre les murs : une case ne garde aucune vitesse qui la ferait entrer dans un mur voisin.
func stop_at_walls(u: FluidField, v: FluidField) -> void:
	for y: int in height:
		for x: int in width:
			if u.at(x, y) > 0.0 and is_solid(x + 1, y) or u.at(x, y) < 0.0 and is_solid(x - 1, y):
				u.put(x, y, 0.0)
			if v.at(x, y) > 0.0 and is_solid(x, y + 1) or v.at(x, y) < 0.0 and is_solid(x, y - 1):
				v.put(x, y, 0.0)


## Met à zéro `field` dans les cases pleines : ni vitesse ni matière dans un mur.
func clear_inside(field: FluidField) -> void:
	for i: int in solid.size():
		if solid[i] != 0:
			field.data[i] = 0.0
