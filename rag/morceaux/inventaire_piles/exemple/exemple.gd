extends Node
## Exemple : inventaire de 3 emplacements. 25 potions (piles de 10) occupent 10, 10 et 5 ; une épée ne trouve plus de
## place ; retirer 12 potions vide la dernière pile et entame la deuxième ; l'épée entre alors. Une copie de la potion
## (duplicate) s'empile avec l'original : la comparaison se fait par id.

const POTION: ItemData = preload("res://5_data/items/potion.tres")
const SWORD: ItemData = preload("res://5_data/items/sword.tres")

var _changements := 0


func _ready() -> void:
	var inventaire := InventoryComponent.new()
	inventaire.slot_count = 3
	add_child(inventaire)
	inventaire.changed.connect(func() -> void: _changements += 1)
	var reste_potions := inventaire.add(POTION, 25)
	var apres_potions := inventaire.counts()
	var reste_epee := inventaire.add(SWORD, 1)
	var retirees := inventaire.remove(POTION, 12)
	var apres_retrait := inventaire.counts()
	var reste_epee_2 := inventaire.add(SWORD, 1)
	var copie := POTION.duplicate() as ItemData
	var reste_copie := inventaire.add(copie, 2)
	var potions := inventaire.count_of(POTION)
	var ok := reste_potions == 0 and apres_potions == [10, 10, 5] and reste_epee == 1 and retirees == 12
	ok = ok and apres_retrait == [10, 3, 0] and reste_epee_2 == 0 and reste_copie == 0 and potions == 15
	if ok and copie != POTION and _changements == 4:
		print(("EXEMPLE VERIFIE : 25 potions → %s, reste %d ; épée refusée (reste %d) ; 12 retirées → %s ; épée acceptée ; "
				+ "2 potions copiées (duplicate) empilées : %d potions ; %d signaux changed")
				% [apres_potions, reste_potions, reste_epee, apres_retrait, potions, _changements])
	else:
		push_error("potions %s reste %d, épée %d, retirées %d → %s, épée %d, copie %d, total %d, signaux %d"
				% [apres_potions, reste_potions, reste_epee, retirees, apres_retrait, reste_epee_2, reste_copie, potions,
				_changements])
	get_tree().quit()
