extends SceneTree
## Compare deux images de même taille (deux rendus d'une même vue) et décrit l'écart, sans fenêtre.
##
## Usage : godot --headless --path <projet> -s <ce script> -- a=<a.png> b=<b.png> [seuil=24] [grille=12x8]
##
## Un pixel « change » quand une de ses composantes (de 0 à 255) diffère de plus de `seuil`.
## Rapport : une ligne JSON préfixée par @@IMAGES@@ : taille, pixels qui changent et leur part,
## écart maximal, boîte englobante des pixels qui changent, décompte par case d'une grille
## (rangée par rangée, de haut en bas), luminance et couleur moyennes avant (a) et après (b) sur
## ces pixels. En cas d'échec : {"erreur": "…"}.
## Le script est typé : lancé par -s, il hérite des avertissements du projet ouvert (règle 5.3).

const MARQUEUR := "@@IMAGES@@"


func _initialize() -> void:
	var args := {}
	for argument: String in OS.get_cmdline_user_args():
		var morceaux := argument.split("=", true, 1)
		if morceaux.size() == 2:
			args[morceaux[0]] = morceaux[1]
	print(MARQUEUR + JSON.stringify(_comparer(args)))
	quit(0)


func _luminance(r: float, g: float, b: float) -> float:
	return 0.2126 * r + 0.7152 * g + 0.0722 * b


func _comparer(args: Dictionary) -> Dictionary:
	var a := Image.load_from_file(str(args.get("a", "")))
	var b := Image.load_from_file(str(args.get("b", "")))
	if a == null or b == null:
		return {"erreur": "image illisible : %s ou %s" % [args.get("a", ""), args.get("b", "")]}
	if a.get_size() != b.get_size():
		return {"erreur": "tailles différentes : %s et %s" % [a.get_size(), b.get_size()]}
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	var seuil := int(str(args.get("seuil", "24")))
	var grille := str(args.get("grille", "12x8")).split("x")
	var colonnes := int(grille[0])
	var rangees := int(grille[1])
	var largeur := a.get_width()
	var hauteur := a.get_height()
	var da := a.get_data()
	var db := b.get_data()
	var cases: Array[int] = []
	cases.resize(colonnes * rangees)
	cases.fill(0)
	var changes := 0
	var ecart_max := 0
	var x0 := largeur
	var y0 := hauteur
	var x1 := -1
	var y1 := -1
	var somme_a: Array[float] = [0.0, 0.0, 0.0]
	var somme_b: Array[float] = [0.0, 0.0, 0.0]
	for y: int in hauteur:
		var rangee := mini(int(float(y * rangees) / hauteur), rangees - 1)
		for x: int in largeur:
			var i := (y * largeur + x) * 3
			var ecart := maxi(absi(da[i] - db[i]), maxi(absi(da[i + 1] - db[i + 1]), absi(da[i + 2] - db[i + 2])))
			if ecart > ecart_max:
				ecart_max = ecart
			if ecart <= seuil:
				continue
			changes += 1
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
			cases[rangee * colonnes + mini(int(float(x * colonnes) / largeur), colonnes - 1)] += 1
			for k: int in 3:
				somme_a[k] += da[i + k]
				somme_b[k] += db[i + k]
	var rapport := {"largeur": largeur, "hauteur": hauteur, "seuil": seuil, "changes": changes,
		"part": float(changes) / float(largeur * hauteur), "ecart_max": ecart_max,
		"boite": [x0, y0, x1, y1] if changes > 0 else [], "grille": [colonnes, rangees], "cases": cases}
	if changes > 0:
		var couleur_a: Array[float] = []
		var couleur_b: Array[float] = []
		for k: int in 3:
			couleur_a.append(somme_a[k] / changes)
			couleur_b.append(somme_b[k] / changes)
		rapport["couleur_a"] = couleur_a
		rapport["couleur_b"] = couleur_b
		rapport["lum_a"] = _luminance(couleur_a[0], couleur_a[1], couleur_a[2])
		rapport["lum_b"] = _luminance(couleur_b[0], couleur_b[1], couleur_b[2])
	return rapport
