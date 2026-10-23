extends Node
## Exemple minimal de GLoot (v3.0.2, GDScript) : un inventaire limité à 5 de poids accepte une potion (1) et une
## épée (4), puis refuse une seconde épée.


func _ready() -> void:
	# Les prototypes des objets : une ressource JSON (dans un projet, un fichier .json de 5_data).
	var prototypes := JSON.new()
	prototypes.data = {"potion": {"name": "Potion", "weight": 1.0}, "epee": {"name": "Épée", "weight": 4.0}}
	var sac := Inventory.new()
	sac.protoset = prototypes
	# Les contraintes sont des nœuds enfants de l'inventaire.
	var poids := WeightConstraint.new()
	poids.capacity = 5.0
	sac.add_child(poids)
	add_child(sac)
	var potion := sac.create_and_add_item("potion")
	var epee := sac.create_and_add_item("epee")
	var seconde := sac.create_item("epee")
	var refusee := not sac.can_add_item(seconde)
	if potion != null and epee != null and refusee and is_equal_approx(poids.get_occupied_space(), 5.0) \
			and sac.get_item_count() == 2:
		print("EXEMPLE VERIFIE : %d objets, poids %.1f sur %.1f, seconde épée refusée"
				% [sac.get_item_count(), poids.get_occupied_space(), poids.capacity])
	else:
		push_error("objets %d, poids %.1f, refus %s" % [sac.get_item_count(), poids.get_occupied_space(), refusee])
	# libérer l'inventaire avant de quitter : sinon ses objets restent en mémoire à la sortie
	sac.queue_free()
	get_tree().quit.call_deferred()
