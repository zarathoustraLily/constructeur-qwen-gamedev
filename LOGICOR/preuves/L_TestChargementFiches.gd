extends SceneTree
## L_TestChargementFiches.gd
## Vérifie que les fiches .tres Space Dracula se chargent correctement.

func _initialize() -> void:
	print("=== TEST CHARGEMENT FICHES .tres ===\n")
	
	var erreurs: int = 0
	
	# Charger un ennemi.
	var ennemi: Resource = load("res://donnees/CRT-001.tres")
	if ennemi == null:
		print("ERREUR: CRT-001.tres ne se charge pas")
		erreurs += 1
	else:
		var script = ennemi.get_script()
		if script != null:
			print("CRT-001: PV_Max=%d, Vitesse=%.1f, arsenal=%s" % [ennemi.PV_Max, ennemi.Vitesse, ennemi.arsenal])
		else:
			print("CRT-001: script=null, props=%s" % [ennemi.get_property_list()])
	
	# Charger un boss.
	var boss: Resource = load("res://donnees/ANO-001.tres")
	if boss == null:
		print("ERREUR: ANO-001.tres ne se charge pas")
		erreurs += 1
	else:
		var script = boss.get_script()
		if script != null:
			print("ANO-001: PV_Max=%d, phases=%d, attaques=%d" % [boss.PV_Max, boss.phases.size(), boss.attaques.size()])
		else:
			print("ANO-001: script=null")
	
	# Charger une arme.
	var arme: Resource = load("res://donnees/REL-001.tres")
	if arme == null:
		print("ERREUR: REL-001.tres ne se charge pas")
		erreurs += 1
	else:
		var script = arme.get_script()
		if script != null:
			print("REL-001: props=%s" % [arme.props])
		else:
			print("REL-001: script=null")
	
	# Charger un mini-boss.
	var mb: Resource = load("res://donnees/MIN-001.tres")
	if mb == null:
		print("ERREUR: MIN-001.tres ne se charge pas")
		erreurs += 1
	else:
		var script = mb.get_script()
		if script != null:
			print("MIN-001: PV_Max=%d, phases=%d, attaques=%d" % [mb.PV_Max, mb.phases.size(), mb.attaques.size()])
		else:
			print("MIN-001: script=null")
	
	# Charger une salle.
	var salle: Resource = load("res://donnees/SLA-01.tres")
	if salle == null:
		print("ERREUR: SLA-01.tres ne se charge pas")
		erreurs += 1
	else:
		var script = salle.get_script()
		if script != null:
			print("SLA-01: niveau=%d, profil=%s, pool=%d, types=%d" % [salle.niveau, salle.profil_nom, salle.pool.size(), salle.nb_types])
		else:
			print("SLA-01: script=null")
	
	if erreurs == 0:
		print("\n=== TOUTES LES FICHES SE CHARGENT CORRECTEMENT ===")
	else:
		print("\n=== %d ERREURS DE CHARGEMENT ===" % erreurs)
	
	quit()
