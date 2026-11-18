class_name AssetEntry extends RefCounted
## Un asset trouvé dans un dossier des réglages : son identifiant stable, sa catégorie, sa forme (modèle 3D, animation
## 2D en atlas, animation 2D en images) et son fichier ou son dossier.

## La forme d'un asset.
enum Kind {
	## Un modèle 3D glTF (.glb, .gltf), exporté de Blender.
	MODEL_3D,
	## Une animation 2D rangée en atlas (.atlas.json de l'optimiseur de l'éditeur de cartes).
	ATLAS_2D,
	## Une animation 2D en images numérotées, une par fichier, dans un dossier.
	FRAMES_2D,
}

## L'identifiant : la catégorie, puis le chemin relatif au dossier source, sans extension (ennemi/golem).
var id: String = ""
## Le nom montré dans la liste : la fin de l'identifiant.
var display_name: String = ""
## La catégorie : une de ViewerConfig.CATEGORIES.
var category: String = ""
## La forme de l'asset.
var kind: Kind = Kind.MODEL_3D
## Le fichier (.glb, .gltf, .atlas.json), ou le dossier des images.
var path: String = ""


## Vrai pour un modèle 3D.
func is_3d() -> bool:
	return kind == Kind.MODEL_3D
#@ 2+


## Le fichier d'accompagnement de l'asset, qu'il existe ou non : `<nom>.visu.json` à côté du fichier
## (heros.glb → heros.visu.json, flamme.atlas.json → flamme.visu.json), `visu.json` dans un dossier d'images.
func sidecar_path() -> String:
	if kind == Kind.FRAMES_2D:
		return path.path_join("visu.json")
	var base: String = path.trim_suffix(".atlas.json") if kind == Kind.ATLAS_2D else path.get_basename()
	return base + ".visu.json"
#@ all
