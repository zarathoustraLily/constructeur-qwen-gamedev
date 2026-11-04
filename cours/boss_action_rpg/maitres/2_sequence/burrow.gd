class_name Burrow extends Level
## Le Terrier : la chambre de Bobine et l'Établi. Ce que Bobine choisit à l'Établi lui revient ici.

@onready var _armory: Armory = $Armory
#@ 29+
@onready var _door: PlinthDoor = $Door
#@ all


func _ready() -> void:
	super()
	_armory.chosen.connect(hero.equip)
#@ 29+
	hero.weapon_changed.connect(_on_armed)


func _on_armed(_kit: WeaponKit) -> void:
	_door.open_door()
#@ all
