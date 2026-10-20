extends SceneTree
## L_TestDirectorRun.gd
## Le test du run director.

func _initialize() -> void:
	print("=== TEST DIRECTOR RUN ===\n")
	
	# Créer la fiche du héros.
	var fiche_heros := FicheHeros.new()
	fiche_heros.vie_max = 30
	fiche_heros.souffle_max = 50
	fiche_heros.cout_porte_secrete_base = 10.0
	fiche_heros.cout_porte_secrete_ramp = 0.4
	
	# Créer les fiches des ennemis.
	var fiches_ennemis: Array = []
	for i in range(3):
		var fiche := FicheEnnemi.new()
		fiche.id = "CRT-%03d" % (i + 1)
		fiche.nom = "CRT-%03d" % (i + 1)
		fiche.PV_Max = 100
		fiche.Vitesse = 200.0
		fiche.NoteDifficulte = 50
		fiches_ennemis.append(fiche)
	
	# Créer les fiches des salles.
	var fiches_salles: Array = []
	for i in range(3):
		var fiche := FicheSalle.new()
		fiche.nom = "Salle%03d" % (i + 1)
		fiche.types = ["combat"] if i < 2 else ["boss"]
		fiche.delai_apparition = 0.5
		fiche.delai_deverrouillage = 0.4
		fiche.delai_fin_combat = 0.2
		fiche.encounters = [
			{ "enemies": ["Unit%03d" % (i + 1)], "count": 1 + i, "difficulte": 50 + i * 10 },
		]
		fiche.issues = ["Salle%03d" % (i + 2)] if i < 2 else []
		fiche.cout_combat = float(i * 5)
		fiche.cout_vie = i
		fiches_salles.append(fiche)
	
	# Créer le run director.
	var director := BPC_DirectorRun.new()
	director.fiche_heros = fiche_heros
	director.fiches_ennemis = fiches_ennemis
	director.fiches_salles = fiches_salles
	
	# Démarrer le run.
	director.demarrer_run()
	
	# Passer par les salles.
	var profondeur: int = 1
	while not director.run_terminé and profondeur <= 3:
		var salle: FicheSalle = director.salle_actuelle
		if salle:
			print("Salle %d: %s" % [profondeur, salle.nom])
		else:
			print("Salle %d: (aucune)" % profondeur)
		director.salle_suivante()
		profondeur += 1
	
	# Terminer le run.
	director.terminer_run()
	print("Run terminé")
	
	# Tester la difficulté.
	var diff: int = director.calculer_difficulte(3, 50, 10.0)
	print("Difficulté à la profondeur 3: %d" % diff)
	
	# Tester le coût de la porte secrète.
	var cout: int = director.cout_porte_secrete(3)
	print("Coût porte secrète à la profondeur 3: %d" % cout)
	
	print("=== FIN : run director fonctionne ===")
	quit(0)
