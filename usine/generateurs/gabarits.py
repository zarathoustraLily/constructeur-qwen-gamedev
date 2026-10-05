"""Gabarits de tests cachés et fonctions GDScript de mesure.

Une fonction de mesure GDScript sert deux fois, au caractère près :
  - le générateur la lance sur la solution de référence pour obtenir la vérité terrain
    (écrite dans tests_caches/ sous forme de JSON) ;
  - le test caché la relance sur le projet candidat et compare.
La vérité vient donc du moteur, jamais d'un calcul refait en Python ni d'un LLM.
"""

from __future__ import annotations

from usine.generateurs.commun import MARQUEUR

CATEGORIES_D1 = ["parse_error", "null_instance", "invalid_node_path", "signal_missing", "type_error",
                 "missing_resource", "autre"]

CONSIGNE_D1 = (
    "Le fichier journal.txt contient la sortie de Godot quand on lance ce projet en headless. "
    "Trouver l'erreur à l'origine du problème et écrire res://reponse.json au format "
    '{"categorie": "...", "fichier": "res://...", "ligne": N}, où fichier:ligne est la ligne du script '
    "qui provoque l'erreur. Catégories possibles : " + ", ".join(CATEGORIES_D1) + ". "
    "Ne modifier aucun autre fichier."
)

GABARIT_TEST_D1 = '''extends GdUnitTestSuite
## Juge D1 : la réponse res://reponse.json doit donner la bonne catégorie et la bonne position.

const CATEGORIE := "{categorie}"
const FICHIER := "{fichier}"
const LIGNE := {ligne}


func _reponse() -> Dictionary:
	if not FileAccess.file_exists("res://reponse.json"):
		return {{}}
	var donnees = JSON.parse_string(FileAccess.get_file_as_string("res://reponse.json"))
	return donnees if donnees is Dictionary else {{}}


func test_categorie() -> void:
	assert_str(str(_reponse().get("categorie", ""))).is_equal(CATEGORIE)


func test_fichier() -> void:
	assert_str(str(_reponse().get("fichier", ""))).is_equal(FICHIER)


func test_ligne() -> void:
	var ligne = _reponse().get("ligne", -1)
	assert_bool(ligne is float or ligne is int).is_true()
	assert_int(int(ligne)).is_equal(LIGNE)
'''

GABARIT_TEST_S2 = '''extends GdUnitTestSuite
## Juge S2 : connexions déclarées dans {scene}.

const SCENE := "{scene}"
const ATTENDUES := {attendues}


func _connexions() -> Array:
	var etat := (load(SCENE) as PackedScene).get_state()
	var resultat: Array = []
	for i in etat.get_connection_count():
		resultat.append([
			str(etat.get_connection_source(i)),
			str(etat.get_connection_signal(i)),
			str(etat.get_connection_target(i)),
			str(etat.get_connection_method(i)),
		])
	return resultat


func test_connexions_declarees_dans_la_scene() -> void:
	var presentes := _connexions()
	for attendue in ATTENDUES:
		assert_array(presentes).contains([attendue])
'''

# --- Données de vérité partagées par le générateur et le test caché ----------------------------

ENTETE_MESURE = f'''extends SceneTree
## Lancé par le générateur sur la solution de référence : imprime la vérité terrain.

const MARQUEUR := "{MARQUEUR}"

'''

FIN_MESURE = '''

## Mesure à la première image : l'arbre est alors prêt (_ready des nœuds ajoutés, espace physique).
func _process(_delta: float) -> bool:
	var args := OS.get_cmdline_user_args()
	var sortie = call(args[0], args[1], JSON.parse_string(args[2]) if args.size() > 2 else null)
	print(MARQUEUR + JSON.stringify(sortie))
	return true
'''

# K1 : interface d'un script, lue par réflexion.
FONCTION_INTERFACE = '''func _args(liste: Array) -> Array:
	var resultat: Array = []
	for a in liste:
		resultat.append([str(a["name"]), int(a["type"]), str(a["class_name"])])
	return resultat


func interface_script(chemin: String, _plan = null) -> Dictionary:
	if not ResourceLoader.exists(chemin):
		return {"charge": false}
	var s := load(chemin) as Script
	if s == null or not s.can_instantiate():
		return {"charge": false}
	var methodes := {}
	for m in s.get_script_method_list():
		methodes[str(m["name"])] = {"args": _args(m["args"]), "defauts": m["default_args"].size(),
			"retour": [int(m["return"]["type"]), str(m["return"]["class_name"])]}
	var signaux := {}
	for sg in s.get_script_signal_list():
		signaux[str(sg["name"])] = _args(sg["args"])
	var variables := {}
	for p in s.get_script_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		variables[str(p["name"])] = {"type": int(p["type"]), "classe": str(p["class_name"]),
			"exportee": bool(int(p["usage"]) & PROPERTY_USAGE_EDITOR),
			"defaut": var_to_str(s.get_property_default_value(p["name"]))}
	var constantes: Array = s.get_script_constant_map().keys()
	constantes.sort()
	return {"charge": true, "classe": str(s.get_global_name()), "base": str(s.get_instance_base_type()),
		"methodes": methodes, "signaux": signaux, "variables": variables, "constantes": constantes}
'''

GABARIT_TEST_K1 = '''extends GdUnitTestSuite
## Juge K1 : l'interface de {script} (classe, méthodes, signaux, variables, constantes)
## doit être celle demandée. Vérité terrain : interface_k1.json, lue par réflexion sur la référence.

const SCRIPT := "{script}"
const ATTENDU := "res://tests_juge/interface_k1.json"


{fonction}

func _norm(v) -> Variant:
	return JSON.parse_string(JSON.stringify(v))


func _calcule() -> Dictionary:
	return _norm(interface_script(SCRIPT))


func _attendu() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ATTENDU))


func test_script_charge() -> void:
	assert_bool(_calcule()["charge"]).is_true()


func test_classe_et_base() -> void:
	var c := _calcule()
	var a := _attendu()
	assert_str(str(c.get("classe", ""))).is_equal(a["classe"])
	assert_str(str(c.get("base", ""))).is_equal(a["base"])


func test_methodes() -> void:
	var c: Dictionary = _calcule().get("methodes", {{}})
	var a: Dictionary = _attendu()["methodes"]
	for nom in a:
		assert_that(c.get(nom)).override_failure_message("méthode " + nom).is_equal(a[nom])


func test_signaux() -> void:
	var c: Dictionary = _calcule().get("signaux", {{}})
	var a: Dictionary = _attendu()["signaux"]
	for nom in a:
		assert_that(c.get(nom)).override_failure_message("signal " + nom).is_equal(a[nom])


func test_variables() -> void:
	var c: Dictionary = _calcule().get("variables", {{}})
	var a: Dictionary = _attendu()["variables"]
	for nom in a:
		assert_that(c.get(nom)).override_failure_message("variable " + nom).is_equal(a[nom])


func test_constantes() -> void:
	assert_that(_calcule().get("constantes", [])).is_equal(_attendu()["constantes"])
'''

# S1 : état stocké d'une scène (sans l'ajouter à l'arbre), restreint au plan tiré de la spec.
FONCTION_ETAT_SCENE = '''func _valeur(v, sous) -> Variant:
	if sous is Dictionary:
		if not (v is Resource):
			return ["pas une ressource", type_string(typeof(v))]
		var props := {}
		for k in sous:
			props[k] = _valeur(v.get(k), sous[k])
		return {"classe": v.get_class(), "props": props}
	if v is Resource:
		if v.resource_path != "" and not v.resource_path.contains("::"):
			return {"chemin": v.resource_path}
		return {"classe": v.get_class()}
	if v is Object:
		return {"objet": v.get_class()}
	return var_to_str(v)


func etat_scene(chemin: String, plan) -> Dictionary:
	if not ResourceLoader.exists(chemin):
		return {"charge": false}
	var ps := load(chemin) as PackedScene
	if ps == null or not ps.can_instantiate():
		return {"charge": false}
	var racine := ps.instantiate()
	var noeuds := {}
	for p in plan["noeuds"]:
		var n: Node = racine if p == "." else racine.get_node_or_null(NodePath(p))
		if n == null:
			noeuds[p] = null
			continue
		var groupes: Array = []
		for g in n.get_groups():
			if not str(g).begins_with("_"):
				groupes.append(str(g))
		groupes.sort()
		var script = n.get_script()
		var props := {}
		for k in plan["noeuds"][p]:
			props[k] = _valeur(n.get(k), plan["noeuds"][p][k])
		noeuds[p] = {"classe": n.get_class(), "script": script.resource_path if script else "",
			"scene": n.scene_file_path if p != "." else "", "groupes": groupes, "props": props}
	var etat := ps.get_state()
	var connexions: Array = []
	for i in etat.get_connection_count():
		connexions.append([str(etat.get_connection_source(i)), str(etat.get_connection_signal(i)),
			str(etat.get_connection_target(i)), str(etat.get_connection_method(i)),
			etat.get_connection_flags(i), var_to_str(etat.get_connection_binds(i)),
			etat.get_connection_unbinds(i)])
	connexions.sort()
	racine.free()
	return {"charge": true, "noeuds": noeuds, "connexions": connexions}
'''

GABARIT_TEST_S1 = '''extends GdUnitTestSuite
## Juge S1 : la scène {scene} doit avoir les nœuds, propriétés, groupes et connexions
## demandés. Vérité terrain : etat_s1.json (plan tiré de la spec, état lu sur la référence).

const SCENE := "{scene}"
const ATTENDU := "res://tests_juge/etat_s1.json"


{fonction}

func _attendu() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ATTENDU))


func _calcule() -> Dictionary:
	return JSON.parse_string(JSON.stringify(etat_scene(SCENE, _attendu()["plan"])))


func test_scene_chargee() -> void:
	assert_bool(_calcule()["charge"]).is_true()


func test_noeuds() -> void:
	var c: Dictionary = _calcule().get("noeuds", {{}})
	var a: Dictionary = _attendu()["etat"]["noeuds"]
	for chemin in a:
		assert_that(c.get(chemin)).override_failure_message("nœud " + chemin).is_equal(a[chemin])


func test_connexions() -> void:
	assert_that(_calcule().get("connexions", [])).is_equal(_attendu()["etat"]["connexions"])
'''

# F1 : mesure en frames du héros, en physique déterministe : pas fixe (1/physics_ticks_per_second)
# et move_and_collide(velocity * dt). move_and_slide est évité : hors d'une image physique, il prend
# le delta de l'image de rendu, qui dépend de l'horloge.
FONCTION_MESURE_HERO = '''func _hero(scene: String, reglages) -> CharacterBody2D:
	var hero := (load(scene) as PackedScene).instantiate() as CharacterBody2D
	if reglages is Dictionary:
		for k in reglages:
			hero.set(k, reglages[k])
	# Espace vide : le héros mesuré ne heurte rien (ni décor, ni autre héros encore présent).
	hero.collision_layer = 0
	hero.collision_mask = 0
	var arbre := Engine.get_main_loop() as SceneTree
	arbre.root.add_child(hero)
	hero.position = Vector2.ZERO
	return hero


## Une image de _physics_process, avec une entrée imposée au lieu d'Input.
func _image(hero, entree: Vector2, dash: bool, dt: float) -> void:
	if entree != Vector2.ZERO:
		hero.facing = entree.normalized()
	if dash:
		hero.try_dash(entree)
	hero.advance_dash(dt)
	hero.velocity = hero.compute_velocity(entree)
	hero.move_and_collide(hero.velocity * dt)


## reglages (générateur seulement) : propriétés imposées au héros avant la mesure.
func mesurer_hero(scene: String, reglages = null) -> Dictionary:
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var hero = _hero(scene, reglages)
	for i in 30:
		_image(hero, Vector2.RIGHT, false, dt)
	var marche := snappedf(hero.position.x, 0.01)
	hero.position = Vector2.ZERO
	var images_dash := 0
	var images_invulnerable := 0
	var images_avant_redash := 0
	var dash_px := 0.0
	_image(hero, Vector2.ZERO, true, dt)
	var i := 1
	while i < 600:
		if hero.is_dashing():
			images_dash = i
			dash_px = snappedf(hero.position.x, 0.01)
		if hero.health.invulnerable:
			images_invulnerable = i
		if hero.can_dash():
			images_avant_redash = i
			break
		_image(hero, Vector2.ZERO, false, dt)
		i += 1
	var mesure := {"marche_30_images_px": marche, "images_dash": images_dash,
		"images_invulnerable": images_invulnerable, "images_avant_redash": images_avant_redash,
		"dash_px": dash_px}
	hero.free()
	return mesure
'''

GABARIT_TEST_F1 = '''extends GdUnitTestSuite
## Juge F1 : mesures du héros en frames (physique déterministe à 60 images/s).
## Vérité terrain : mesure_f1.json, mesurée par le moteur sur la solution de référence.

const SCENE := "res://scenes/hero.tscn"
const ATTENDU := "res://tests_juge/mesure_f1.json"
const TOLERANCE_PX := 0.5


{fonction}

func _attendu() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ATTENDU))


func _calcule() -> Dictionary:
	return JSON.parse_string(JSON.stringify(mesurer_hero(SCENE)))


func test_marche() -> void:
	assert_float(_calcule()["marche_30_images_px"]).is_equal_approx(_attendu()["marche_30_images_px"], TOLERANCE_PX)


func test_dash_en_images() -> void:
	assert_int(int(_calcule()["images_dash"])).is_equal(int(_attendu()["images_dash"]))


func test_invulnerabilite_en_images() -> void:
	assert_int(int(_calcule()["images_invulnerable"])).is_equal(int(_attendu()["images_invulnerable"]))


func test_recharge_en_images() -> void:
	assert_int(int(_calcule()["images_avant_redash"])).is_equal(int(_attendu()["images_avant_redash"]))


func test_distance_du_dash() -> void:
	assert_float(_calcule()["dash_px"]).is_equal_approx(_attendu()["dash_px"], TOLERANCE_PX)
'''


def script_mesure(fonction: str) -> str:
    """Script `extends SceneTree` lancé par le générateur : appelle <fonction>(<arg1>, <json>)."""
    return ENTETE_MESURE + fonction + FIN_MESURE


def test_k1(script_res: str) -> str:
    return GABARIT_TEST_K1.format(script=script_res, fonction=FONCTION_INTERFACE)


def test_s1(scene_res: str) -> str:
    return GABARIT_TEST_S1.format(scene=scene_res, fonction=FONCTION_ETAT_SCENE)


def test_f1() -> str:
    return GABARIT_TEST_F1.format(fonction=FONCTION_MESURE_HERO)
