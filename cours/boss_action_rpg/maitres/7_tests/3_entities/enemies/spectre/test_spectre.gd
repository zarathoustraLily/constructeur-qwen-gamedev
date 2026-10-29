extends GdUnitTestSuite
## Règles d'un spectre (réglages raccourcis pour le test) : au départ il dort (invisible, intouchable, sans coup) ;
## appelé, il plane sur son cercle au-dessus de sa cible ; après sa planée il annonce (en s'illuminant) puis plonge
## vers le torse de sa cible ; sa plongée touche une fois, et seulement pendant la plongée ; il remonte puis replane ;
## sa cible abattue, il ne plonge plus ; trois tirs le dissipent pour de bon ; son modèle est un squelette spectral
## (le shader de spectre sur chaque pièce, un matériau à lui, des maillages partagés) ; pour annoncer, il ouvre les bras
## au-dessus des épaules et la mâchoire ; il plonge couché, griffes en avant, linceul étiré ; dissipé, il s'affaisse.

const SPECTRE := preload("res://3_entities/enemies/spectre/spectre.tscn")
const SHADER_PATH: String = "res://6_assets/Shader/Characters/spectre.gdshader"


## Un corps de test sur la couche du héros, qui note les coups reçus.
class Victim extends CharacterBody3D:
	var hits: Array[float] = []

	func take_hit(amount: float, _from: Vector3) -> float:
		hits.append(amount)
		return amount


var _world: Node3D
var _victim: Victim
var _dissipated: int = 0


func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)
	_victim = Victim.new()
	_victim.collision_layer = Layers.bit(Layers.HERO)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	_victim.add_child(shape)
	_world.add_child(_victim)
	_dissipated = 0


func _spectre() -> Spectre:
	var spectre: Spectre = SPECTRE.instantiate() as Spectre
	var settings: SpectreSettings = spectre.settings.duplicate() as SpectreSettings
	settings.hover_time = 0.3
	settings.windup_time = 0.2
	settings.recover_time = 0.3
	settings.fade_time = 0.2
	spectre.settings = settings
	spectre.position = Vector3(0.0, 2.6, 6.0)
	_world.add_child(spectre)
	spectre.dissipated.connect(_on_dissipated)
	return spectre


func _on_dissipated() -> void:
	_dissipated += 1


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_au_depart_il_dort() -> void:
	var spectre: Spectre = _spectre()
	assert_bool(spectre.visible).is_false()
	assert_str(spectre.machine.current.name).is_equal("Idle")
	assert_int(spectre.hurtbox.collision_layer).is_equal(0)
	assert_bool(spectre.hitbox.active).is_false()


func test_appele_il_plane_au_dessus_de_sa_cible() -> void:
	var spectre: Spectre = _spectre()
	spectre.settings.hover_time = 5.0
	spectre.activate(_victim, 0.0)
	assert_bool(spectre.is_active()).is_true()
	assert_int(spectre.hurtbox.collision_layer).is_equal(Layers.bit(Layers.TARGETS))
	await _frames(150)
	assert_str(spectre.machine.current.name).is_equal("Hover")
	assert_float(spectre.global_position.y).is_equal_approx(spectre.settings.hover_height, 0.2)
	var au_sol: Vector2 = Vector2(spectre.global_position.x, spectre.global_position.z)
	assert_float(au_sol.length()).is_equal_approx(spectre.settings.hover_radius, 0.6)


func test_il_annonce_puis_plonge_et_touche_une_fois() -> void:
	var spectre: Spectre = _spectre()
	spectre.activate(_victim, 0.0)
	await _frames(22)
	assert_str(spectre.machine.current.name).is_equal("Windup")
	assert_float((spectre.get_node("View") as SpectreView).intensity).is_greater(spectre.settings.base_intensity)
	await _frames(14)
	assert_str(spectre.machine.current.name).is_equal("Dive")
	assert_bool(spectre.hitbox.active).is_true()
	await _frames(40)
	assert_array(_victim.hits).is_equal([spectre.settings.damage])
	assert_bool(spectre.hitbox.active).is_false()


func test_apres_la_plongee_il_remonte_puis_replane() -> void:
	var spectre: Spectre = _spectre()
	spectre.activate(_victim, 0.0)
	var vus: Array[StringName] = []
	spectre.machine.state_changed.connect(func(_from: StringName, to: StringName) -> void: vus.append(to))
	await _frames(120)
	assert_array(vus).contains([&"Windup", &"Dive", &"Recover"])
	assert_int(vus.count(&"Hover")).is_greater_equal(1)


func test_sa_cible_abattue_il_ne_plonge_plus() -> void:
	var spectre: Spectre = _spectre()
	var settings: HealthSettings = HealthSettings.new()
	settings.max_health = 10.0
	var sante: HealthComponent = HealthComponent.new()
	sante.settings = settings
	_victim.add_child(sante)
	sante.take_damage(10.0)
	spectre.activate(_victim, 0.0, sante)
	await _frames(60)
	assert_str(spectre.machine.current.name).is_equal("Hover")
	assert_array(_victim.hits).is_empty()


func test_trois_tirs_le_dissipent_pour_de_bon() -> void:
	var spectre: Spectre = _spectre()
	spectre.settings.hover_time = 5.0
	spectre.activate(_victim, 0.0)
	for _i: int in 3:
		spectre.hurtbox.receive(12.0)
	assert_str(spectre.machine.current.name).is_equal("Fade")
	assert_int(spectre.hurtbox.collision_layer).is_equal(0)
	await _frames(20)
	assert_bool(spectre.visible).is_false()
	assert_bool(spectre.gone).is_true()
	assert_int(_dissipated).is_equal(1)
	spectre.activate(_victim, 0.0)
	assert_bool(spectre.visible).is_false()


func _poser(spectre: Spectre, etat: StringName) -> void:
	spectre.machine.transition_to(etat)
	for _i: int in 60:
		(spectre.get_node("View") as SpectreView).update(1.0 / 60.0)


func test_son_modele_est_un_squelette_spectral() -> void:
	var spectre: Spectre = _spectre()
	var autre: Spectre = _spectre()
	var view: SpectreView = spectre.get_node("View") as SpectreView
	var pieces: Array[Node] = view.get_node("Model").find_children("*", "MeshInstance3D", true, false)
	assert_int(pieces.size()).is_equal(10)
	for n: Node in pieces:
		var mi: MeshInstance3D = n as MeshInstance3D
		assert_str((mi.material_override as ShaderMaterial).shader.resource_path).is_equal(SHADER_PATH)
		assert_object(mi.material_override).is_same(view.own_material)
	assert_object(view.own_material).is_not_same(view.material)
	var torse: MeshInstance3D = view.get_node("Model/Torso") as MeshInstance3D
	assert_object((autre.get_node("View/Model/Torso") as MeshInstance3D).mesh).is_same(torse.mesh)


func test_pour_annoncer_il_ouvre_les_bras_et_la_machoire() -> void:
	var spectre: Spectre = _spectre()
	spectre.settings.hover_time = 5.0
	spectre.activate(_victim, 0.0)
	_poser(spectre, &"Windup")
	var model: SpectreModel = spectre.get_node("View/Model") as SpectreModel
	for k: int in 2:
		assert_float(model.wrists[k].global_position.y).is_greater(model.shoulders[k].global_position.y)
	assert_float(model.wrists[0].global_position.distance_to(model.wrists[1].global_position)).is_greater(0.9)
	assert_float(model.jaw.rotation.x).is_less(-0.4)


func test_il_plonge_couche_griffes_en_avant() -> void:
	var spectre: Spectre = _spectre()
	spectre.activate(_victim, 0.0)
	_poser(spectre, &"Dive")
	var model: SpectreModel = spectre.get_node("View/Model") as SpectreModel
	var tete: Vector3 = spectre.to_local(model.head.global_position)
	assert_float(tete.z).is_less(-0.25)
	for k: int in 2:
		assert_float(spectre.to_local(model.wrists[k].global_position).z).is_less(tete.z)
	var view: SpectreView = spectre.get_node("View") as SpectreView
	assert_float(float(view.own_material.get_shader_parameter(&"trail"))).is_greater(0.4)


func test_dissipe_il_s_affaisse() -> void:
	var spectre: Spectre = _spectre()
	spectre.settings.hover_time = 5.0
	spectre.activate(_victim, 0.0)
	_poser(spectre, &"Hover")
	var model: SpectreModel = spectre.get_node("View/Model") as SpectreModel
	var debout: float = spectre.to_local(model.head.global_position).y
	_poser(spectre, &"Fade")
	assert_float(spectre.to_local(model.head.global_position).y).is_less(debout - 0.3)
