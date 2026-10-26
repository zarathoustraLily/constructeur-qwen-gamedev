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
