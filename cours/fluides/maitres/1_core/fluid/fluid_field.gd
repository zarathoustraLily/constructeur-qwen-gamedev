class_name FluidField extends RefCounted
## Un champ posé sur une grille : une valeur par case (densité, température, une composante de la vitesse). Les cases sont
## rangées ligne par ligne dans un seul tableau : il se parcourt vite, et la simulation n'y crée aucun objet.
## Le centre de la case (x, y) est au point (x, y) : une lecture entre deux cases mélange ses voisines.

## La largeur de la grille, en cases.
var width: int = 0
## La hauteur de la grille, en cases.
var height: int = 0
## Les valeurs, ligne par ligne.
var data: PackedFloat32Array = PackedFloat32Array()


func _init(columns: int, rows: int) -> void:
	width = columns
	height = rows
	data.resize(columns * rows)
	data.fill(0.0)


## La place de la case (x, y) dans `data`.
func index(x: int, y: int) -> int:
	return y * width + x


## La valeur de la case (x, y) ; hors de la grille, celle de la case du bord la plus proche.
func at(x: int, y: int) -> float:
	return data[index(clampi(x, 0, width - 1), clampi(y, 0, height - 1))]


## Pose `value` dans la case (x, y).
func put(x: int, y: int, value: float) -> void:
	data[index(x, y)] = value


## La valeur au point (x, y), entre quatre cases : un mélange bilinéaire.
func sample(x: float, y: float) -> float:
	var left: int = floori(x)
	var top: int = floori(y)
	var across: float = x - left
	var down: float = y - top
	var upper: float = lerpf(at(left, top), at(left + 1, top), across)
	var lower: float = lerpf(at(left, top + 1), at(left + 1, top + 1), across)
	return lerpf(upper, lower, down)


## Met `value` dans toutes les cases.
func fill(value: float) -> void:
	data.fill(value)


## Recopie les valeurs de `other`, de la même taille, sans créer de tableau.
func copy_from(other: FluidField) -> void:
	for i: int in data.size():
		data[i] = other.data[i]


## La somme de toutes les cases : ce qu'un transport doit à peu près conserver.
func total() -> float:
	var sum_of_cells: float = 0.0
	for value: float in data:
		sum_of_cells += value
	return sum_of_cells


## La plus grande valeur du champ.
func peak() -> float:
	var highest: float = data[0]
	for value: float in data:
		highest = maxf(highest, value)
	return highest


## Ajoute `amount` dans le disque de centre (`center_x`, `center_y`) : le plus au centre, rien au bord du rayon `radius`.
func add_disc(center_x: float, center_y: float, radius: float, amount: float) -> void:
	var reach: int = ceili(radius)
	for y: int in range(maxi(floori(center_y) - reach, 0), mini(floori(center_y) + reach + 1, height)):
		for x: int in range(maxi(floori(center_x) - reach, 0), mini(floori(center_x) + reach + 1, width)):
			var distance: float = Vector2(x - center_x, y - center_y).length()
			if distance < radius:
				data[index(x, y)] += amount * (1.0 - distance / radius)
