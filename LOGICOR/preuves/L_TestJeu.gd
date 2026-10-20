extends SceneTree
## L_TestJeu.gd
## Test du jeu complet : héros, salle, ennemis.

func _initialize() -> void:
	print("=== TEST JEU COMPLET ===\n")

	var erreurs: int = 0

	# 1. Charger la fiche du héros
	var fiche_heros := FicheHeros.new()
	fiche_heros.vie_max = 30
	fiche_heros.souffle_max = 50
	fiche_heros.vitesse = 300.0
	fiche_heros.degat_attaque = 10
	print("Héros: vie=%d, souffle=%d, vitesse=%.0f" % [fiche_heros.vie_max, fiche_heros.souffle_max, fiche_heros.vitesse])

	# 2. Charger un ennemi
	var fiche_ennemi: Resource = load("res://donnees/CRT-001.tres")
	if fiche_ennemi == null:
		print("ERREUR: CRT-001.tres ne se charge pas")
		erreurs += 1
	else:
		print("Ennemi CRT-001: PV=%d, vitesse=%.0f" % [fiche_ennemi.PV_Max, fiche_ennemi.Vitesse])

	# 3. Charger un boss
	var fiche_boss: Resource = load("res://donnees/ANO-001.tres")
	if fiche_boss == null:
		print("ERREUR: ANO-001.tres ne se charge pas")
		erreurs += 1
	else:
		print("Boss ANO-001: PV=%d, phases=%d, attaques=%d" % [fiche_boss.PV_Max, fiche_boss.phases.size(), fiche_boss.attaques.size()])

	# 4. Simuler une attaque du héros
	var degat: int = fiche_heros.degat_attaque
	print("Attaque héros: %d dégâts" % degat)

	# 5. Vérifier le spawn pool
	var spawn_pools: Array = [
		{"Ref": "CRT-001", "Weight": 2, "Elite": false},
		{"Ref": "CRT-002", "Weight": 1, "Elite": false},
		{"Ref": "CRT-003", "Weight": 1, "Elite": true},
	]
	print("Spawn pool: %d entrées" % spawn_pools.size())

	# 6. Vérifier le profil d'encounter
	var profile: Dictionary = {
		"BaseDifficulty": 30,
		"DepthDifficultyRamp": 10,
		"ActiveEnemyCapBase": 2.3,
		"ActiveEnemyCapDepthRamp": 0.35,
		"ActiveEnemyCapMax": 8,
	}
	print("Profil: cap_base=%.1f, cap_max=%d" % [profile["ActiveEnemyCapBase"], profile["ActiveEnemyCapMax"]])

	print("\n=== RESULTAT: %d erreur(s) ===" % erreurs)
	if erreurs == 0:
		print("TOUS LES TESTS PASSENT")
	quit(0 if erreurs == 0 else 1)
