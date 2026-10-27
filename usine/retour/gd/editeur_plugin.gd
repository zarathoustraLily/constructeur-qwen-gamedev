@tool
extends EditorPlugin
## Voir l'éditeur Godot tel qu'on le voit (outil voir_editeur de l'usine), posé en plugin dans une copie du projet.
## L'usine lance l'éditeur réduit ; le plugin pose la fenêtre hors de l'écran à la taille voulue, ouvre la scène,
## sélectionne le nœud, déplie l'Inspecteur et le fait défiler jusqu'à la propriété visée, puis rend la fenêtre
## entière (PNG) et écrit sa vérité (JSON) : zones de l'éditeur, lignes de l'arbre de scène, propriétés visibles de
## l'Inspecteur et leur valeur affichée, place des nœuds 3D dans la vue de l'éditeur. Puis il quitte.
## Arguments après « -- » : --editeur-sortie=<base> --editeur-scene=res://… --editeur-selection=<chemin depuis la
## racine> --editeur-propriete=<nom> --editeur-ecran=3D --editeur-taille=1920x1080 --editeur-position=-6000,-6000

const PREFIXE := "--editeur-"
const DOCKS := {
	"SceneTreeDock": "scene", "FileSystemDock": "systeme_de_fichiers", "InspectorDock": "inspecteur",
	"ImportDock": "importer", "NodeDock": "signaux",
}

var _args: Dictionary[String, String] = {}


func _enter_tree() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(PREFIXE):
			var corps := a.trim_prefix(PREFIXE)
			_args[corps.get_slice("=", 0)] = corps.substr(corps.find("=") + 1) if corps.contains("=") else ""
	if not _args.has("sortie"):
		return
	var fenetre := get_tree().root
	var xy := _arg("position", "-6000,-6000").split(",")
	var t := _arg("taille", "1920x1080").split("x")
	fenetre.position = Vector2i(int(xy[0]), int(xy[1]))
	fenetre.mode = Window.MODE_WINDOWED
	fenetre.size = Vector2i(int(t[0]), int(t[1]))
	fenetre.position = Vector2i(int(xy[0]), int(xy[1]))
	_lancer.call_deferred()


func _arg(nom: String, defaut: String) -> String:
	return _args[nom] if _args.has(nom) else defaut


func _images(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _lancer() -> void:
	# Filet : sur une erreur en route, l'éditeur se ferme quand même (il est hors de l'écran, personne ne le voit).
	get_tree().create_timer(60.0).timeout.connect(get_tree().quit)
	await _images(30)
	var fs := EditorInterface.get_resource_filesystem()
	var attente := 0
	while fs.is_scanning() and attente < 1200:
		await get_tree().process_frame
		attente += 1
	var erreurs: Array[String] = []
	var scene := _arg("scene", "")
	if not scene.is_empty():
		EditorInterface.open_scene_from_path(scene)
		await _images(10)
	var racine := EditorInterface.get_edited_scene_root()
	# Écran principal : celui demandé, sinon 3D pour une scène 3D et 2D pour le reste.
	EditorInterface.set_main_screen_editor(_arg("ecran", "3D" if racine is Node3D else "2D"))
	if racine == null:
		erreurs.append("aucune scène ouverte")
	var noeud: Node = null
	var chemin := _arg("selection", "")
	if racine != null and not chemin.is_empty():
		noeud = racine if chemin == "." else racine.get_node_or_null(NodePath(chemin))
		if noeud == null:
			erreurs.append("nœud introuvable : " + chemin)
	if noeud != null:
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(noeud)
		EditorInterface.edit_node(noeud)
	await _images(10)
	var inspecteur := EditorInterface.get_inspector()
	var propriete := _arg("propriete", "")
	if not propriete.is_empty() and noeud != null:
		inspecteur.expand_all_folding()
		await _images(5)
		var cible := _editeur_de(inspecteur, propriete)
		if cible == null:
			erreurs.append("propriété absente de l'Inspecteur : " + propriete)
		else:
			inspecteur.ensure_control_visible(cible)
	await _images(30)
	var image := get_tree().root.get_texture().get_image()
	image.save_png(_args["sortie"] + ".png")
	var reduite := _arg("reduite", "").split("x")
	if reduite.size() == 2:
		var petite := image.duplicate() as Image
		petite.resize(int(reduite[0]), int(reduite[1]), Image.INTERPOLATE_LANCZOS)
		petite.save_png(_args["sortie"] + "_reduite.png")
	var donnees := {
		"fenetre": [get_tree().root.size.x, get_tree().root.size.y],
		"langue": EditorInterface.get_editor_language(),
		"echelle": EditorInterface.get_editor_scale(),
		"scene": scene,
		"selection": String(racine.get_path_to(noeud)) if racine != null and noeud != null else "",
		"propriete": propriete,
		"zones": _zones(),
		"haut": _boutons_du_haut(),
		"bas": _boutons_du_bas(),
		"traductions": {"Output": EditorInterface.get_base_control().atr("Output")},
		"arbre": _arbre(racine),
		"inspecteur": _inspecteur(inspecteur),
		"vue_3d": _vue_3d(racine),
	}
	# Après l'image : d'autres propriétés, lues dans l'Inspecteur telles qu'il les affiche (sans image).
	var releves: Array[Dictionary] = []
	for releve: String in _arg("releves", "").split(";", false):
		var chemin_r := releve.get_slice(":", 0)
		var propriete_r := releve.get_slice(":", 1)
		var n_r: Node = null
		if racine != null:
			n_r = racine if chemin_r == "." else racine.get_node_or_null(NodePath(chemin_r))
		if n_r == null:
			erreurs.append("relevé : nœud introuvable : " + chemin_r)
			continue
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(n_r)
		EditorInterface.edit_node(n_r)
		await _images(5)
		inspecteur.expand_all_folding()
		await _images(5)
		var e := _editeur_de(inspecteur, propriete_r)
		if e == null:
			erreurs.append("relevé : propriété absente de l'Inspecteur : " + releve)
			continue
		releves.append({"chemin": chemin_r, "propriete": propriete_r, "libelle": e.label, "affiche": _affiche(e),
			"valeur": var_to_str(n_r.get(propriete_r)), "groupe": _groupe(n_r, propriete_r)})
	donnees["releves"] = releves
	donnees["erreurs"] = erreurs
	var f := FileAccess.open(_args["sortie"] + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(donnees, " ", false))
	f.close()
	get_tree().quit()


func _rect(r: Rect2) -> Array[int]:
	return [roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y)]


func _titre_d_onglet(c: Control) -> String:
	## Le titre affiché de l'onglet du dock : son nom, traduit dans la langue de l'éditeur (« Scene » → « Scène »).
	return c.atr(String(c.name))


func _zones() -> Dictionary:
	var zones := {}
	var base := EditorInterface.get_base_control()
	for classe: String in DOCKS:
		for n: Node in base.find_children("*", classe, true, false):
			var c := n as Control
			zones[DOCKS[classe]] = {"titre": _titre_d_onglet(c), "rect": _rect(c.get_global_rect()),
				"visible": c.is_visible_in_tree()}
	var vue := EditorInterface.get_editor_viewport_3d(0)
	var conteneur := vue.get_parent() as Control
	zones["vue_3d"] = {"titre": "3D", "rect": _rect(conteneur.get_global_rect()), "visible": conteneur.is_visible_in_tree()}
	var ecran := EditorInterface.get_editor_main_screen()
	zones["ecran_principal"] = {"titre": "", "rect": _rect(ecran.get_global_rect()), "visible": ecran.is_visible_in_tree()}
	for n: Node in base.find_children("*", "EditorBottomPanel", true, false):
		var c := n as Control
		zones["panneau_du_bas"] = {"titre": "", "rect": _rect(c.get_global_rect()), "visible": c.is_visible_in_tree()}
	return zones


func _boutons_du_haut() -> Array[Dictionary]:
	## Les boutons de la barre du haut : écrans principaux (texte) et lancement (bulle d'aide).
	var limite := 48.0 * EditorInterface.get_editor_scale()
	return _boutons(func(r: Rect2) -> bool: return r.position.y <= limite)


func _boutons_du_bas() -> Array[Dictionary]:
	## Les onglets du panneau du bas (Sortie, Débogueur…), dessinés par une barre d'onglets, puis ses boutons.
	var panneaux := EditorInterface.get_base_control().find_children("*", "EditorBottomPanel", true, false)
	if panneaux.is_empty():
		return []
	var panneau := panneaux[0] as Control
	var zone := panneau.get_global_rect()
	var sortie: Array[Dictionary] = []
	for n: Node in panneau.find_children("*", "TabBar", true, false):
		var barre := n as TabBar
		if not barre.is_visible_in_tree():
			continue
		for i in barre.get_tab_count():
			if barre.is_tab_hidden(i):
				continue
			var r := barre.get_tab_rect(i)
			sortie.append({"texte": barre.atr(barre.get_tab_title(i)), "bulle": "", "onglet": true,
				"rect": _rect(Rect2(barre.get_global_rect().position + r.position, r.size)),
				"enfonce": i == barre.current_tab})
	sortie.append_array(_boutons(func(r: Rect2) -> bool: return zone.has_point(r.get_center())))
	return sortie


func _boutons(garder: Callable) -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	for n: Node in EditorInterface.get_base_control().find_children("*", "Button", true, false):
		var b := n as Button
		if not b.is_visible_in_tree() or not garder.call(b.get_global_rect()):
			continue
		if b.text.is_empty() and b.tooltip_text.is_empty():
			continue
		sortie.append({"texte": b.atr(b.text), "bulle": b.atr(b.tooltip_text).get_slice("\n", 0),
			"rect": _rect(b.get_global_rect()), "enfonce": b.button_pressed})
	return sortie


func _arbre(racine: Node) -> Array[Dictionary]:
	var lignes: Array[Dictionary] = []
	var docks := EditorInterface.get_base_control().find_children("*", "SceneTreeDock", true, false)
	if docks.is_empty() or racine == null:
		return lignes
	var dock := docks[0] as Control
	var arbres := dock.find_children("*", "Tree", true, false)
	if arbres.is_empty():
		return lignes
	var arbre := arbres[0] as Tree
	var zone := arbre.get_global_rect()
	var item := arbre.get_root()
	var rang := 0
	while item != null:
		if item.is_visible_in_tree():
			var r := arbre.get_item_area_rect(item)
			var global := Rect2(zone.position + r.position - Vector2(arbre.get_scroll()), r.size)
			var chemin := ""
			var type := ""
			var visible := true  # l'œil de la ligne est fermé quand le nœud est caché
			var meta: Variant = item.get_metadata(0)
			if meta is NodePath:
				var n := racine.get_tree().root.get_node_or_null(meta as NodePath)
				if n != null:
					chemin = String(racine.get_path_to(n))
					type = n.get_class()
					if n is Node3D or n is CanvasItem:
						visible = bool(n.get("visible"))
			lignes.append({"rang": rang, "texte": item.get_text(0), "chemin": chemin, "type": type, "visible": visible,
				"rect": _rect(global), "selectionne": item.is_selected(0), "replie": item.collapsed,
				"dans_la_zone": zone.encloses(global)})
			rang += 1
		item = item.get_next_in_tree()
	return lignes


func _editeur_de(inspecteur: EditorInspector, propriete: String) -> EditorProperty:
	for n: Node in inspecteur.find_children("*", "EditorProperty", true, false):
		var p := n as EditorProperty
		if p.get_edited_property() == StringName(propriete) and p.is_visible_in_tree():
			return p
	return null


func _inspecteur(inspecteur: EditorInspector) -> Dictionary:
	var objet := inspecteur.get_edited_object()
	var zone := inspecteur.get_global_rect()
	var proprietes: Array[Dictionary] = []
	for n: Node in inspecteur.find_children("*", "EditorProperty", true, false):
		var p := n as EditorProperty
		if not p.is_visible_in_tree() or String(p.get_edited_property()).is_empty():
			continue
		var r := p.get_global_rect()
		if not zone.intersects(r):
			continue
		var valeur: Variant = p.get_edited_object().get(p.get_edited_property()) if p.get_edited_object() != null else null
		proprietes.append({"propriete": String(p.get_edited_property()), "libelle": p.label, "rect": _rect(r),
			"entiere": zone.encloses(r), "valeur": var_to_str(valeur), "affiche": _affiche(p),
			"groupe": _groupe(p.get_edited_object(), String(p.get_edited_property()))})
	return {"objet": String(objet.get("name")) if objet != null else "", "classe": objet.get_class() if objet != null else "",
		"rect": _rect(zone), "proprietes": proprietes}


func _groupe(objet: Object, propriete: String) -> String:
	## La section de l'Inspecteur qui contient la propriété (« Transform », « Visibility »…), d'après la liste des
	## propriétés de l'objet : un groupe court jusqu'au groupe ou à la catégorie suivante.
	if objet == null:
		return ""
	var groupe := ""
	for p: Dictionary in objet.get_property_list():
		var usage: int = p["usage"]
		if usage & PROPERTY_USAGE_CATEGORY:
			groupe = ""
		elif usage & PROPERTY_USAGE_GROUP:
			groupe = String(p["name"])
		elif String(p["name"]) == propriete:
			return groupe
	return ""


func _affiche(p: EditorProperty) -> Array[String]:
	## Ce que montrent les champs de la propriété, tels qu'affichés (les rotations en degrés, par exemple).
	var champs: Array[String] = []
	for n: Node in p.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if c is EditorSpinSlider:
			var s := c as EditorSpinSlider
			var entier := s.get_step() >= 1.0 or s.editing_integer
			var nombre := str(roundi(s.value)) if entier else String.num(s.value, 3)
			if not entier and not nombre.contains("."):
				nombre += ".0"
			champs.append((s.label + " " if not s.label.is_empty() else "") + nombre + s.suffix)
		elif c is CheckBox:
			champs.append("coché" if (c as CheckBox).button_pressed else "non coché")
		elif c is OptionButton:
			champs.append((c as OptionButton).text)
		elif c is LineEdit and not (c.get_parent() is EditorSpinSlider):
			champs.append((c as LineEdit).text)
		elif c is Button and not (c is CheckBox) and not (c as Button).text.is_empty():
			champs.append((c as Button).text)
	return champs


func _vue_3d(racine: Node) -> Dictionary:
	var vue := EditorInterface.get_editor_viewport_3d(0)
	var conteneur := vue.get_parent() as Control
	var camera := vue.get_camera_3d()
	var zone := conteneur.get_global_rect()
	var noeuds: Array[Dictionary] = []
	if camera != null and racine != null:
		var echelle := zone.size / Vector2(vue.size)
		var a_voir: Array[Node] = [racine]
		a_voir.append_array(racine.find_children("*", "Node3D", true, false))
		for n: Node in a_voir:
			var n3 := n as Node3D
			if n3 == null:
				continue
			var p := n3.global_position
			var devant := (-camera.global_basis.z).dot(p - camera.global_position) > 0.0
			var ecran := zone.position + camera.unproject_position(p) * echelle if devant else Vector2(-1, -1)
			noeuds.append({"chemin": String(racine.get_path_to(n3)), "position": [p.x, p.y, p.z],
				"ecran": [roundi(ecran.x), roundi(ecran.y)], "dans_la_vue": devant and zone.has_point(ecran)})
	return {"rect": _rect(zone), "camera": [camera.global_position.x, camera.global_position.y, camera.global_position.z]
		if camera != null else [], "noeuds": noeuds}
