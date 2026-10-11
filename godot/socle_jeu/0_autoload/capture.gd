extends Node
## Captures horodatées (béquille, point 8) : plusieurs images du jeu en une seule grille,
## avec, pour chaque case, ce que le journal Trace a noté depuis la case précédente.
## Une image seule prouve qu'une pose a existé ; une suite d'images montre le mouvement.
##
##   godot --path <projet> --fixed-fps 60 -- --capture=<fichier.png> --capture-frames=30,60,90,120
##
## Écrit la grille <fichier.png> (de gauche à droite, puis de haut en bas) et la légende
## <fichier.png>.txt (case, image, temps de jeu, lignes du journal), puis quitte.
## Pour voir une action, appuyer sur des touches entre deux images (répétable) :
##   --capture-press=move_up:0-90 --capture-press=fire:60-240
## Toujours passer --fixed-fps 60 : l'image N tombe alors à N/60 s de jeu.
## En headless rien n'est dessiné : la légende et le journal sont écrits quand même.
## Sans --capture, le nœud s'éteint et ne coûte rien.
## Dépend de : le journal (groupe « journal »), s'il existe.


## Une touche tenue de la première à la dernière image.
class Press:
	var action: StringName
	var first: int
	var last: int

	func _init(new_action: StringName, new_first: int, new_last: int) -> void:
		action = new_action
		first = new_first
		last = new_last


const GAP := 4
const BACKDROP := Color(0.08, 0.08, 0.11, 1.0)
const DEFAULT_FRAMES: Array[int] = [30, 60, 90, 120, 150, 180, 210, 240]

var capturing: bool = false
var _frame: int = 0
var _presses: Array[Press] = []


func _process(_delta: float) -> void:
	_frame += 1
	for press in _presses:
		if _frame == press.first:
			Input.action_press(press.action)
		elif _frame == press.last + 1:
			Input.action_release(press.action)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var path := ""
	var frames := PackedInt32Array(DEFAULT_FRAMES)
	var scale := 0.5
	var cols := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-frames="):
			frames = parse_frames(arg.trim_prefix("--capture-frames="))
		elif arg.begins_with("--capture-scale="):
			scale = float(arg.trim_prefix("--capture-scale="))
		elif arg.begins_with("--capture-press="):
			var press := parse_press(arg.trim_prefix("--capture-press="))
			if press != null:
				_presses.append(press)
		elif arg.begins_with("--capture-cols="):
			cols = maxi(1, int(arg.trim_prefix("--capture-cols=")))
	if path.is_empty() or frames.is_empty():
		set_process(false)
		return
	capturing = true
	var shots: Array[Image] = []
	var legend: PackedStringArray = []
	var fps := Engine.physics_ticks_per_second
	# Le journal est lu s'il existe : la capture marche aussi dans un projet qui ne l'a pas.
	var trace := get_tree().get_first_node_in_group(&"journal")
	var seen: int = _journal(trace).size()
	for i in frames.size():
		while _frame < frames[i]:
			await get_tree().process_frame
		var img: Image = null
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			img = get_viewport().get_texture().get_image()
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			if not is_equal_approx(scale, 1.0):
				img.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_BILINEAR)
			shots.append(img)
		legend.append("case %d (ligne %d, colonne %d) : image %d, %.2f s de jeu"
				% [i + 1, i / cols + 1, i % cols + 1, frames[i], float(frames[i]) / fps])
		var lines := _journal(trace)
		for line in lines.slice(seen):
			legend.append("    " + line)
		seen = lines.size()
	if shots.is_empty():
		legend.insert(0, "pas d'image : rendu absent (headless) ; le journal reste valable")
	else:
		var err := compose(shots, cols).save_png(path)
		legend.insert(0, "grille %s : %d cases, %d par ligne (erreur %d)" % [path.get_file(), shots.size(), cols, err])
	var f := FileAccess.open(path + ".txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(legend) + "\n")
		f.close()
	print("[capture] %s" % legend[0])
	get_tree().quit()


func _journal(trace: Node) -> PackedStringArray:
	return trace.get(&"lines") as PackedStringArray if trace != null else PackedStringArray()


static func parse_frames(raw: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	for piece in raw.split(",", false):
		out.append(int(piece.strip_edges()))
	out.sort()
	return out


## « move_up:0-90 » → la touche move_up tenue des images 0 à 90 ; null si l'action n'existe pas
## ou si le texte est faux.
static func parse_press(raw: String) -> Press:
	var action := StringName(raw.get_slice(":", 0))
	var span := raw.get_slice(":", 1)
	if not InputMap.has_action(action) or not span.contains("-"):
		return null
	return Press.new(action, int(span.get_slice("-", 0)), int(span.get_slice("-", 1)))


static func compose(shots: Array[Image], cols: int) -> Image:
	var c := mini(cols, shots.size())
	var r := ceili(float(shots.size()) / float(c))
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create_empty(c * w + (c + 1) * GAP, r * h + (r + 1) * GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKDROP)
	for i in shots.size():
		var at := Vector2i(GAP + (i % c) * (w + GAP), GAP + (i / c) * (h + GAP))
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, Vector2i(w, h)), at)
	return sheet
