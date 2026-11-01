extends SceneTree
## Rend des séquences d'images de simulations, et ce qu'elles montrent en chiffres : la vérité des paires d'images. Sans fenêtre ni
## carte : tout passe par le processeur. Copié dans un projet d'étape par `usine/paires/voir_fluide.py`.
##   godot --headless --path . -s res://voir_fluide.gd ++ <scénarios.json> <dossier des images> <vérité.json>

const WIDTH := 640
const HEIGHT := 360
## Une valeur plus grande que ça n'a plus de sens : le calcul s'est emballé.
const RUNAWAY := 1000.0


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var scenarios: Array = JSON.parse_string(FileAccess.get_file_as_string(arguments[0]))
	var results: Array = []
	for scenario: Dictionary in scenarios:
		results.append(_run(scenario, arguments[1]))
	var file: FileAccess = FileAccess.open(arguments[2], FileAccess.WRITE)
	file.store_string(JSON.stringify(results))
	file.close()
	quit()


## Joue un scénario, rend ses images et rend ses mesures, une par image.
func _run(scenario: Dictionary, folder: String) -> Dictionary:
	var settings: FluidSettings = FluidSettings.new()
	settings.width = int(scenario["largeur"])
	settings.height = int(scenario["hauteur"])
	settings.iterations = int(scenario["passes"])
	settings.relaxation = float(scenario["relaxation"])
	settings.dissipation = float(scenario["perte"])
	settings.viscosity = 0.0
	settings.diffusion = float(scenario.get("diffusion", 0.0))
	settings.sharp_transport = bool(scenario["macormack"])
	settings.vortex_strength = float(scenario["tourbillons"])
	var solver: FluidSolver = FluidSolver.new(settings)
	for box: Array in scenario["murs"]:
		solver.walls.add_box(int(box[0]), int(box[1]), int(box[2]), int(box[3]))
	if bool(scenario["feu"]):
		var fire: FireSettings = FireSettings.new()
		fire.ignition = 0.25
		fire.buoyancy = float(scenario["poussee"])
		fire.cooling = float(scenario["refroidissement"])
		solver.fire = fire
	var source: Array = scenario["source"]
	var force: Array = scenario["force"]
	var delta: float = float(scenario["delta"])
	var images: Array[int] = []
	for number: float in scenario["images"]:
		images.append(int(number))
	var ramp: Gradient = _ramp(int(scenario["couleurs"]))
	var measures: Array = []
	for step: int in images[images.size() - 1] + 1:
		if bool(scenario["feu"]):
			solver.fuel.add_disc(source[0], source[1], source[2], 8.0 * delta)
			solver.temperature.add_disc(source[0], source[1], source[2], 3.0 * delta)
		else:
			solver.density.add_disc(source[0], source[1], source[2], 6.0 * delta)
			solver.add_force(source[0], source[1], source[2], float(force[0]) * delta, float(force[1]) * delta)
		solver.step(delta)
		var shown: FluidField = solver.temperature if bool(scenario["feu"]) else solver.density
		if step in images:
			var name: String = "%s_%d.png" % [scenario["nom"], measures.size()]
			_save(shown, solver.walls, ramp, float(scenario["clair"]), folder.path_join(name))
			measures.append(_measure(shown, step * delta))
	return {"nom": scenario["nom"], "mesures": measures}


func _ramp(index: int) -> Gradient:
	var ramp: Gradient = Gradient.new()
	var colors: Array[PackedColorArray] = [
		PackedColorArray([Color.BLACK, Color(0.75, 0.75, 0.8)]),
		PackedColorArray([Color.BLACK, Color(1.0, 0.5, 0.1)]),
		PackedColorArray([Color(0.03, 0.05, 0.1), Color(0.4, 0.8, 1.0)]),
	]
	ramp.colors = colors[index % colors.size()]
	return ramp


## Enregistre `field` en couleurs, les murs en gris, à la taille des images.
func _save(field: FluidField, walls: ObstacleMask, ramp: Gradient, brightest: float, path: String) -> void:
	var image: Image = FluidImage.colored(field, ramp, brightest)
	for y: int in field.height:
		for x: int in field.width:
			if walls.is_solid(x, y):
				image.set_pixel(x, y, Color(0.35, 0.35, 0.35))
	image.resize(WIDTH, HEIGHT, Image.INTERPOLATE_BILINEAR)
	image.save_png(path)


## Ce que montre un champ : son total, son pic, son centre de gravité, et les bords de ce qui dépasse un vingtième du pic.
func _measure(field: FluidField, instant: float) -> Dictionary:
	var total: float = 0.0
	var peak: float = 0.0
	var center: Vector2 = Vector2.ZERO
	for y: int in field.height:
		for x: int in field.width:
			var value: float = field.at(x, y)
			if is_nan(value) or is_inf(value):
				return {"instant": instant, "emballe": true}
			total += value
			peak = maxf(peak, value)
			center += Vector2(x, y) * value
	var box: Rect2i = Rect2i()
	var first: bool = true
	for y: int in field.height:
		for x: int in field.width:
			if field.at(x, y) > peak * 0.05:
				box = Rect2i(x, y, 1, 1) if first else box.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
				first = false
	center = center / maxf(total, 0.0001)
	return {"instant": instant, "total": total, "pic": peak, "centre": [center.x, center.y], "emballe": peak > RUNAWAY,
			"gauche": box.position.x, "droite": box.end.x, "haut": box.position.y, "bas": box.end.y}
