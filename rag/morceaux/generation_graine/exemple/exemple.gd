extends Node
## Exemple : génération reproductible. Deux générateurs de même graine creusent la même grotte ; une autre graine en
## creuse une autre. Le même générateur réemployé sans remettre sa graine creuse une grotte différente : son état a
## avancé. Toutes les cases restent dans la grille.

const TAILLE := Vector2i(40, 30)
const PAS := 600


func _ready() -> void:
	var a := RandomWalk.carve(_generateur(42), TAILLE, PAS)
	var b := RandomWalk.carve(_generateur(42), TAILLE, PAS)
	var c := RandomWalk.carve(_generateur(7), TAILLE, PAS)
	var rng := _generateur(42)
	var premier := RandomWalk.carve(rng, TAILLE, PAS)
	var second := RandomWalk.carve(rng, TAILLE, PAS)
	rng.seed = 42  # remettre la graine remet l'état
	var troisieme := RandomWalk.carve(rng, TAILLE, PAS)
	var dedans := a.all(func(v: Vector2i) -> bool: return v.x >= 0 and v.y >= 0 and v.x < TAILLE.x and v.y < TAILLE.y)
	if a == b and a != c and premier == a and second != a and troisieme == a and dedans:
		print(("EXEMPLE VERIFIE : graine 42 deux fois, %d cases identiques ; graine 7, %d cases, autre grotte ; même "
				+ "générateur réemployé : autre grotte, puis la même après rng.seed = 42 ; toutes les cases dans la grille")
				% [a.size(), c.size()])
	else:
		push_error("a == b %s, a != c %s, premier %s, second différent %s, troisième %s, dedans %s"
				% [a == b, a != c, premier == a, second != a, troisieme == a, dedans])
	get_tree().quit()


func _generateur(graine: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	return rng
