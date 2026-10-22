extends Node3D
## Exemple minimal de Phantom Camera (v0.11.0.3) : une caméra virtuelle suit une cible, avec un décalage.
## Le PhantomCameraHost, enfant de la vraie Camera3D, la place sur la caméra virtuelle de plus haute priorité.

const DECALAGE: Vector3 = Vector3(0.0, 2.0, 6.0)
const VITESSE: float = 3.0
const IMAGES: int = 90

var _camera: Camera3D
var _cible: Node3D
var _image: int = 0


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.add_child(PhantomCameraHost.new())
	add_child(_camera)
	_cible = Node3D.new()
	add_child(_cible)
	var pcam := PhantomCamera3D.new()
	pcam.priority = 10
	pcam.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	pcam.follow_offset = DECALAGE
	add_child(pcam)
	pcam.follow_target = _cible


func _physics_process(delta: float) -> void:
	_cible.position.x += VITESSE * delta
	_image += 1
	if _image < IMAGES:
		return
	var ecart := _camera.global_position.distance_to(_cible.global_position + DECALAGE)
	if ecart < 0.1:
		print("EXEMPLE VERIFIE : la caméra suit la cible à %.3f m près" % ecart)
	else:
		push_error("la caméra est à %.3f m de la position attendue" % ecart)
	get_tree().quit()
