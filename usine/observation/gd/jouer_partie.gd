extends SceneTree
## Joue des séquences scriptées d'un jeu, sans fenêtre, et enregistre ce qui se passe image par image.
## À lancer avec --headless --fixed-fps 60 (chaque image = un pas de physique de 1/60 s).
##
## Arguments, après « -- » :
##   config=<chemin.json>     description du jeu : acteur, commandes, obstacles, séquences (usine/observation/jeux/)
##   sequences=<a,b,…>        séquences à jouer, dans l'ordre, chacune sur une partie neuve
##   monde=<chemin.tscn>      monde de vérité (formes de collision de la référence), posé en fantôme
##   mode=monde sortie=<chemin.tscn>   écrit le monde de vérité du projet ouvert, puis quitte
##
## Sortie : une ligne « @@USINE_OBSERVATION@@ {json} » par séquence, puis « @@USINE_OBSERVATION_FIN@@ ».
## Aucune règle n'est jugée ici : les mesures brutes vont au juge Python (usine/observation/partie.py).

const MARQUEUR := "@@USINE_OBSERVATION@@"
const CALQUE_SOL := 1 << 19          # calque 20 : sol de référence (terrain, route, rampes)
const CALQUE_OBSTACLE := 1 << 20     # calque 21 : obstacles de référence

var args := {}
var config: Dictionary
var file: Array = []                 # séquences restant à jouer
var monde: Node
var partie: Node
var acteur: Node3D
var forme: CollisionShape3D
var capteur_eau: Node
var maillages: Array = []            # [MeshInstance3D, partie du corps, sommets]
var seq: Dictionary
var nom_seq := ""
var image := 0
var cible := Vector3.INF
var demi_tour_fait := false
var enregistrements: Array = []
var pause := 0
var a_lancer := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	config = JSON.parse_string(FileAccess.get_file_as_string(args["config"]))
	if args.get("mode", "") == "monde":
		_nouvelle_partie()
		return
	if args.has("monde"):
		monde = load(args["monde"]).instantiate()
		root.add_child(monde)
	file.assign(str(args.get("sequences", "")).split(",", false))
	_suivante()


func _scene() -> String:
	var s: String = config.get("scene", "")
	return s if s != "" else ProjectSettings.get_setting("application/run/main_scene")


func _nouvelle_partie() -> void:
	partie = load(_scene()).instantiate()
	root.add_child(partie)
	acteur = null
	maillages.clear()


func _suivante() -> void:
	if partie:
		partie.free()
		partie = null
	if file.is_empty():
		print("@@USINE_OBSERVATION_FIN@@")
		quit()
		return
	nom_seq = file.pop_front()
	seq = config["sequences"][nom_seq]
	image = 0
	cible = Vector3.INF
	demi_tour_fait = false
	enregistrements = []
	_relacher_tout()
	_nouvelle_partie()


func _relacher_tout() -> void:
	for nom: String in config["commandes"]:
		Input.action_release(config["commandes"][nom])


func _trouver_acteur() -> bool:
	var a: Dictionary = config["acteur"]
	var trouves := partie.find_children("*", a["classe"], true, false)
	if trouves.is_empty():
		return false
	acteur = trouves[0]
	forme = acteur.find_children("*", "CollisionShape3D", false, false)[0]
	var capteurs := acteur.find_children("*", a.get("capteur_eau", ""), true, false) if a.has("capteur_eau") else []
	capteur_eau = capteurs[0] if not capteurs.is_empty() else null
	for chemin: String in a["visuels"].get("carrosserie", []):
		var mi := acteur.get_node_or_null(chemin) as MeshInstance3D
		if mi and mi.mesh:
			maillages.append([mi, "carrosserie", mi.mesh.get_faces()])
	var roues: Dictionary = a["visuels"].get("roues", {})
	if roues:
		for r in acteur.find_children("*", roues["classe"], true, false):
			var mi := r.get_node_or_null(roues["maillage"]) as MeshInstance3D
			if mi and mi.mesh:
				maillages.append([mi, "roues", mi.mesh.get_faces()])
	return true


# --- Monde de vérité ------------------------------------------------------------------------------

func _ecrire_monde(chemin: String) -> void:
	var m := Node3D.new()
	m.name = "MondeDeVerite"
	var obstacles: Array = config.get("obstacles", [])
	for corps in partie.find_children("*", "StaticBody3D", true, false):
		if acteur.is_ancestor_of(corps):
			continue
		var origine: String = corps.owner.scene_file_path.get_file() if corps.owner else "?"
		for f in corps.find_children("*", "CollisionShape3D", false, false):
			if f.shape == null or f.disabled:
				continue
			var fantome := StaticBody3D.new()
			fantome.collision_layer = CALQUE_OBSTACLE if origine in obstacles else CALQUE_SOL
			fantome.collision_mask = 0
			fantome.set_meta("origine", "%s %s" % [origine, corps.global_position.snapped(Vector3.ONE * 0.1)])
			var copie := CollisionShape3D.new()
			copie.shape = f.shape.duplicate()
			copie.transform = f.global_transform
			fantome.add_child(copie)
			m.add_child(fantome)
	for n in m.get_children():
		n.owner = m
		n.get_child(0).owner = m
	var paquet := PackedScene.new()
	paquet.pack(m)
	var code := ResourceSaver.save(paquet, chemin)
	print(MARQUEUR, JSON.stringify({"monde": chemin, "corps": m.get_child_count(), "code": code}))
	m.free()


# --- Conduite ---------------------------------------------------------------------------------------

func _presser(nom: String, force: float = 1.0) -> void:
	Input.action_press(config["commandes"][nom], force)


func _conduire() -> void:
	_relacher_tout()
	for t: Dictionary in seq.get("tenir", []):
		if image >= int(t["de"]) and image < int(t.get("a", 1 << 30)):
			for nom: String in t["actions"]:
				_presser(nom, float(t.get("force", 1.0)))
	var alt: Dictionary = seq.get("alterner", {})
	if alt and image >= int(alt["de"]):
		var actions: Array = alt["actions"]
		_presser(actions[floori(image / float(alt["periode"])) % actions.size()])
	for e: Dictionary in seq.get("evenements", []):
		# Le jeu peut lire une commande dans _input() : un vrai événement, pressé puis relâché.
		if image == int(e["image"]) or image == int(e["image"]) + 1:
			var ev := InputEventAction.new()
			ev.action = config["commandes"][e["action"]]
			ev.pressed = image == int(e["image"])
			Input.parse_input_event(ev)
	var pilote: Dictionary = seq.get("pilote", {})
	if pilote and image >= int(pilote["de"]):
		_piloter(pilote)


func _piloter(pilote: Dictionary) -> void:
	if cible == Vector3.INF:
		var proches := partie.find_children("*", "StaticBody3D", true, false).filter(
			func(c: Node) -> bool: return c.owner and c.owner.scene_file_path.get_file() == pilote["vers"])
		if proches.is_empty():
			return
		proches.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_to(acteur.global_position) < b.global_position.distance_to(acteur.global_position))
		cible = proches[0].global_position
	var vers := (cible - acteur.global_position) * Vector3(1, 0, 1)
	var avant := -acteur.global_basis.z * Vector3(1, 0, 1)
	var angle := avant.signed_angle_to(vers, Vector3.UP)
	# Demi-tour sur place d'abord (frein et braquage à l'arrêt), puis on roule vers la cible.
	if pilote.get("demi_tour", false) and not demi_tour_fait and absf(angle) > 0.25:
		_presser("frein")
		_presser("gauche" if angle > 0.0 else "droite")
		return
	demi_tour_fait = true
	_presser("avancer")
	if absf(angle) > 0.05:
		_presser("gauche" if angle > 0.0 else "droite", clampf(absf(angle) * 2.0, 0.2, 1.0))


# --- Mesures ------------------------------------------------------------------------------------------

## Hauteur du sol de référence à la verticale de `p`, depuis 4 m au-dessus (NAN s'il n'y en a pas).
func _sol(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 4.0, p + Vector3.DOWN * 30.0, CALQUE_SOL)
	var r := acteur.get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"].y if r else NAN


func _arrondi(v: float) -> Variant:
	if is_nan(v):
		return null
	return snappedf(v, 0.001)


func _mesurer() -> Dictionary:
	var p := acteur.global_position
	var espace := acteur.get_world_3d().direct_space_state
	var dans_l_eau: bool = capteur_eau != null and capteur_eau.is_in_water()
	var sur_sol: bool = acteur is CharacterBody3D and (acteur as CharacterBody3D).is_on_floor()
	var vitesse: Vector3 = acteur.velocity if "velocity" in acteur else Vector3.ZERO
	var e := {"i": image, "p": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)],
		"vy": snappedf(vitesse.y, 0.0001), "v": snappedf(vitesse.length(), 0.01),
		"vh": snappedf((vitesse * Vector3(1, 0, 1)).length(), 0.01),
		"appui": "sol" if sur_sol else ("eau" if dans_l_eau else "air")}
	var sol := _sol(p)
	e["sol"] = _arrondi(sol)
	e["haut"] = snappedf(p.y - (maxf(0.0, sol) if not is_nan(sol) else 0.0), 0.001)
	var dessus := espace.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 60.0, p + Vector3.DOWN * 60.0, CALQUE_SOL))
	e["sous"] = null
	e["sous_obj"] = null
	if dessus:
		e["sous"] = snappedf(dessus["position"].y - p.y, 0.001)
		e["sous_obj"] = dessus["collider"].get_meta("origine", "?")
	# Pénétration de la forme de l'acteur dans les obstacles de référence.
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = forme.shape
	q.transform = forme.global_transform
	q.collision_mask = CALQUE_OBSTACLE
	var points := espace.collide_shape(q, 16)
	var profondeur := 0.0
	for k in range(0, points.size(), 2):
		profondeur = maxf(profondeur, points[k].distance_to(points[k + 1]))
	e["pen"] = snappedf(profondeur, 0.001)
	e["pen_obj"] = null
	if profondeur > 0.0:
		e["pen_obj"] = ", ".join(espace.intersect_shape(q, 4).map(func(h: Dictionary) -> String: return h["collider"].get_meta("origine", "?")))
	# Enfouissement : de combien le bas visible de chaque partie du corps passe sous le sol de référence.
	for partie_du_corps: String in ["carrosserie", "roues"]:
		e["enf_" + partie_du_corps] = null
	for m: Array in maillages:
		var mi: MeshInstance3D = m[0]
		var bas := Vector3(0, INF, 0)
		for v: Vector3 in m[2]:
			var g: Vector3 = mi.global_transform * v
			if g.y < bas.y:
				bas = g
		var s := _sol(bas)
		if not is_nan(s) and s > 0.05:
			var cle: String = "enf_" + m[1]
			if e[cle] == null or s - bas.y > e[cle]:
				e[cle] = snappedf(s - bas.y, 0.001)
				e[cle + "_obj"] = mi.name
	# Caméra : l'acteur dans le champ, la caméra au-dessus du sol, son regard dans le sens de la marche.
	var cam := root.get_viewport().get_camera_3d()
	if cam:
		e["cam_champ"] = cam.is_position_in_frustum(p)
		var sc := _sol(cam.global_position)
		e["cam_sous"] = _arrondi(sc - cam.global_position.y) if not is_nan(sc) else null
		var marche := vitesse * Vector3(1, 0, 1)
		e["cam_al"] = null
		if marche.length() > 0.001:
			e["cam_al"] = snappedf((-cam.global_basis.z * Vector3(1, 0, 1)).normalized().dot(marche.normalized()), 0.01)
	return e


## La partie suivante s'ajoute à la fin d'une image, comme une partie seule (ajoutée avant la première
## image) : son premier pas de physique vient avant son premier affichage, et la trace d'une séquence
## est la même jouée seule ou à la suite d'autres.
func _process(_delta: float) -> bool:
	if a_lancer:
		a_lancer = false
		_suivante.call_deferred()
	return false


func _physics_process(_delta: float) -> bool:
	if pause > 0:
		pause -= 1
		if pause == 0:
			a_lancer = true
		return false
	if partie == null:
		return false
	image += 1
	if acteur == null:
		if not _trouver_acteur():
			print(MARQUEUR, JSON.stringify({"sequence": nom_seq, "erreur": "acteur %s introuvable" % config["acteur"]["classe"]}))
			pause = 2
			return false
		if args.get("mode", "") == "monde":
			_ecrire_monde(args["sortie"])
			print("@@USINE_OBSERVATION_FIN@@")
			quit()
			return false
	_conduire()
	# Échauffement : la suspension se pose ; la trace d'une partie neuve commence ensuite, seule ou dans un lot.
	if image > int(config.get("echauffement", 10)):
		enregistrements.append(_mesurer())
	if image >= int(seq["images"]):
		_relacher_tout()
		print(MARQUEUR, JSON.stringify({"sequence": nom_seq, "images": image, "enregistrements": enregistrements}))
		partie.queue_free()
		partie = null
		pause = 2
	return false
