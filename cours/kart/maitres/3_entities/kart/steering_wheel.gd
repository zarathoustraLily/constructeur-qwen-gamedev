extends MeshInstance3D
## Volant du kart : au démarrage, les mains du pilote (cibles de cinématique inverse) y sont accrochées.

## Pilote dont les cibles IKTargetLeftArm et IKTargetRightArm sont accrochées aux poignées du volant.
@export var character : Node3D
@onready var left_hand_grip : Node3D = $LeftHandGrip
@onready var right_hand_grip : Node3D = $RightHandGrip


func _ready() -> void:
	character.IKTargetLeftArm.reparent(left_hand_grip)
	character.IKTargetLeftArm.position = Vector3.ZERO
	
	character.IKTargetRightArm.reparent(right_hand_grip)
	character.IKTargetRightArm.position = Vector3.ZERO
