class_name SheetImporter
extends RefCounted
## Le découpage d'une planche peinte, en calcul pur sur une `Image` : trouver ses pièces, les ranger dans des pages
## d'atlas sans perdre de place, puis construire ces pages. Une planche est une grande toile à fond transparent où des
## éléments de toutes tailles sont peints, séparés par du vide : la garder telle quelle ferait payer en mémoire vidéo
## chaque pixel transparent.
## Une pièce est un îlot de pixels non transparents. Les îlots se trouvent par plages : sur chaque ligne, les suites de
## pixels non transparents ; deux plages de lignes voisines qui se touchent, même par un coin, sont du même îlot
## (union-find). Une pièce n'emporte que ses propres plages : le cadre d'un losange déborde souvent sur un voisin, dont
## les pixels ne doivent pas la suivre dans la page.

## Le côté d'un bloc de compression (BPTC, S3TC), en pixels. Les cases des pièces et les pages s'alignent sur les blocs :
## aucun bloc ne mêle deux pièces, et la compression ne fait pas baver l'une sur l'autre.
const BLOCK_PX: int = 4
## Le nombre de largeurs de page essayées par `pack`, de la racine de la surface à deux fois elle.
const WIDTH_TRIES: int = 11


## Les pièces de `image`, dans l'ordre de lecture (de haut en bas, puis de gauche à droite) : les îlots dont les cadres
## sont à moins de `merge_gap_px` pixels l'un de l'autre n'en font qu'un (0 : seuls ceux qui se touchent) ; ceux de moins
## de `min_area_px` pixels sont des poussières, ignorées.
static func find_pieces(image: Image, merge_gap_px: int, min_area_px: int) -> Array[SheetPiece]:
	var runs: Array[PackedInt32Array] = _runs(_rgba(image))
	var pieces: Array[SheetPiece] = _gather(runs, _islands(runs))
	if merge_gap_px > 0:
		pieces = _merge_close(pieces, merge_gap_px)
	var kept: Array[SheetPiece] = []
	for piece: SheetPiece in pieces:
		if piece.area >= min_area_px:
			kept.append(piece)
	kept.sort_custom(func(a: SheetPiece, b: SheetPiece) -> bool:
		return a.source_rect.position.y < b.source_rect.position.y or (a.source_rect.position.y == b.source_rect.position.y
				and a.source_rect.position.x < b.source_rect.position.x))
	return kept


## Range `pieces` dans des pages d'au plus `max_page_px` pixels de côté, par étagères : les plus hautes d'abord, de gauche
## à droite ; une étagère neuve quand la largeur est pleine, une page neuve quand la hauteur l'est. Chaque pièce garde
## `padding_px` pixels transparents autour d'elle. Plusieurs largeurs de page sont essayées : on garde celle qui couvre
## le moins de pixels. Écrit dans chaque pièce sa page et sa place ; rend la taille de chaque page, ou une liste vide si
## une pièce ne tient dans aucune page.
static func pack(pieces: Array[SheetPiece], padding_px: int, max_page_px: int) -> Array[Vector2i]:
	var order: Array[SheetPiece] = pieces.duplicate()
	order.sort_custom(func(a: SheetPiece, b: SheetPiece) -> bool:
		if a.source_rect.size.y != b.source_rect.size.y:
			return a.source_rect.size.y > b.source_rect.size.y
		if a.source_rect.size.x != b.source_rect.size.x:
			return a.source_rect.size.x > b.source_rect.size.x
		return a.source_rect.position.y < b.source_rect.position.y or (a.source_rect.position.y == b.source_rect.position.y
				and a.source_rect.position.x < b.source_rect.position.x))
	var widest: int = 0
	var area: int = 0
	for piece: SheetPiece in order:
		var cell: Vector2i = _cell(piece, padding_px)
		if cell.x > max_page_px or cell.y > max_page_px:
			return []
		widest = maxi(widest, cell.x)
		area += cell.x * cell.y
	var best_width: int = widest
	var best_cover: int = -1
	for attempt: int in WIDTH_TRIES:
		var width: int = mini(max_page_px, maxi(widest, _aligned(ceili(sqrt(float(area)) * (1.0 + 0.1 * attempt)))))
		var cover: int = 0
		for page_size: Vector2i in _shelves(order, width, padding_px, max_page_px):
			cover += page_size.x * page_size.y
		if best_cover < 0 or cover < best_cover:
			best_cover = cover
			best_width = width
	return _shelves(order, best_width, padding_px, max_page_px)


## Les pages d'atlas de `pieces` rangées par `pack`, aux tailles `page_sizes` : chaque pièce y recopie ses plages de
## `image`, à sa place ; le reste est transparent.
static func build_pages(image: Image, pieces: Array[SheetPiece], page_sizes: Array[Vector2i]) -> Array[Image]:
	var rgba: Image = _rgba(image)
	var pages: Array[Image] = []
	for page_size: Vector2i in page_sizes:
		pages.append(Image.create_empty(page_size.x, page_size.y, false, Image.FORMAT_RGBA8))
	for piece: SheetPiece in pieces:
		var shift: Vector2i = piece.page_position - piece.source_rect.position
		for index: int in range(0, piece.runs.size(), 3):
			var row: int = piece.runs[index]
			var from: int = piece.runs[index + 1]
			var span: Rect2i = Rect2i(from, row, piece.runs[index + 2] - from, 1)
			pages[piece.page].blit_rect(rgba, span, span.position + shift)
	return pages


# `image` au format RGBA8, où l'alpha d'un pixel est son quatrième octet (une copie si elle était dans un autre format).
static func _rgba(image: Image) -> Image:
	if image.get_format() == Image.FORMAT_RGBA8:
		return image
	var converted: Image = image.duplicate() as Image
	converted.convert(Image.FORMAT_RGBA8)
	return converted


# Les plages de pixels non transparents, ligne par ligne, en trois colonnes : la ligne, la première colonne, la colonne
# qui suit la dernière.
static func _runs(rgba: Image) -> Array[PackedInt32Array]:
	var data: PackedByteArray = rgba.get_data()
	var width: int = rgba.get_width()
	var rows: PackedInt32Array = PackedInt32Array()
	var starts: PackedInt32Array = PackedInt32Array()
	var ends: PackedInt32Array = PackedInt32Array()
	for y: int in rgba.get_height():
		var alpha: int = y * width * 4 + 3
		var x: int = 0
		while x < width:
			if data[alpha + x * 4] == 0:
				x += 1
				continue
			var start: int = x
			while x < width and data[alpha + x * 4] != 0:
				x += 1
			rows.append(y)
			starts.append(start)
			ends.append(x)
	return [rows, starts, ends]


# L'îlot de chaque plage, par union-find : de parent en parent, chaque plage mène à celle qui représente son îlot.
# Deux plages de lignes voisines se touchent quand leurs colonnes se recouvrent ou se suivent en diagonale.
static func _islands(runs: Array[PackedInt32Array]) -> PackedInt32Array:
	var rows: PackedInt32Array = runs[0]
	var starts: PackedInt32Array = runs[1]
	var ends: PackedInt32Array = runs[2]
	var parent: PackedInt32Array = PackedInt32Array()
	parent.resize(rows.size())
	for run: int in rows.size():
		parent[run] = run
	# Les plages de la ligne du dessus vont de `above_begin` (incluse) à `above_end` (exclue).
	var above_begin: int = 0
	var above_end: int = 0
	var row_begin: int = 0
	for run: int in rows.size():
		if run > 0 and rows[run] != rows[run - 1]:
			var touching: bool = rows[run] == rows[run - 1] + 1
			above_begin = row_begin if touching else run
			above_end = run
			row_begin = run
		for other: int in range(above_begin, above_end):
			if starts[other] <= ends[run] and starts[run] <= ends[other]:
				# La plus ancienne des deux racines représente l'îlot réuni.
				var first: int = _root(parent, other)
				var second: int = _root(parent, run)
				parent[maxi(first, second)] = mini(first, second)
	return parent


# La plage qui représente l'îlot de `run`.
static func _root(parent: PackedInt32Array, run: int) -> int:
	var current: int = run
	while parent[current] != current:
		current = parent[current]
	return current


# Une pièce par îlot, dans l'ordre où les îlots apparaissent.
static func _gather(runs: Array[PackedInt32Array], parent: PackedInt32Array) -> Array[SheetPiece]:
	var by_root: Dictionary[int, SheetPiece] = {}
	var pieces: Array[SheetPiece] = []
	for run: int in parent.size():
		var root: int = _root(parent, run)
		if not by_root.has(root):
			by_root[root] = SheetPiece.new()
			pieces.append(by_root[root])
		by_root[root].add_run(runs[0][run], runs[1][run], runs[2][run])
	return pieces


# Les pièces, celles dont les cadres sont à moins de `gap_px` pixels regroupées, jusqu'à ce qu'aucune ne le soit plus.
static func _merge_close(pieces: Array[SheetPiece], gap_px: int) -> Array[SheetPiece]:
	var result: Array[SheetPiece] = pieces.duplicate()
	var merged: bool = true
	while merged:
		merged = false
		for first: int in result.size():
			for second: int in range(first + 1, result.size()):
				if result[first].source_rect.grow(gap_px).intersects(result[second].source_rect):
					result[first].absorb(result[second])
					result.remove_at(second)
					merged = true
					break
			if merged:
				break
	return result


# Les pages des pièces `order` rangées par étagères dans une largeur `width` : écrit la page et la place de chaque pièce,
# rend la taille de chaque page, rognée à ce qu'elle contient (en blocs entiers).
static func _shelves(order: Array[SheetPiece], width: int, padding_px: int, max_page_px: int) -> Array[Vector2i]:
	var page_sizes: Array[Vector2i] = []
	var x: int = 0
	var y: int = 0
	var shelf: int = 0
	var used_width: int = 0
	for piece: SheetPiece in order:
		var cell: Vector2i = _cell(piece, padding_px)
		if x + cell.x > width:
			x = 0
			y += shelf
			shelf = 0
		if y + cell.y > max_page_px:
			page_sizes.append(Vector2i(used_width, y))
			x = 0
			y = 0
			shelf = 0
			used_width = 0
		piece.page = page_sizes.size()
		piece.page_position = Vector2i(x + padding_px, y + padding_px)
		x += cell.x
		shelf = maxi(shelf, cell.y)
		used_width = maxi(used_width, x)
	page_sizes.append(Vector2i(used_width, y + shelf))
	return page_sizes


# La case d'une pièce dans une page : la pièce et sa marge, arrondies aux blocs.
static func _cell(piece: SheetPiece, padding_px: int) -> Vector2i:
	return Vector2i(_aligned(piece.source_rect.size.x + 2 * padding_px), _aligned(piece.source_rect.size.y + 2 * padding_px))


# `value` arrondi au bloc supérieur.
static func _aligned(value: int) -> int:
	return (value + BLOCK_PX - 1) & ~(BLOCK_PX - 1)
