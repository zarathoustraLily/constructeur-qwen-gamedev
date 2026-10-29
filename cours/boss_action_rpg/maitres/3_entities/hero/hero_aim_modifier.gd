@tool
class_name HeroAimModifier extends SkeletonModifier3D
## Le buste du héros incliné vers ce qu'il vise, par-dessus son animation : ses clips tiennent le fusil à
## l'horizontale ; quand il vise plus haut ou plus bas, l'os `bone` (et tout ce qu'il porte : bras, tête, fusil) tourne
## d'autant, et le canon pointe là où part le tir. La vue règle `pitch` ; ce nœud ne décide rien. Il passe avant l'IK
## de la main gauche, qui suit le fusil incliné.

## L'os qui s'incline (le haut du buste).
@export var bone: StringName = &"Chest"
## L'inclinaison voulue, en radians (positive : vers le haut).
@export_range(-1.5, 1.5, 0.01) var pitch: float = 0.0


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or is_zero_approx(pitch):
		return
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return
	var parent: int = skeleton.get_bone_parent(index)
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var bone_basis: Basis = skeleton.get_bone_global_pose(index).basis
	# Dans le repère du squelette, le soldat regarde vers +Z : lever le buste, c'est tourner autour de +X, en arrière.
	var raised: Basis = Basis(Vector3.RIGHT, -pitch) * bone_basis
	skeleton.set_bone_pose_rotation(index, (parent_basis.inverse() * raised).get_rotation_quaternion())
