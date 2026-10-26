# Génération procédurale reproductible : graine et RandomNumberGenerator

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier generation_graine`.

## Ce que fait le morceau

Une grotte creusée par une marche au hasard sur une grille. Le hasard vient d'un `RandomNumberGenerator` reçu en paramètre : même graine, même grotte ; autre graine, autre grotte.

## Quand l'employer

Donjons, grottes, placement d'objets, niveaux du jour (une graine par jour), parties rejouables, tests qui doivent redonner le même résultat.

Dans un projet qui suit le plan : l'outil générique dans `1_core/procedural/` ; le générateur reçoit le `RandomNumberGenerator` en dépendance (règle SIM-09 du plan : un tirage qui compte vient d'un générateur reçu, `randf()` seulement dans une vue).

## Le code (`1_core/procedural/random_walk.gd`, vérifié)

```gdscript
class_name RandomWalk
extends RefCounted
## Grotte creusée par une marche au hasard sur une grille. Le hasard vient du RandomNumberGenerator reçu : même graine,
## même grotte.


## Creuse `steps` pas depuis le centre d'une grille de `size` cases, sans en sortir. Rend les cases creusées, dans
## l'ordre où elles l'ont été (chacune une fois).
static func carve(rng: RandomNumberGenerator, size: Vector2i, steps: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var cell := Vector2i(floori(size.x / 2.0), floori(size.y / 2.0))  # size / 2 : division entière, avertissement
	var seen: Dictionary[Vector2i, bool] = {cell: true}
	var cells: Array[Vector2i] = [cell]
	for _step: int in steps:
		var next := cell + directions[rng.randi_range(0, directions.size() - 1)]
		if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
			continue
		cell = next
		if not seen.has(cell):
			seen[cell] = true
			cells.append(cell)
	return cells
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : graine 42 deux fois, 244 cases identiques ; graine 7, 218 cases, autre grotte ; même générateur réemployé : autre grotte, puis la même après rng.seed = 42 ; toutes les cases dans la grille.

## Pièges

- Réemployer le même générateur sans remettre sa graine donne une autre grotte : son état a avancé (mesuré). `rng.seed = graine` remet l'état (mesuré : même grotte).
- Les fonctions globales `randi()`, `randf()`, `pick_random()` ne passent pas par le générateur reçu : elles cassent la reproduction (principe du plan SIM-09 ; non mesuré ici).
- `size / 2` sur un `Vector2i` est une division entière : l'avertissement `integer_division`, une erreur avec les réglages du plan, la vise aussi (mesuré : « Integer division. Decimal part will be discarded. ») ; écrire `floori(size.x / 2.0)`.
