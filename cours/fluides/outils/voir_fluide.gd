extends SceneTree
## Rend des séquences d'images de simulations, et ce qu'elles montrent en chiffres : la vérité des paires d'images. Sans fenêtre ni
## carte : tout passe par le processeur. Copié dans un projet d'étape par `usine/paires/voir_fluide.py`.
##   godot --headless --path . -s res://voir_fluide.gd ++ <scénarios.json> <dossier des images> <vérité.json>
## Un scénario porte son `code` : `build()` rend le solveur, et `feed(solver, delta)`, s'il existe, le nourrit à chaque pas. C'est ce
## texte qui tourne, tel quel : celui qu'une paire de création donne en réponse.

const WIDTH := 640
const HEIGHT := 360
## Une valeur plus grande que ça n'a plus de sens : le calcul s'est emballé.
const RUNAWAY := 1000.0
const WALL := Color(0.35, 0.35, 0.35)
const GROUND_LOW := Color(0.16, 0.13, 0.1)
const GROUND_HIGH := Color(0.55, 0.47, 0.36)
const WATER := Color(0.2, 0.55, 1.0)
const SLOW := Color(0.15, 0.4, 0.9)
const FAST := Color(0.9, 0.97, 1.0)
const DOT := 5


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
	var script: GDScript = GDScript.new()
	script.source_code = "extends RefCounted\n\n\n" + String(scenario["code"])
	if script.reload() != OK:
		return {"nom": scenario["nom"], "erreur": "le code ne se charge pas"}
	var scene: RefCounted = script.new()
	var solver: RefCounted = scene.build()
	var delta: float = float(scenario["delta"])
	var images: Dictionary[int, bool] = {}
	for number: float in scenario["images"]:
		images[int(number)] = true
	var ramp: Gradient = _ramp(int(scenario["couleurs"]))
	var measures: Array = []
	for step: int in images.keys().max() + 1:
		if scene.has_method("feed"):
			scene.feed(solver, delta)
		solver.step(delta)
		if images.has(step):
			var name: String = "%s_%d.png" % [scenario["nom"], measures.size()]
			_picture(String(scenario["genre"]), solver, ramp, float(scenario["clair"])).save_png(folder.path_join(name))
			measures.append(_measure(String(scenario["genre"]), solver, (step + 1) * delta))
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


## Le champ que montre un genre ; rien pour des particules.
func _field(genre: String, solver: RefCounted) -> FluidField:
	match genre:
		"gaz":
			return solver.density
		"feu":
			return solver.temperature
		"vagues":
			return solver.surface
		"crue":
			return solver.depth
	return null


## L'image de l'état du solveur, à la taille des images.
func _picture(genre: String, solver: RefCounted, ramp: Gradient, brightest: float) -> Image:
	if genre == "flip" or genre == "sph":
		return _dots(solver, brightest)
	var field: FluidField = _field(genre, solver)
	var image: Image
	if genre == "vagues":
		image = _swell(field, ramp, brightest)
	elif genre == "crue":
		image = _flood(solver, brightest)
	else:
		image = FluidImage.colored(field, ramp, brightest)
		for y: int in field.height:
			for x: int in field.width:
				if solver.walls.is_solid(x, y):
					image.set_pixel(x, y, WALL)
	image.resize(WIDTH, HEIGHT, Image.INTERPOLATE_BILINEAR)
	return image


## Une surface qui monte et descend : le creux à gauche de la rampe, l'eau plate au milieu, la crête à droite.
func _swell(field: FluidField, ramp: Gradient, brightest: float) -> Image:
	var image: Image = Image.create(field.width, field.height, false, Image.FORMAT_RGB8)
	for y: int in field.height:
		for x: int in field.width:
			image.set_pixel(x, y, ramp.sample(0.5 + 0.5 * field.at(x, y) / brightest))
	return image


## Le sol, plus clair quand il est haut, et l'eau par-dessus, plus franche quand elle est profonde.
func _flood(solver: FloodSolver, deepest: float) -> Image:
	var image: Image = Image.create(solver.depth.width, solver.depth.height, false, Image.FORMAT_RGB8)
	var highest: float = maxf(solver.ground.peak(), 0.001)
	for y: int in solver.depth.height:
		for x: int in solver.depth.width:
			var land: Color = GROUND_LOW.lerp(GROUND_HIGH, solver.ground.at(x, y) / highest)
			image.set_pixel(x, y, land.lerp(WATER, clampf(solver.depth.at(x, y) / deepest, 0.0, 1.0)))
	return image


## Des particules : un point par particule, plus clair quand elle va vite.
func _dots(solver: RefCounted, fastest: float) -> Image:
	var image: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	image.fill(Color(0.03, 0.04, 0.07))
	var scale: Vector2 = Vector2(WIDTH / float(solver.settings.width), HEIGHT / float(solver.settings.height))
	for i: int in solver.positions.size():
		var place: Vector2 = Vector2(solver.positions[i]) * scale - Vector2(DOT, DOT) * 0.5
		var color: Color = SLOW.lerp(FAST, clampf(solver.velocities[i].length() / fastest, 0.0, 1.0))
		image.fill_rect(Rect2i(Vector2i(place), Vector2i(DOT, DOT)), color)
	return image


## Ce que montre l'état du solveur à cet instant.
func _measure(genre: String, solver: RefCounted, instant: float) -> Dictionary:
	if genre == "flip" or genre == "sph":
		return _measure_dots(solver, instant)
	return _measure_field(_field(genre, solver), instant)


## Un champ : son total, son pic, son centre de gravité, et les bords de ce qui dépasse un vingtième du pic. Une surface d'eau monte et
## descend : c'est l'écart à zéro qui compte.
func _measure_field(field: FluidField, instant: float) -> Dictionary:
	var total: float = 0.0
	var peak: float = 0.0
	var center: Vector2 = Vector2.ZERO
	for y: int in field.height:
		for x: int in field.width:
			var value: float = absf(field.at(x, y))
			if is_nan(value) or is_inf(value):
				return {"instant": instant, "emballe": true}
			total += value
			peak = maxf(peak, value)
			center += Vector2(x, y) * value
	var box: Rect2i = Rect2i()
	var first: bool = true
	for y: int in field.height:
		for x: int in field.width:
			if absf(field.at(x, y)) > peak * 0.05:
				box = Rect2i(x, y, 1, 1) if first else box.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
				first = false
	center = center / maxf(total, 0.0001)
	return {"instant": instant, "total": total, "pic": peak, "centre": [center.x, center.y], "emballe": peak > RUNAWAY,
			"gauche": box.position.x, "droite": box.end.x, "haut": box.position.y, "bas": box.end.y}


## Des particules : leur nombre, la plus grande vitesse, leur centre et leurs bords.
func _measure_dots(solver: RefCounted, instant: float) -> Dictionary:
	var count: int = solver.positions.size()
	var center: Vector2 = Vector2.ZERO
	var low: Vector2 = Vector2(INF, INF)
	var high: Vector2 = Vector2(-INF, -INF)
	var fastest: float = 0.0
	for i: int in count:
		var place: Vector2 = solver.positions[i]
		if is_nan(place.x) or is_nan(place.y) or is_inf(place.x) or is_inf(place.y):
			return {"instant": instant, "emballe": true}
		center += place
		low = low.min(place)
		high = high.max(place)
		fastest = maxf(fastest, solver.velocities[i].length())
	return {"instant": instant, "total": count, "pic": fastest, "centre": [center.x / count, center.y / count], "emballe": fastest > RUNAWAY,
			"gauche": low.x, "droite": high.x, "haut": low.y, "bas": high.y}
