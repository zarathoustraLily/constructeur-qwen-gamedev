class_name Armory extends Node3D
## L'Établi : les socles posés sous ce nœud. Il tient une seule règle : un seul socle est vide à la fois. L'arme qu'on avait
## retourne sur son socle quand on en prend une autre.

## Bobine vient de prendre l'arme `kit`.
signal chosen(kit: WeaponKit)

## Les socles.
var stands: Array[WeaponStand] = []


func _ready() -> void:
	for child: Node in get_children():
		if child is WeaponStand:
			var stand: WeaponStand = child as WeaponStand
			stands.append(stand)
			stand.taken.connect(_on_taken)


func _on_taken(kit: WeaponKit) -> void:
	for stand: WeaponStand in stands:
		stand.set_empty(stand.kit == kit)
	chosen.emit(kit)
