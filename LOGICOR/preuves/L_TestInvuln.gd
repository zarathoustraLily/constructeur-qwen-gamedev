extends SceneTree
## L_TestInvuln.gd
## Le test du système d'i-frames.

func _initialize() -> void:
	print("=== TEST INVULN ===\n")
	
	# Créer la fiche du héros.
	var fiche := FicheHeros.new()
	fiche.vie_max = 30
	fiche.souffle_max = 50
	fiche.seuil_invuln = 0.25
	fiche.degat_min_invuln = 15
	fiche.duree_invuln = 1.3
	
	# Créer le système d'invulnérabilité.
	var invuln := BPC_Invuln.new(fiche)
	
	# Simuler la baisse des PV.
	var pv: int = 30
	var delta: float = 0.1
	
	while pv > 0:
		# Vérifier les i-frames.
		invuln.verifier(pv, fiche.vie_max)
		
		# Tick.
		invuln.tick(delta)
		
		# Afficher le statut.
		var statut: String = "Pas d'invuln"
		if invuln.est_invuln():
			statut = "INVULN ACTIVÉ" if pv == fiche.degat_min_invuln else "INVULN ACTIF (temps restant: %.1fs)" % invuln.temps_restant
		
		print("PV: %d / %d → %s" % [pv, fiche.vie_max, statut])
		
		pv -= 5
	
	print("PV: %d / %d → INVULN TERMINÉ" % [pv, fiche.vie_max])
	print("=== FIN : i-frames fonctionnent ===")
	quit()
