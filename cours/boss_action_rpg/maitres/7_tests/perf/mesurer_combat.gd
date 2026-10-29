extends SceneTree
## Mesure le combat, sans fenêtre et sans joueur : le héros (invulnérable) tire sans cesse sur le golem, qui l'attaque ;
## la seconde phase commence en pleine fenêtre, une demi-seconde après son début (spectres, rugissement, braise,
## bouclier jeté) ; la vie du golem est remontée pour que le combat dure. Après l'échauffement, sur la fenêtre :
## - allocations : le compteur d'allocations de l'ObjectDB, lu au début et à la fin (les bits hauts de l'identifiant
##   d'un objet témoin, créé puis libéré) ; il voit chaque objet créé, même libéré aussitôt ;
## - temps : la durée de chaque image (Time.get_ticks_usec), en médiane et au plus haut (les moniteurs de temps du
##   moteur, TIME_PROCESS et TIME_PHYSICS_PROCESS, restent à 0 sous un script lancé par -s : on ne les lit pas) ;
## - objets et nœuds au début et à la fin de la fenêtre ;
## - ce qui se dessine (compté dans l'arbre : en headless, le moteur ne dessine rien) : instances visibles, surfaces,
##   couches par-dessus, émetteurs de particules, lumières qui font des ombres.
#@ 15+
## - la qualité graphique appliquée et les passes d'ombre qu'elle peut demander par image ; `--qualite=basse` (après
##   les deux nombres) choisit la qualité basse.
#@ 14+
## Résultat : une ligne « @@MESURE@@<json> ».
##   godot --headless --fixed-fps 60 --path <projet> -s res://7_tests/perf/mesurer_combat.gd -- <échauffement> <fenêtre>

const MARQUEUR: String = "@@MESURE@@"
const MASQUE_COMPTEUR: int = (1 << 39) - 1

var _echauffement: int = 300
var _fenetre: int = 600
var _scene: Node3D
var _hero: Hero
var _golem: Golem
var _image: int = 0
var _compteur_debut: int = 0
var _objets_debut: int = 0
var _noeuds_debut: int = 0
var _tic: int = 0
var _durees: PackedInt64Array = PackedInt64Array()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 2:
		_echauffement = int(args[0])
		_fenetre = int(args[1])
	_durees.resize(_fenetre)
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)
	current_scene = _scene


func _physics_process(_delta: float) -> bool:
	_image += 1
	if _image == 2:
		_preparer()
	if _image > 2:
		_jouer()
	var debut: int = _echauffement
	if _image == debut:
		_objets_debut = int(Performance.get_monitor(Performance.OBJECT_COUNT))
		_noeuds_debut = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		_compteur_debut = _compteur()
		_tic = Time.get_ticks_usec()
	elif _image > debut and _image <= debut + _fenetre:
		var maintenant: int = Time.get_ticks_usec()
		var i: int = _image - debut - 1
		_durees[i] = maintenant - _tic
		_tic = maintenant
		if _image == debut + _fenetre:
			_conclure(_compteur() - _compteur_debut - 1)
			return true
	return false


func _preparer() -> void:
	_hero = _scene.get_node("Hero") as Hero
	_golem = _scene.get_node("Golem") as Golem
	_hero.get_node("Input").free()
	var orbit: OrbitCamera = _scene.get_node("OrbitCamera") as OrbitCamera
	orbit.get_node("Input").free()
	orbit.lock(_golem.lock_point)
	_hero.invulnerable = true
	_hero.global_position = _golem.global_position + Vector3(-7.0, 0.0, 0.0)
	_hero.rotation.y = Motion.yaw_of(Vector3.RIGHT)


func _jouer() -> void:
	_hero.invulnerable = true
	_hero.aiming = true
	_hero.trigger = true
	if _image == _echauffement + 30:
		_golem.health.take_damage(_golem.health.settings.max_health * 0.31)
	elif _image % 60 == 0:
		_golem.health.heal(_golem.health.settings.max_health)


func _compteur() -> int:
	var temoin: Object = Object.new()
	var c: int = (temoin.get_instance_id() >> 24) & MASQUE_COMPTEUR
	temoin.free()
	return c


func _conclure(allocations: int) -> void:
	var dessins: Dictionary = _dessins()
	var resultat: Dictionary = {
		"allocations": allocations,
		"images": _fenetre,
		"image_us_mediane": _mediane_entiers(_durees),
		"image_us_max": _max_entiers(_durees),
		"objets": [_objets_debut, int(Performance.get_monitor(Performance.OBJECT_COUNT))],
		"noeuds": [_noeuds_debut, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))],
		"golem_phase": _golem.phase,
		"golem_etat": String(_golem.machine.current.name),
	}
	resultat.merge(dessins)
#@ 15+
	var reglage: GraphicsQualityApplier = _scene.get_node("GraphicsQuality") as GraphicsQualityApplier
	resultat["qualite"] = String(reglage.current.id)
	resultat["passes_ombres"] = reglage.shadow_passes()
#@ 14+
	print(MARQUEUR + JSON.stringify(resultat))


func _dessins() -> Dictionary:
	var instances: int = 0
	var surfaces: int = 0
	var couches: int = 0
	var particules: int = 0
	var ombres: int = 0
	for n: Node in _scene.find_children("*", "GeometryInstance3D", true, false):
		var g: GeometryInstance3D = n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		instances += 1
		if g.material_overlay != null:
			couches += 1
		var mi: MeshInstance3D = g as MeshInstance3D
		if mi != null and mi.mesh != null:
			surfaces += mi.mesh.get_surface_count()
		if g is GPUParticles3D:
			particules += 1
	for n: Node in _scene.find_children("*", "Light3D", true, false):
		var l: Light3D = n as Light3D
		if l.is_visible_in_tree() and l.shadow_enabled:
			ombres += 1
	return {"instances": instances, "surfaces": surfaces, "couches": couches, "particules": particules,
			"lumieres_ombres": ombres}


func _mediane_entiers(valeurs: PackedInt64Array) -> int:
	var t: PackedInt64Array = valeurs.duplicate()
	t.sort()
	return t[floori(t.size() * 0.5)]


func _max_entiers(valeurs: PackedInt64Array) -> int:
	var m: int = 0
	for v: int in valeurs:
		m = maxi(m, v)
	return m
