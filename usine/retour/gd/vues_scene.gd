extends Node
## Voir la scène 3D comme dans l'éditeur (outil voir_scene de l'usine), posé en autoload dans une copie du projet.
## À l'image N : la vue du jeu (ce que voit le joueur, HUD compris), puis des vues d'observation cadrées sur la scène
## (dessus, côté, face, 3/4) où l'on a dessiné les repères : le champ de la caméra du jeu (jaune), la boîte de chaque
## objet (verte s'il est dans le champ, rouge sinon), les axes X Y Z (rouge, vert, bleu), la grille du sol, les noms.
## Écrit une planche PNG titrée et un JSON de mesures (caméras, objets, champ), puis quitte.
## Arguments après « -- » : --vues-sortie=<base> --vues-image=N --vues-liste=jeu,dessus,cote,face,perspective
## --vues-cadrer=<chemin de nœud> --vues-taille=640x360

const COULEUR_CHAMP := Color(1.0, 0.85, 0.1)
const COULEUR_DEDANS := Color(0.2, 0.95, 0.3)
const COULEUR_DEHORS := Color(1.0, 0.25, 0.2)
const COULEUR_GRILLE := Color(0.55, 0.55, 0.6, 0.6)
const COULEUR_LUMIERE := Color(1.0, 0.6, 1.0)
const NOMS_PLANS := ["proche (near)", "lointain (far)", "gauche", "haut", "droite", "bas"]
const TITRES := {
	"jeu": "JEU : ce que voit le joueur (caméra du jeu, HUD compris)",
	"dessus": "DESSUS : vu de +Y, haut de l'image = -Z",
	"cote": "CÔTÉ : vu de +X, gauche de l'image = +Z",
	"face": "FACE : vu de +Z, droite de l'image = +X",
	"perspective": "3/4 : vu de (+X, +Y, +Z)",
}
const MAX_BOITES := 300
const MAX_NOMS := 12

var _sortie := ""
var _image := 60
var _vues: PackedStringArray = ["jeu", "dessus", "cote", "face", "perspective"]
var _cadrer := ""
var _taille := Vector2i(640, 360)
var _images := 0
var _materiau_lignes: StandardMaterial3D
## Taille d'un pixel des noms, en mètres : proportionnelle à la scène, pour que les noms gardent la même taille à
## l'image dans toutes les vues (elles sont toutes cadrées sur la scène).
var _pixel_noms := 0.01


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for argument in OS.get_cmdline_user_args():
		var cle := argument.get_slice("=", 0)
		var valeur := argument.substr(cle.length() + 1)
		match cle:
			"--vues-sortie":
				_sortie = valeur
			"--vues-image":
				_image = maxi(1, valeur.to_int())
			"--vues-liste":
				_vues = valeur.split(",", false)
			"--vues-cadrer":
				_cadrer = valeur
			"--vues-taille":
				_taille = Vector2i(maxi(64, valeur.get_slice("x", 0).to_int()), maxi(64, valeur.get_slice("x", 1).to_int()))
	set_process(not _sortie.is_empty())


func _process(_delta: float) -> void:
	_images += 1
	if _images == _image:
		set_process(false)
		_voir()


func _voir() -> void:
	var camera := get_viewport().get_camera_3d()
	await RenderingServer.frame_post_draw
	var vue_jeu := get_viewport().get_texture().get_image()
	var objets := _objets(camera)
	var donnees := {
		"image": _image, "scene": _scene_courante(), "camera": _decrire_camera(camera),
		"cameras": _cameras(), "lumieres": _lumieres(), "objets": objets, "caches": _caches(),
	}
	var bornes := _bornes(objets, camera)
	donnees["bornes"] = {"centre": _v(bornes.get_center()), "taille": _v(bornes.size)}
	var reperes := Node3D.new()
	reperes.name = "UsineReperes"
	get_tree().root.add_child(reperes)
	_dessiner_reperes(reperes, camera, objets, bornes)
	var tuiles: Array[Image] = []
	var titres: PackedStringArray = []
	for vue in _vues:
		if vue == "jeu":
			var copie := vue_jeu.duplicate() as Image
			copie.resize(_taille.x, _taille.y, Image.INTERPOLATE_BILINEAR)
			tuiles.append(copie)
		elif TITRES.has(vue):
			tuiles.append(await _rendre_observation(vue, bornes))
		else:
			continue
		titres.append(TITRES[vue])
	var planche := await _composer(tuiles, titres)
	planche.save_png(_sortie + ".png")
	var fichier := FileAccess.open(_sortie + ".json", FileAccess.WRITE)
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	print("USINE_VUES ", _sortie)
	# Libérer repères et sous-vues, et laisser le moteur les rendre, avant de quitter : sinon il signale à la sortie
	# des ressources de rendu jamais libérées.
	reperes.queue_free()
	for _i in 4:
		await get_tree().process_frame
	get_tree().quit()


func _scene_courante() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _v(v: Vector3) -> Array[float]:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


func _decrire_camera(camera: Camera3D) -> Dictionary:
	if camera == null:
		return {}
	return {
		"chemin": str(camera.get_path()), "position": _v(camera.global_position),
		"regarde_vers": _v(-camera.global_basis.z), "haut": _v(camera.global_basis.y),
		"projection": "orthographique" if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else "perspective",
		"fov": camera.fov, "size": camera.size, "near": camera.near, "far": camera.far,
		"cull_mask": camera.cull_mask,
	}


func _cameras() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	for n in get_tree().root.find_children("*", "Camera3D", true, false):
		var c := n as Camera3D
		liste.append({"chemin": str(c.get_path()), "courante": c.is_current(), "position": _v(c.global_position),
				"regarde_vers": _v(-c.global_basis.z)})
	return liste


func _lumieres() -> Array[Dictionary]:
	var liste: Array[Dictionary] = []
	for n in get_tree().root.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		liste.append({"chemin": str(l.get_path()), "type": l.get_class(), "visible": l.is_visible_in_tree(),
				"position": _v(l.global_position), "vers": _v(-l.global_basis.z), "energie": l.light_energy,
				"ombres": l.shadow_enabled})
	return liste


## Les objets 3D dessinés : boîte dans le monde, et place par rapport au champ de la caméra du jeu.
func _objets(camera: Camera3D) -> Array[Dictionary]:
	var plans: Array[Plane] = camera.get_frustum() if camera != null else []
	var liste: Array[Dictionary] = []
	for n in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var boite := g.global_transform * g.get_aabb()
		var objet := {"chemin": str(g.get_path()), "nom": str(g.name), "type": g.get_class(),
				"centre": _v(boite.get_center()), "taille": _v(boite.size)}
		if camera != null:
			var dehors: PackedStringArray = []
			for i in plans.size():
				if _entierement_au_dessus(plans[i], boite):
					dehors.append(NOMS_PLANS[i])
			if (g.layers & camera.cull_mask) == 0:
				dehors.append("couche exclue par cull_mask")
			objet["dans_le_champ"] = dehors.is_empty()
			objet["hors_champ"] = dehors
			if not camera.is_position_behind(boite.get_center()):
				var ecran := camera.unproject_position(boite.get_center())
				objet["ecran"] = [roundi(ecran.x), roundi(ecran.y)]
			objet["distance"] = snappedf(camera.global_position.distance_to(boite.get_center()), 0.01)
		liste.append(objet)
	return liste


func _entierement_au_dessus(plan: Plane, boite: AABB) -> bool:
	for i in 8:
		if not plan.is_point_over(boite.get_endpoint(i)):
			return false
	return true


func _caches() -> PackedStringArray:
	var liste: PackedStringArray = []
	for n in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() and liste.size() < 40:
			liste.append(str(g.get_path()))
	return liste


## La région à montrer : le nœud demandé, sinon tous les objets et la caméra du jeu.
func _bornes(objets: Array[Dictionary], camera: Camera3D) -> AABB:
	var bornes := AABB()
	var premier := true
	for o: Dictionary in objets:
		if not _cadrer.is_empty() and not String(o["chemin"]).contains(_cadrer):
			continue
		var c: Array = o["centre"]
		var t: Array = o["taille"]
		var b := AABB(Vector3(c[0], c[1], c[2]) - Vector3(t[0], t[1], t[2]) * 0.5, Vector3(t[0], t[1], t[2]))
		bornes = b if premier else bornes.merge(b)
		premier = false
	if camera != null and _cadrer.is_empty():
		var point := AABB(camera.global_position, Vector3.ZERO)
		bornes = point if premier else bornes.merge(point)
		premier = false
	if premier:
		bornes = AABB(Vector3(-5.0, -5.0, -5.0), Vector3(10.0, 10.0, 10.0))
	return bornes.grow(maxf(bornes.size.length() * 0.05, 0.5))


func _dessiner_reperes(reperes: Node3D, camera: Camera3D, objets: Array[Dictionary], bornes: AABB) -> void:
	_materiau_lignes = StandardMaterial3D.new()
	_materiau_lignes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materiau_lignes.vertex_color_use_as_albedo = true
	_materiau_lignes.no_depth_test = true
	_materiau_lignes.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materiau_lignes.render_priority = 10
	var lignes := ImmediateMesh.new()
	lignes.surface_begin(Mesh.PRIMITIVE_LINES, _materiau_lignes)
	var echelle := maxf(bornes.size.length(), 1.0)
	_pixel_noms = echelle * 0.0009
	_grille(lignes, bornes)
	for i in 3:
		var axe := Vector3.ZERO
		axe[i] = echelle * 0.15
		var couleur := [Color.RED, Color.GREEN, Color(0.3, 0.5, 1.0)][i] as Color
		_ligne(lignes, Vector3.ZERO, axe, couleur)
		_nom(reperes, ["X", "Y", "Z"][i], axe * 1.05, couleur)
	var noms := 0
	var tries := objets.duplicate()
	tries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _volume(a) > _volume(b))
	for k in mini(tries.size(), MAX_BOITES):
		var o: Dictionary = tries[k]
		var c: Array = o["centre"]
		var t: Array = o["taille"]
		var b := AABB(Vector3(c[0], c[1], c[2]) - Vector3(t[0], t[1], t[2]) * 0.5, Vector3(t[0], t[1], t[2]))
		var dedans: bool = o.get("dans_le_champ", true)
		_boite(lignes, b, COULEUR_DEDANS if dedans else COULEUR_DEHORS)
		if noms < MAX_NOMS:
			_nom(reperes, String(o["nom"]), b.get_center() + Vector3(0.0, b.size.y * 0.5, 0.0),
					COULEUR_DEDANS if dedans else COULEUR_DEHORS)
			noms += 1
	for n in get_tree().root.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		# Une lumière directionnelle n'a pas de place, seulement une direction : sa flèche part d'un coin haut de la
		# scène, pour ne rien cacher.
		var depart := l.global_position
		if l is DirectionalLight3D:
			depart = Vector3(bornes.position.x, bornes.end.y, bornes.position.z)
		_ligne(lignes, depart, depart - l.global_basis.z * echelle * 0.15, COULEUR_LUMIERE)
		_nom(reperes, "lumière " + str(l.name), depart, COULEUR_LUMIERE)
	if camera != null:
		_champ(lignes, camera, bornes)
		_ligne(lignes, camera.global_position, camera.global_position - camera.global_basis.z * echelle * 0.2,
				COULEUR_CHAMP)
		_nom(reperes, "CAMÉRA " + str(camera.name), camera.global_position, COULEUR_CHAMP)
	lignes.surface_end()
	var instance := MeshInstance3D.new()
	instance.mesh = lignes
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.extra_cull_margin = 16384.0
	reperes.add_child(instance)


func _volume(o: Dictionary) -> float:
	var t: Array = o["taille"]
	return maxf(float(t[0]), 0.01) * maxf(float(t[1]), 0.01) * maxf(float(t[2]), 0.01)


func _ligne(lignes: ImmediateMesh, a: Vector3, b: Vector3, couleur: Color) -> void:
	lignes.surface_set_color(couleur)
	lignes.surface_add_vertex(a)
	lignes.surface_set_color(couleur)
	lignes.surface_add_vertex(b)


func _boite(lignes: ImmediateMesh, b: AABB, couleur: Color) -> void:
	for arete: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 5),
			Vector2i(2, 3), Vector2i(2, 6), Vector2i(3, 7), Vector2i(4, 5), Vector2i(4, 6), Vector2i(5, 7),
			Vector2i(6, 7)]:
		_ligne(lignes, b.get_endpoint(arete.x), b.get_endpoint(arete.y), couleur)


## La grille du sol, à y = 0, sur l'emprise de la scène, d'un pas rond (1, 2, 5, 10 m…).
func _grille(lignes: ImmediateMesh, bornes: AABB) -> void:
	var etendue := maxf(bornes.size.x, bornes.size.z)
	var pas := 1.0
	for p: float in [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]:
		pas = p
		if etendue / p <= 40.0:
			break
	var x0 := floorf(bornes.position.x / pas) * pas
	var z0 := floorf(bornes.position.z / pas) * pas
	var x1 := ceilf(bornes.end.x / pas) * pas
	var z1 := ceilf(bornes.end.z / pas) * pas
	var x := x0
	while x <= x1:
		_ligne(lignes, Vector3(x, 0.0, z0), Vector3(x, 0.0, z1), COULEUR_GRILLE)
		x += pas
	var z := z0
	while z <= z1:
		_ligne(lignes, Vector3(x0, 0.0, z), Vector3(x1, 0.0, z), COULEUR_GRILLE)
		z += pas


## Le champ de la caméra du jeu : ses quatre arêtes, du plan proche jusqu'à la profondeur utile (la scène), et les deux
## rectangles qui le ferment.
func _champ(lignes: ImmediateMesh, camera: Camera3D, bornes: AABB) -> void:
	var taille := get_viewport().get_visible_rect().size
	var loin := camera.near
	for i in 8:
		loin = maxf(loin, camera.global_position.distance_to(bornes.get_endpoint(i)))
	loin = minf(loin * 1.1, camera.far)
	var coins := [Vector2.ZERO, Vector2(taille.x, 0.0), taille, Vector2(0.0, taille.y)]
	var pres: Array[Vector3] = []
	var fond: Array[Vector3] = []
	for coin: Vector2 in coins:
		pres.append(camera.project_position(coin, camera.near))
		fond.append(camera.project_position(coin, loin))
	for i in 4:
		_ligne(lignes, pres[i], fond[i], COULEUR_CHAMP)
		_ligne(lignes, pres[i], pres[(i + 1) % 4], COULEUR_CHAMP)
		_ligne(lignes, fond[i], fond[(i + 1) % 4], COULEUR_CHAMP)


func _nom(reperes: Node3D, texte: String, ou: Vector3, couleur: Color) -> void:
	var etiquette := Label3D.new()
	etiquette.text = texte
	etiquette.position = ou
	etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiquette.pixel_size = _pixel_noms
	etiquette.font_size = 32
	etiquette.outline_size = 10
	etiquette.modulate = couleur
	etiquette.no_depth_test = true
	etiquette.render_priority = 20
	reperes.add_child(etiquette)


## Une vue d'observation, rendue dans une sous-vue qui partage le monde 3D du jeu.
func _rendre_observation(vue: String, bornes: AABB) -> Image:
	var sous_vue := SubViewport.new()
	sous_vue.size = _taille
	sous_vue.world_3d = get_viewport().world_3d
	sous_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sous_vue)
	var oeil := Camera3D.new()
	var ambiance := Environment.new()
	ambiance.background_mode = Environment.BG_COLOR
	ambiance.background_color = Color(0.16, 0.17, 0.2)
	ambiance.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiance.ambient_light_color = Color.WHITE
	ambiance.ambient_light_energy = 0.7
	oeil.environment = ambiance  # lisible même si la scène est sombre, comme l'éditeur
	sous_vue.add_child(oeil)
	var centre := bornes.get_center()
	var s := bornes.size
	var rapport := float(_taille.x) / float(_taille.y)
	var recul := s.length() + 10.0
	oeil.near = 0.05
	oeil.far = recul * 4.0 + 100.0
	match vue:
		"dessus":
			oeil.projection = Camera3D.PROJECTION_ORTHOGONAL
			oeil.size = maxf(s.z, s.x / rapport) * 1.1
			oeil.look_at_from_position(centre + Vector3.UP * recul, centre, Vector3.FORWARD)
		"cote":
			oeil.projection = Camera3D.PROJECTION_ORTHOGONAL
			oeil.size = maxf(s.y, s.z / rapport) * 1.1
			oeil.look_at_from_position(centre + Vector3.RIGHT * recul, centre, Vector3.UP)
		"face":
			oeil.projection = Camera3D.PROJECTION_ORTHOGONAL
			oeil.size = maxf(s.y, s.x / rapport) * 1.1
			oeil.look_at_from_position(centre + Vector3.BACK * recul, centre, Vector3.UP)
		_:
			oeil.fov = 50.0
			var rayon := s.length() * 0.5
			oeil.look_at_from_position(centre + Vector3(1.0, 0.9, 1.0).normalized() * rayon / sin(deg_to_rad(25.0)) * 1.05,
					centre, Vector3.UP)
	oeil.current = true
	for _i in 3:
		await RenderingServer.frame_post_draw
	var image := sous_vue.get_texture().get_image()
	sous_vue.queue_free()
	return image


## La planche : les vues en grille, chacune sous son titre, assemblées et écrites par Godot.
func _composer(tuiles: Array[Image], titres: PackedStringArray) -> Image:
	var colonnes := mini(3, maxi(1, tuiles.size()))
	var lignes := ceili(float(tuiles.size()) / colonnes)
	var bandeau := 26
	var feuille := SubViewport.new()
	feuille.size = Vector2i(_taille.x * colonnes, (_taille.y + bandeau) * lignes)
	feuille.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	feuille.transparent_bg = false
	add_child(feuille)
	var fond := ColorRect.new()
	fond.color = Color(0.08, 0.08, 0.09)
	fond.size = Vector2(feuille.size)
	feuille.add_child(fond)
	for i in tuiles.size():
		var origine := Vector2((i % colonnes) * _taille.x, floori(float(i) / colonnes) * (_taille.y + bandeau))
		var titre := Label.new()
		titre.text = titres[i]
		titre.position = origine + Vector2(6.0, 2.0)
		titre.add_theme_font_size_override(&"font_size", 15)
		feuille.add_child(titre)
		var image := TextureRect.new()
		image.texture = ImageTexture.create_from_image(tuiles[i])
		image.position = origine + Vector2(0.0, bandeau)
		image.size = Vector2(_taille)
		feuille.add_child(image)
	for _i in 3:
		await RenderingServer.frame_post_draw
	var planche := feuille.get_texture().get_image()
	feuille.queue_free()
	return planche
