class_name BobineModel extends Node3D
## Le modèle de Bobine : le squelette et les clips du héros, un corps de bois bâti au chargement, et son arme dans la main
## droite. Ses nœuds portent les noms que lit HeroView (%GeneralSkeleton, AnimationPlayer, %Muzzle, %LeftHandIK) : la vue du
## héros la montre sans rien savoir d'elle.

@onready var _skeleton: Skeleton3D = %GeneralSkeleton
@onready var _body: MeshInstance3D = %Body
@onready var _weapon: MeshInstance3D = %WeaponMesh


func _ready() -> void:
	_body.mesh = BobineBody.build(_skeleton)
	_body.skin = _skeleton.create_skin_from_rest_transforms()
	_weapon.mesh = WeaponShapes.nailer()
