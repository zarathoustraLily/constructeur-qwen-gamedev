@tool
class_name GolemStrikeModifier extends SkeletonModifier3D
## Le buste du golem penché vers l'avant, par-dessus son animation : ses clips d'attaque frappent à sa propre hauteur
## (le marteau passe à 4 m du sol), trop haut pour un héros quatre fois plus petit que lui. Penché de `bend` radians
## autour de l'os `bone` (le bas du dos), tout le haut du corps suit, et le marteau passe au ras du sol devant lui. La vue
## règle `bend` d'après l'attaque en cours ; ce nœud ne décide rien.

## L'os autour duquel le buste se penche.
@export var bone: StringName = &"spine_01"
## L'angle du buste vers l'avant, en radians (0 : l'animation telle quelle).
@export_range(0.0, 1.5, 0.01) var bend: float = 0.0


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or is_zero_approx(bend):
		return
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return
	var parent: int = skeleton.get_bone_parent(index)
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var bone_basis: Basis = skeleton.get_bone_global_pose(index).basis
	# Dans le repère du squelette, le golem regarde vers +Z : pencher vers l'avant, c'est tourner autour de +X.
	var bent: Basis = Basis(Vector3.RIGHT, bend) * bone_basis
	skeleton.set_bone_pose_rotation(index, (parent_basis.inverse() * bent).get_rotation_quaternion())
