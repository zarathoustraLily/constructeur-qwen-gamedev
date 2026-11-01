extends SceneTree
## Une arme à 0,1 s entre deux tirs, décomptée à 60 images par seconde : combien de tirs en 10 s, selon le test de fin ?


func _initialize() -> void:
	var image: float = 1.0 / 60.0
	var six: float = 0.1
	for _i: int in 6:
		six -= image
	print("0,1 s moins 6 images : ", String.num_scientific(six))
	for souple: bool in [false, true]:
		var reste: float = 0.0
		var tirs: int = 0
		for _i: int in 600:
			reste = maxf(reste - image, 0.0)
			if reste <= 0.0 or (souple and is_zero_approx(reste)):
				tirs += 1
				reste = 0.1
		print("is_zero_approx ", souple, " : ", tirs, " tirs en 10 s")
	quit()
