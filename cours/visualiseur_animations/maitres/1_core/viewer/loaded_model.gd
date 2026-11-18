class_name LoadedModel extends RefCounted
## Un modèle 3D chargé : sa scène, son lecteur d'animations et son squelette s'il en a, ou l'erreur qui l'a empêché de
## charger. La scène est hors de l'arbre : qui la reçoit la pose sous un nœud, ou la libère (free_scene).

## La scène du modèle ; null si le chargement a échoué.
var root: Node3D
## Le lecteur d'animations du modèle ; null s'il n'a aucune animation.
var player: AnimationPlayer
## Le squelette ; null pour un modèle sans os (un coffre, une porte).
var skeleton: Skeleton3D
## L'erreur de chargement, vide si tout va bien.
var error: String = ""


## Les noms des animations, triés.
func clips() -> Array[String]:
	var names: Array[String] = []
	if player != null:
		for clip: StringName in player.get_animation_list():
			names.append(String(clip))
	names.sort()
	return names


## Le pavé qui contient tous les maillages au repos, dans le repère de la scène (pour cadrer la caméra).
func bounds() -> AABB:
	var box: AABB = AABB()
	var first: bool = true
	if root == null:
		return box
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var part: AABB = _to_root(mesh) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## Libère la scène, si personne ne l'a posée dans l'arbre.
func free_scene() -> void:
	if root != null and not root.is_inside_tree():
		root.free()
	root = null
	player = null
	skeleton = null


## La transformation de `node` dans le repère de la scène, de parent en parent (la scène peut être hors de l'arbre).
func _to_root(node: Node3D) -> Transform3D:
	var xform: Transform3D = Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform
