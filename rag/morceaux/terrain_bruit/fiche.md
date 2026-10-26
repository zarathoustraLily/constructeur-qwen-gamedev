# Terrain en relief tiré d'un bruit (FastNoiseLite, SurfaceTool)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier terrain_bruit`.

## Ce que fait le morceau

Une grille de sommets soulevés par `FastNoiseLite.get_noise_2d` × hauteur, deux triangles par carré, normales calculées par `SurfaceTool.generate_normals()`. Même graine du bruit, même terrain.

## Quand l'employer

Terrain, collines, fond marin, relief d'une carte ; base d'un monde ouvert ou d'une île générée.

Dans un projet qui suit le plan : l'outil commun de maillage dans `1_core/procedural/` ; un générateur `@tool` et sa scène dans `6_assets/Mesh/Procedural/<famille>/`, ses réglages (graine, taille, hauteur) dans `5_data/DECORS/` (section 6 des règles du dépôt).

## Le code (`1_core/procedural/height_terrain.gd`, vérifié)

```gdscript
class_name HeightTerrain
extends RefCounted
## Terrain en relief tiré d'un bruit : une grille de `cells` × `cells` carrés de `cell_size` mètres, chaque sommet
## soulevé de noise.get_noise_2d() × `height` (le bruit rend une valeur entre -1 et 1).


## Les tableaux du maillage (ArrayMesh.add_surface_from_arrays), normales comprises.
static func build_arrays(noise: FastNoiseLite, cells: int, cell_size: float, height: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: int in cells + 1:
		for x: int in cells + 1:
			var p := Vector3(x * cell_size, noise.get_noise_2d(x, z) * height, z * cell_size)
			st.set_uv(Vector2(x, z) / cells)
			st.add_vertex(p)
	var row := cells + 1
	for z: int in cells:
		for x: int in cells:
			var i := z * row + x
			# Deux triangles par carré, sommets dans le sens des aiguilles d'une montre vus d'en haut : la face avant
			# regarde vers le haut et generate_normals() fait pointer les normales vers +Y.
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + row)
			st.add_index(i + 1)
			st.add_index(i + row + 1)
			st.add_index(i + row)
	st.generate_normals()
	return st.commit_to_arrays()


static func build(noise: FastNoiseLite, cells: int, cell_size: float, height: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, build_arrays(noise, cells, cell_size, height))
	return mesh
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 1089 sommets, 6144 indices ; hauteurs de -2.14 à 1.66 m ; normale moyenne (-0.01, 0.88, 0.02) ; même graine, même terrain.

## Pièges

- L'ordre des sommets d'un triangle décide de sa face avant, donc du sens des normales de `generate_normals()` (mesuré : avec l'ordre du morceau, normale moyenne vers +Y).
- `get_noise_2d` rend une valeur entre -1 et 1 : la hauteur reste dans [-height, height] (mesuré).
- `commit_to_arrays()` donne les tableaux sans passer par le serveur de rendu : on peut les lire et les tester sans fenêtre (mesuré).
