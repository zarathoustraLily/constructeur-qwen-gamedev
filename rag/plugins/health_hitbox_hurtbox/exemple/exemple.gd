extends Node3D
## Exemple minimal de Health, HitBoxes, HurtBoxes (v5.0.4, GDScript) : une zone qui frappe (BasicHitBox3D, 3 dégâts)
## touche une zone qui encaisse (BasicHurtBox3D), reliée à une santé (Health) de 10 points.

const IMAGES: int = 10

var _sante: Health
var _degats_recus: Array[int] = []
var _image: int = 0


func _ready() -> void:
	_sante = Health.new()
	_sante.max = 10
	_sante.current = 10
	_sante.damaged.connect(_on_damaged)
	add_child(_sante)
	var encaisse := BasicHurtBox3D.new()
	encaisse.health = _sante
	encaisse.add_child(_forme())
	add_child(encaisse)
	var frappe := BasicHitBox3D.new()
	frappe.amount = 3
	frappe.add_child(_forme())
	frappe.position = Vector3(0.5, 0.0, 0.0)  # les deux sphères se recouvrent
	add_child(frappe)


func _forme() -> CollisionShape3D:
	var forme := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	forme.shape = sphere
	return forme


func _on_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float,
		applied: int) -> void:
	_degats_recus.append(applied)


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image < IMAGES:
		return
	if _sante.current == 7 and _degats_recus == [3]:
		print("EXEMPLE VERIFIE : santé %d/%d après un coup de %d" % [_sante.current, _sante.max, _degats_recus[0]])
	else:
		push_error("santé %d, dégâts reçus %s" % [_sante.current, _degats_recus])
	get_tree().quit()
