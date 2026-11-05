class_name SheetPiece
extends RefCounted
## Une pièce trouvée dans une planche peinte : un îlot de pixels non transparents (ou plusieurs, regroupés), son cadre
## rogné au plus juste dans la planche, ses pixels rangés en plages ligne par ligne, et sa place dans une page d'atlas.
## Les plages disent quels pixels lui appartiennent : son cadre peut couvrir des pixels d'une pièce voisine (le cadre
## d'un losange déborde sur ce qui l'entoure), qui ne la suivent pas dans la page.

## Le cadre de la pièce dans la planche, rogné au plus juste, en pixels.
var source_rect: Rect2i = Rect2i()
## Le nombre de ses pixels non transparents.
var area: int = 0
## Ses plages de pixels, trois nombres par plage : la ligne, la première colonne, la colonne qui suit la dernière.
var runs: PackedInt32Array = PackedInt32Array()
## La page d'atlas où elle est rangée (-1 tant qu'elle ne l'est pas).
var page: int = -1
## La place de son coin haut gauche dans sa page, en pixels.
var page_position: Vector2i = Vector2i.ZERO


## Ajoute la plage de la ligne `row`, des colonnes `from` (incluse) à `to` (exclue).
func add_run(row: int, from: int, to: int) -> void:
	var run_rect: Rect2i = Rect2i(from, row, to - from, 1)
	source_rect = run_rect if area == 0 else source_rect.merge(run_rect)
	area += to - from
	runs.append(row)
	runs.append(from)
	runs.append(to)


## Prend les pixels de `other` : les deux pièces n'en font plus qu'une.
func absorb(other: SheetPiece) -> void:
	source_rect = source_rect.merge(other.source_rect)
	area += other.area
	runs.append_array(other.runs)
