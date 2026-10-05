extends SceneTree
## Mesure d'efficience d'un projet (compétence E). Lancé par usine/efficience/mesure.py :
##   godot --headless --fixed-fps 60 --path <projet> -s <ce script> -- <mode> <scène> <échauffement> <fin> <images de rendu>
##
## Mode « deterministe » :
##   - allocations : compteur d'allocations de l'ObjectDB (bits hauts de l'id d'un objet témoin,
##     créé puis libéré) lu à la fin de l'échauffement puis à la fin de la fenêtre. Ce compteur
##     voit chaque création d'objet, même libéré aussitôt ; OBJECT_COUNT ne voit pas ce churn.
##   - lots de dessin : comptage structurel (les draw calls valent 0 en headless) à chaque image
##     de la fenêtre, médiane. Un lot = une suite d'éléments consécutifs dans l'ordre de dessin
##     qui partagent texture et matériau ; un MultiMeshInstance2D compte pour un lot.
##   - signature de rendu aux images demandées (après la fenêtre, pour ne rien allouer dedans).
## Mode « temps » : durée de chaque image de la fenêtre (Time.get_ticks_usec), médiane.
##
## Aucune allocation d'objet pendant la fenêtre : seulement des tableaux et des RID.
## Résultat : une ligne « @@USINE_EFFICIENCE@@<json> ».

const MARQUEUR := "@@USINE_EFFICIENCE@@"
const MASQUE_COMPTEUR := (1 << 39) - 1

var mode := "deterministe"
var echauffement := 60
var fin := 180
var images_rendu: Array[int] = []
var image := 0
var compteur_debut := 0
var allocations := -1
var lots := PackedInt32Array()
var durees := PackedInt64Array()
var tic := 0
var signatures: Array = []
var hachages_textures := {}
var scene_racine: Node = null
var _cles: Array = []
## Taille de l'écran du jeu : celle du projet (en headless, la fenêtre racine fait 64×64).
var ecran := Rect2()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[0]
	var chemin := args[1]
	echauffement = int(args[2])
	fin = int(args[3])
	if args.size() > 4 and args[4] != "":
		for morceau in args[4].split(","):
			images_rendu.append(int(morceau))
	ecran = Rect2(0, 0, int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	var paquet: PackedScene = load(chemin)
	scene_racine = paquet.instantiate()
	root.add_child(scene_racine)


func _compteur() -> int:
	var temoin := Object.new()
	var c := (temoin.get_instance_id() >> 24) & MASQUE_COMPTEUR
	temoin.free()
	return c


func _process(_delta: float) -> bool:
	image += 1
	if mode == "temps":
		var maintenant := Time.get_ticks_usec()
		if image > echauffement and image <= fin:
			durees.append(maintenant - tic)
		tic = maintenant
		if image >= fin:
			_terminer()
		return false
	if image == echauffement:
		compteur_debut = _compteur()
	elif image > echauffement and image <= fin:
		lots.append(_compter_lots())
		if image == fin:
			# Le témoin de début compte pour une allocation.
			allocations = _compteur() - compteur_debut - 1
	if image in images_rendu:
		signatures.append({"image": image, "elements": _signature()})
	var derniere: int = fin
	for i in images_rendu:
		derniere = maxi(derniere, i)
	if image >= derniere:
		_terminer()
	return false


func _terminer() -> void:
	var resultat := {"mode": mode, "images": image}
	if mode == "temps":
		var tri := Array(durees)
		tri.sort()
		resultat["temps_image_us"] = tri[tri.size() / 2] if tri.size() > 0 else 0
	else:
		var tri := Array(lots)
		tri.sort()
		resultat["allocations"] = allocations
		resultat["lots"] = tri[tri.size() / 2] if tri.size() > 0 else 0
		resultat["lots_min"] = tri[0] if tri.size() > 0 else 0
		resultat["lots_max"] = tri[tri.size() - 1] if tri.size() > 0 else 0
		resultat["rendu"] = signatures
	print(MARQUEUR + JSON.stringify(resultat))
	quit()


# ---------------------------------------------------------------- lots de dessin

func _visible_a_l_ecran(item: CanvasItem, rect_local: Rect2) -> bool:
	var r := item.get_global_transform_with_canvas() * rect_local
	return ecran.intersects(r, true)


func _rect_local(item: CanvasItem) -> Rect2:
	if item is Sprite2D:
		return (item as Sprite2D).get_rect()
	if item is Control:
		return Rect2(Vector2.ZERO, (item as Control).size)
	return Rect2(-1e6, -1e6, 2e6, 2e6)


func _materiau(item: CanvasItem) -> int:
	return item.material.get_instance_id() if item.material != null else 0


func _texture_rid(item: CanvasItem) -> RID:
	if item is Sprite2D and (item as Sprite2D).texture != null:
		return (item as Sprite2D).texture.get_rid()
	if item is TextureRect and (item as TextureRect).texture != null:
		return (item as TextureRect).texture.get_rid()
	if item is MultiMeshInstance2D and (item as MultiMeshInstance2D).texture != null:
		return (item as MultiMeshInstance2D).texture.get_rid()
	return RID()


func _dessine(item: CanvasItem) -> bool:
	if item is Sprite2D:
		return (item as Sprite2D).texture != null
	if item is MultiMeshInstance2D:
		var mm := (item as MultiMeshInstance2D).multimesh
		return mm != null and mm.mesh != null and (mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count) > 0
	if item is Light2D or item is LightOccluder2D:
		return false
	if item is Control or item is Polygon2D or item is Line2D or item is MeshInstance2D or item is AnimatedSprite2D:
		return true
	return item.has_method("_draw")


func _z(item: CanvasItem) -> int:
	var z := 0
	var n: Node = item
	while n is CanvasItem:
		var c := n as CanvasItem
		z += c.z_index
		if not c.z_as_relative:
			break
		n = n.get_parent()
	return z


func _calque(n: Node) -> int:
	var p := n
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


func _collecter(n: Node, ordre: Array) -> void:
	if n is CanvasItem:
		var item := n as CanvasItem
		if not item.is_visible_in_tree():
			return
		if _dessine(item) and (item is MultiMeshInstance2D or _visible_a_l_ecran(item, _rect_local(item))):
			ordre.append(item)
	for enfant in n.get_children():
		_collecter(enfant, ordre)


func _compter_lots() -> int:
	var ordre: Array = []
	_collecter(scene_racine, ordre)
	# Ordre de dessin : calque, puis z, puis ordre de l'arbre (tri stable par indice).
	_cles.clear()
	for k in ordre.size():
		var item: CanvasItem = ordre[k]
		_cles.append([_calque(item), _z(item), k])
	_cles.sort()
	var total := 0
	var precedent_tex := RID()
	var precedent_mat := -1
	var precedent_genre := ""
	for cle in _cles:
		var item: CanvasItem = ordre[cle[2]]
		var genre := item.get_class()
		if item is MultiMeshInstance2D or not item is Sprite2D and not item is TextureRect:
			total += 1
			precedent_genre = ""
			continue
		var tex := _texture_rid(item)
		var mat := _materiau(item)
		if genre != precedent_genre or tex != precedent_tex or mat != precedent_mat:
			total += 1
		precedent_tex = tex
		precedent_mat = mat
		precedent_genre = genre
	return total


# ---------------------------------------------------------------- signature de rendu

func _f(x: float) -> String:
	return "%.2f" % snappedf(x, 0.01)


func _v(p: Vector2) -> String:
	return _f(p.x) + "," + _f(p.y)


func _couleur(c: Color) -> String:
	return "%.3f,%.3f,%.3f,%.3f" % [c.r, c.g, c.b, c.a]


func _hachage_texture(t: Texture2D, region := Rect2()) -> String:
	## Contenu en pixels de la texture (ou de sa région) : un atlas et des textures séparées
	## qui portent les mêmes pixels donnent le même hachage.
	if t == null:
		return "-"
	var cle := [t.get_rid(), region]
	if hachages_textures.has(cle):
		return hachages_textures[cle]
	var img := t.get_image()
	var h := "?"
	if img != null:
		if region.has_area():
			img = img.get_region(Rect2i(region))
		h = "%dx%d:%s" % [img.get_width(), img.get_height(), img.get_data().hex_encode().sha256_text().substr(0, 16)]
	hachages_textures[cle] = h
	return h


func _modulation(item: CanvasItem) -> Color:
	var c := item.self_modulate
	var n: Node = item
	while n is CanvasItem:
		c *= (n as CanvasItem).modulate
		n = n.get_parent()
	return c


func _filtre(item: CanvasItem) -> int:
	var n: Node = item
	while n is CanvasItem:
		var f := (n as CanvasItem).texture_filter
		if f != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return f
		n = n.get_parent()
	return -1


func _materiau_signature(item: CanvasItem) -> String:
	var m := item.material
	if m == null:
		return "-"
	if m is ShaderMaterial:
		var sm := m as ShaderMaterial
		var params := []
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				params.append(str(u["name"]) + "=" + var_to_str(sm.get_shader_parameter(u["name"])))
		return "shader:" + (sm.shader.code.sha256_text().substr(0, 16) if sm.shader else "-") + ":" + ";".join(params)
	if m is CanvasItemMaterial:
		var cm := m as CanvasItemMaterial
		return "cim:%d:%d" % [cm.blend_mode, cm.light_mode]
	return m.get_class()


## Un quadrilatère texturé : pixels de la région source, puis les 4 sommets à l'écran associés
## aux coins de la région (UV relatifs à la région), triés. Un sprite tiré d'un atlas et un
## sprite à texture propre qui affichent les mêmes pixels au même endroit donnent la même entrée.
func _quad(tex: Texture2D, src: Rect2, uv_px: Array, sommets: Array, mod: Color, item: CanvasItem) -> String:
	var paires: Array = []
	for k in 4:
		var uv: Vector2 = ((uv_px[k] as Vector2) - src.position) / src.size
		paires.append("%.4f,%.4f>%s" % [uv.x, uv.y, _v(sommets[k])])
	paires.sort()
	return "quad|%s|%s|%s|f%d|%s" % [_hachage_texture(tex, src), " ".join(paires), _couleur(mod), _filtre(item),
		_materiau_signature(item)]


func _signature_sprite(s: Sprite2D, sortie: Array) -> void:
	var tex := s.texture
	var src := Rect2(Vector2.ZERO, tex.get_size())
	if s.region_enabled:
		src = s.region_rect
	var cell := Vector2(src.size.x / s.hframes, src.size.y / s.vframes)
	var src_cell := Rect2(src.position + Vector2(s.frame_coords) * cell, cell)
	var r := s.get_rect()
	var x := s.get_global_transform_with_canvas()
	var uv := [src_cell.position, src_cell.position + Vector2(cell.x, 0), src_cell.end, src_cell.position + Vector2(0, cell.y)]
	var p := [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]
	if s.flip_h:
		p = [p[1], p[0], p[3], p[2]]
	if s.flip_v:
		p = [p[3], p[2], p[1], p[0]]
	var coins := []
	for q in p:
		coins.append(x * q)
	sortie.append(_quad(tex, src_cell, uv, coins, _modulation(s), s))


## Les données d'instances d'un MultiMesh ne sont pas lisibles en headless (le serveur de rendu
## factice ne les garde pas : get_instance_transform_2d rend l'identité, buffer est vide).
## On ne peut donc pas prouver qu'un MultiMesh dessine la même chose que des sprites : il entre
## dans la signature sous une forme opaque, et un candidat qui remplace des sprites par un
## MultiMesh ne passe pas la comparaison de rendu. Limite connue, documentée dans ETAT.md.
func _signature_multimesh(m: MultiMeshInstance2D, sortie: Array) -> void:
	var mm := m.multimesh
	var n := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
	sortie.append("multimesh|%s|%s|%d|%s" % [mm.mesh.get_class(), _hachage_texture(m.texture), n,
		_v(m.get_global_transform_with_canvas().origin)])


func _signature_element(item: CanvasItem, sortie: Array) -> void:
	if item is Sprite2D:
		if (item as Sprite2D).texture != null and _visible_a_l_ecran(item, _rect_local(item)):
			_signature_sprite(item, sortie)
		return
	if item is MultiMeshInstance2D:
		var mm := (item as MultiMeshInstance2D).multimesh
		if mm != null and mm.mesh != null:
			_signature_multimesh(item, sortie)
		return
	var x := item.get_global_transform_with_canvas()
	var base := "%s|%s|%s|%s" % [item.get_class(), _v(x.origin), _v(x.x), _v(x.y)]
	if item is Light2D:
		var l := item as Light2D
		var tex_l := ""
		if l is PointLight2D:
			tex_l = _hachage_texture((l as PointLight2D).texture) + ":" + _f((l as PointLight2D).texture_scale)
		sortie.append("lumiere|%s|%s|%s|%s|%s|%d|%s" % [base, l.enabled, _f(l.energy), _couleur(l.color),
			l.shadow_enabled, l.blend_mode, tex_l])
		return
	if not _dessine(item):
		return
	var details := ""
	if item is ColorRect:
		details = _couleur((item as ColorRect).color) + "|" + _v((item as ColorRect).size)
	elif item is Label:
		details = (item as Label).text + "|" + _v((item as Label).size)
	elif item is Polygon2D:
		details = _couleur((item as Polygon2D).color) + "|" + var_to_str((item as Polygon2D).polygon)
	elif item is Line2D:
		details = _couleur((item as Line2D).default_color) + "|" + _f((item as Line2D).width) + "|" + var_to_str((item as Line2D).points)
	elif item is TextureRect:
		details = _hachage_texture((item as TextureRect).texture) + "|" + _v((item as TextureRect).size)
	sortie.append("%s|%s|%s|%s" % [base, details, _couleur(_modulation(item)), _materiau_signature(item)])


func _parcourir_signature(n: Node, sortie: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is CanvasItem:
		_signature_element(n, sortie)
	elif n is CanvasModulate:
		pass
	if n is CanvasModulate:
		sortie.append("canvas_modulate|%s" % _couleur((n as CanvasModulate).color))
	elif n is WorldEnvironment:
		var env := (n as WorldEnvironment).environment
		sortie.append("environnement|%s" % (var_to_str(env).sha256_text().substr(0, 16) if env else "-"))
	for enfant in n.get_children():
		_parcourir_signature(enfant, sortie)


func _signature() -> Dictionary:
	var elements: Array = ["ecran|" + _v(ecran.size)]
	_parcourir_signature(scene_racine, elements)
	elements.sort()
	var resume := {}
	for e in elements:
		var genre: String = e.get_slice("|", 0)
		if genre == "quad":
			genre += ":" + e.get_slice("|", 1)
		resume[genre] = int(resume.get(genre, 0)) + 1
	return {"hachage": "\n".join(elements).sha256_text(), "nombre": elements.size(), "resume": resume}
