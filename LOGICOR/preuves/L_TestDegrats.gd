extends SceneTree
## L_TestDegrats.gd
## Le test du pipeline de dégâts.

func _initialize() -> void:
	print("=== TEST DEGRATS ===\n")
	
	var tests: Array = [
		{ "base": 10, "mult": 1.0, "additif": 0, "crit": false, "attendu": 10 },
		{ "base": 10, "mult": 1.0, "additif": 0, "crit": true, "attendu": 30 },
		{ "base": 10, "mult": 1.5, "additif": 5, "crit": false, "attendu": 20 },
		{ "base": 10, "mult": 1.5, "additif": 5, "crit": true, "attendu": 60 },
		{ "base": 5, "mult": 0.8, "additif": 2, "crit": false, "attendu": 6 },
	]
	
	var passés: int = 0
	for test in tests:
		var resultat: int = BPC_DegratsPipeline.calculer(
			test.base,
			test.mult,
			test.additif,
			test.crit
		)
		var statut: String = "OK" if resultat == test.attendu else "ÉCHEC"
		print("Base: %d, Mult: %.1f, Additif: %d, Crit: %s → %d (%s)" % [
			test.base, test.mult, test.additif, test.crit, resultat, statut
		])
		if resultat == test.attendu:
			passés += 1
	
	print("=== FIN : %d tests passés ===" % passés)
	quit()
