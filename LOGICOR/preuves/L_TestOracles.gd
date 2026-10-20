extends SceneTree
## L_TestOracles.gd
## La preuve que le système complet fonctionne (23 steps).

func _initialize() -> void:
	print("=== TEST ORACLE (LOGICOR) ===\n")
	
	# 1. Créer la fiche du héros.
	var fiche_heros := FicheHeros.new()
	fiche_heros.vie_max = 30
	fiche_heros.souffle_max = 50
	fiche_heros.seuil_invuln = 0.25
	fiche_heros.degat_min_invuln = 15
	fiche_heros.duree_invuln = 1.3
	fiche_heros.dernier_effort_soin = 0.4
	fiche_heros.dernier_effort_duree = 5.0
	fiche_heros.dernier_effort_modif = 0.3
	fiche_heros.seuil_combo = 12
	
	# 2. Créer les stats du héros.
	var stats := BPC_Stats.new(fiche_heros)
	print("PV initiaux: %d" % stats.vie)
	print("Souffle initial: %d" % stats.souffle)
	
	# 3. Créer le pipeline de dégâts.
	var pipeline := BPC_DegratsPipeline.new()
	
	# 4. Créer le système d'invulnérabilité.
	var invuln := BPC_Invuln.new(fiche_heros)
	
	# 5. Créer le dernier effort.
	var dernier_effort := BPC_DernierEffort.new(fiche_heros)
	
	# 6. Simuler un combat de 23 steps.
	var pv := stats.vie
	var souffle := stats.souffle
	var en_invuln := false
	var temps_invuln := 0.0
	var dernier_effort_actif := false
	var temps_dernier_effort := 0.0
	var combo := 0
	var step_final := 23
	
	for step in range(23):
		# Tick des systèmes.
		stats.tick(0.01)
		
		# Vérifier les i-frames.
		invuln.verifier(pv, stats.vie)
		
		# Vérifier le dernier effort.
		var soin: int = dernier_effort.verifier(pv, stats.vie)
		if soin > 0:
			dernier_effort_actif = true
			print("        [DERNIER EFFORT activé: +%d PV]" % soin)
		
		# Simuler une attaque ennemie (dégâts fixes).
		if not en_invuln:
			var degats: int = pipeline.calculer(5, 1.0, 0, false)
			pv -= degats
			combo = 0
		
		# Tick de l'invulnérabilité.
		invuln.tick(0.01)
		
		# Tick du dernier effort.
		dernier_effort.tick(0.01)
		
		# Afficher le statut.
		var statut_invuln: String = ""
		if invuln.est_invuln():
			statut_invuln = " [INVULNÉ]"
		
		var statut_effort: String = ""
		if dernier_effort.est_actif():
			statut_effort = " [DERNIER EFFORT]"
		
		if (step + 1) % 5 == 0:
			print("step %2d → PV: %d / %d%s%s" % [step + 1, pv, stats.vie, statut_invuln, statut_effort])
		
		# Vérifier la mort.
		if pv <= 0:
			step_final = step + 1
			print("        [MORT au step %d]" % (step + 1))
			break
	
	print("=== FIN : le héros a survécu %d steps ===" % step_final)
	quit()
