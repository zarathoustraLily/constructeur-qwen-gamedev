extends SceneTree
## Décrit ce que Godot a réellement chargé d'une ou plusieurs scènes (SceneState), en JSON.
## Sert à comparer un .tscn d'origine et sa réécriture sans dépendre de notre lecteur.
## Usage : godot --headless --path <projet> -s etat_scene.gd -- res://a.tscn res://b.tscn
## Sortie : une ligne « @@ETAT_SCENE@@{json} » par scène.

const MARQUEUR := "@@ETAT_SCENE@@"


func _valeur(v: Variant) -> Variant:
	if v is Resource:
		var r: Resource = v
		if r.resource_path != "" and not r.resource_path.contains("::"):
			return {"externe": r.resource_path}
		var proprietes := {}
		for p in r.get_property_list():
			if p["usage"] & PROPERTY_USAGE_STORAGE and p["name"] not in ["resource_path", "resource_scene_unique_id"]:
				proprietes[p["name"]] = _valeur(r.get(p["name"]))
		return {"interne": r.get_class(), "proprietes": proprietes}
	if v is Array:
		var a := []
		for e in v:
			a.append(_valeur(e))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[var_to_str(k)] = _valeur(v[k])
		return d
	return var_to_str(v)


func _etat(chemin: String) -> Dictionary:
	var scene: PackedScene = load(chemin)
	if scene == null:
		return {"chemin": chemin, "erreur": "chargement impossible"}
	var etat := scene.get_state()
	var noeuds := []
	for i in etat.get_node_count():
		var proprietes := {}
		for j in etat.get_node_property_count(i):
			proprietes[etat.get_node_property_name(i, j)] = _valeur(etat.get_node_property_value(i, j))
		var instance := etat.get_node_instance(i)
		noeuds.append({
			"chemin": str(etat.get_node_path(i)),
			"type": str(etat.get_node_type(i)),
			"instance": instance.resource_path if instance else "",
			"groupes": Array(etat.get_node_groups(i)),
			"proprietes": proprietes,
		})
	var connexions := []
	for i in etat.get_connection_count():
		connexions.append({
			"source": str(etat.get_connection_source(i)),
			"signal": str(etat.get_connection_signal(i)),
			"cible": str(etat.get_connection_target(i)),
			"methode": str(etat.get_connection_method(i)),
			"flags": etat.get_connection_flags(i),
			"binds": _valeur(etat.get_connection_binds(i)),
			"unbinds": etat.get_connection_unbinds(i),
		})
	return {"chemin": chemin, "noeuds": noeuds, "connexions": connexions}


# À la première image et non dans _init : les autoloads sont alors enregistrés.
func _process(_delta: float) -> bool:
	for chemin in OS.get_cmdline_user_args():
		print(MARQUEUR + JSON.stringify(_etat(chemin), "", true))
	quit()
	return true
