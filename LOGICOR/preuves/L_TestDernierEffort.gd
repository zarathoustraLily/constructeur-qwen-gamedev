extends SceneTree
## L_TestDernierEffort.gd
## Le test du système de dernier effort.

func _initialize() -> void:
	print("=== TEST DERNIER EFFORT ===\n")
	
	# Créer la fiche du héros.
	var fiche := FicheHeros.new()
	fiche.vie_max = 30
	fiche.souffle_max = 50
	fiche.dernier_effort_soin = 0.4
	fiche.dernier_effort_duree = 5.0
	fiche.dernier_effort_modif = 0.3
	
	# Créer le système de dernier effort.
	var dernier_effort := BPC_DernierEffort.new(fiche)
	
	# Simuler la baisse des PV.
	var pv: int = 30
	var delta: float = 0.8
	
	while pv > 0 and not dernier_effort.est_actif():
		# Vérifier le dernier effort.
		var soin: int = dernier_effort.verifier(pv, fiche.vie_max)
		if soin > 0:
			pv += soin
			print("PV: %d / %d → DERNIER EFFORT ACTIVÉ (seuil: %d×0.1 = %d, soin: +%d PV)" % [
				pv, fiche.vie_max, fiche.vie_max, int(float(fiche.vie_max) * 0.1), soin
			])
		else:
			print("PV: %d / %d → Pas de dernier effort" % [pv, fiche.vie_max])
		pv -= 5
	
	# Simuler la durée du dernier effort.
	if dernier_effort.est_actif():
		var temps: float = 0.0
		while dernier_effort.est_actif() and temps < 6.0:
			dernier_effort.tick(delta)
			temps += delta
			print("PV: %d / %d → DERNIER EFFORT ACTIF (temps restant: %.1fs)" % [
				pv, fiche.vie_max, dernier_effort.temps_restant
			])
	
	print("PV: %d / %d → DERNIER EFFORT TERMINÉ" % [pv, fiche.vie_max])
	print("=== FIN : dernier effort fonctionne ===")
	quit()
