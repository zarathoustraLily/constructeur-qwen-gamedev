class_name Hitbox extends Area3D
## Une zone de coup (une attaque du boss) : allumée, elle frappe une fois chaque corps qui la touche et qui sait
## recevoir un coup (une méthode take_hit(montant, origine)) ; éteinte, elle ne fait rien. On l'allume au moment du
## coup et on l'éteint après : un coup ne touche que pendant sa fenêtre, et une seule fois par allumage.

## Le coup a porté sur `body` ; `dealt` : les dégâts vraiment faits (0 : esquivé ou dans le répit).
signal landed(body: Node3D, dealt: float)

## Les dégâts du coup en cours, posés à l'allumage.
var damage: float = 0.0
## Vrai pendant la fenêtre du coup.
var active: bool = false

var _struck: Array[Node3D] = []


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BOSS_HITS)
	collision_mask = Layers.bit(Layers.HERO)
	monitorable = false
	body_entered.connect(_on_body_entered)


## Allume la zone pour un coup de `amount` : ce qui la touche déjà est frappé tout de suite, ce qui entre ensuite au
## moment où il entre.
func activate(amount: float) -> void:
	damage = amount
	active = true
	_struck.clear()
	for body: Node3D in get_overlapping_bodies():
		_strike(body)


## Éteint la zone : le coup est fini.
func deactivate() -> void:
	active = false


func _on_body_entered(body: Node3D) -> void:
	if active:
		_strike(body)


func _strike(body: Node3D) -> void:
	if body in _struck or not body.has_method(&"take_hit"):
		return
	_struck.append(body)
	var dealt: float = body.call(&"take_hit", damage, global_position)
	landed.emit(body, dealt)
