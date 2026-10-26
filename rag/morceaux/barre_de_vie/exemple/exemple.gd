extends Node
## Exemple : barre de vie. Un HealthComponent du socle (10 points) et une barre qui l'écoute. Un coup de 3 : à
## mi-glissement la barre est entre 10 et 7, à la fin elle vaut 7. Deux coups l'un sur l'autre (2 puis 4) : la barre
## finit à 1, la vie restante.

const GLISSEMENT := 0.3  # dans un jeu, réglé dans la scène du HUD


func _ready() -> void:
	var vie := HealthComponent.new()
	add_child(vie)
	vie.setup(10, 0.0)
	var barre := HealthBar.new()
	barre.slide_duration = GLISSEMENT
	add_child(barre)
	barre.setup(vie)
	var depart := barre.value
	vie.take_damage(3)
	await get_tree().create_timer(GLISSEMENT * 0.5).timeout
	var milieu := barre.value
	await get_tree().create_timer(GLISSEMENT).timeout
	var fin := barre.value
	vie.take_damage(2)
	await get_tree().process_frame
	vie.take_damage(4)
	await get_tree().create_timer(GLISSEMENT * 1.5).timeout
	var apres_deux := barre.value
	var ok := depart == 10.0 and barre.max_value == 10.0 and milieu < 10.0 and milieu > 7.0
	if ok and is_equal_approx(fin, 7.0) and is_equal_approx(apres_deux, 1.0) and vie.current_health == 1:
		print("EXEMPLE VERIFIE : barre à %.1f sur %.0f ; coup de 3 : %.2f à mi-glissement, %.1f à la fin ; coups de 2 puis 4 : %.1f"
				% [depart, barre.max_value, milieu, fin, apres_deux])
	else:
		push_error("départ %.1f/%.0f, milieu %.2f, fin %.2f, après deux coups %.2f, vie %d"
				% [depart, barre.max_value, milieu, fin, apres_deux, vie.current_health])
	get_tree().quit()
