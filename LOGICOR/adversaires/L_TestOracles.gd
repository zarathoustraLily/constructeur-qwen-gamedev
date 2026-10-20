extends SceneTree
## L_TestOracles.gd
## La preuve que l'IA fonctionne (23 steps).

func _initialize() -> void:
	print("=== TEST IA (LOGICOR) ===\n")
	
	# Fabriquer la fiche de l'ennemi.
	var fiche := FicheEnnemi.new()
	fiche.nom = "Unit001"
	fiche.vie_max = 100
	fiche.vitesse = 200.0
	fiche.portee = 120.0
	fiche.distance_max = 600.0
	fiche.outils = [
		{ "nom": "Slam", "when": "toujours", "portee": 120.0, "apres": { "chance": 0.35, "devenir": "Charge" } },
		{ "nom": "Charge", "when": "toujours", "portee": 400.0, "apres": { "chance": 1.0, "devenir": "Slam" } },
	]
	fiche.stades = [
		{ "seuil": 1.00, "armes": ["Slam", "Charge"], "nouveau_comportement": "" },
		{ "seuil": 0.30, "armes": ["Charge"], "nouveau_comportement": "furieux" },
	]
	
	# Fabriquer l'arbre de décision.
	var arbre := BPC_PhaseManager.new(fiche.stades)
	var cible := BPC_AggroSense.new(600.0, 0.0)
	
	# Simuler 23 steps.
	var pv := 100
	var pos_ennemi := Vector3(500.0, 0.0, 0.0)
	var pos_cible := Vector3(0.0, 0.0, 0.0)
	
	for step in range(23):
		var action: String = arbre.tick(pv, pos_ennemi, pos_cible, true)
		print("step %2d → %s" % [step + 1, action])
		
		# Simuler le mouvement.
		if action == "S_AVANCER":
			var dir: Vector3 = (pos_cible - pos_ennemi).normalized()
			pos_ennemi += dir * 20.0
		elif action == "S_FRAPPER":
			pv -= 5
			if pv <= 0:
				pv = 0
				print("        [mort]")
				break
		elif action == "S_MARQUER":
			cible.marquer(null)
		elif action == "S_REPLI":
			pos_ennemi += Vector3(50.0, 0.0, 0.0)
		
		if (step + 1) % 5 == 0:
			print("        [PV Unit001 = %d %%]" % pv)
	
	print("=== FIN : le Unit001 a descendu l'arbre %d fois ===" % (step + 1))
	quit()
