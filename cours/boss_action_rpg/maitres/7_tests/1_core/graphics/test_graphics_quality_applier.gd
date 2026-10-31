extends GdUnitTestSuite
## Règles du choix de la qualité graphique : l'argument `--qualite=` l'emporte, puis le choix enregistré, puis la carte
## graphique (intégrée, logicielle ou virtuelle : basse ; sinon haute). Appliquer la basse coupe les effets d'écran
## coûteux et le brouillard volumétrique (la brume de repli prend sa place), rend la 3D plus petite (FSR), ne laisse des
## ombres qu'aux lumières les plus proches du combat, en demi-sphères, et ramène les portées ; la ressource
## d'environnement partagée reste intacte ; revenir à la haute rend tout.
#@ 19+
## La qualité basse coupe la lumière des effets brefs, la haute la rend.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func _main() -> Node3D:
	var main: Node3D = auto_free(MAIN.instantiate()) as Node3D
	add_child(main)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return main


func _reglage(main: Node3D) -> GraphicsQualityApplier:
	return main.get_node("GraphicsQuality") as GraphicsQualityApplier


func test_le_choix_suit_l_argument_puis_le_reglage_puis_la_carte() -> void:
	var reglage: GraphicsQualityApplier = _reglage(_main())
	var rien: PackedStringArray = PackedStringArray()
	assert_object(reglage.choose(PackedStringArray(["--qualite=basse"]), "haute", RenderingDevice.DEVICE_TYPE_DISCRETE_GPU)).is_same(reglage.low)
	assert_object(reglage.choose(rien, "basse", RenderingDevice.DEVICE_TYPE_DISCRETE_GPU)).is_same(reglage.low)
	assert_object(reglage.choose(rien, "", RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU)).is_same(reglage.low)
	assert_object(reglage.choose(rien, "", RenderingDevice.DEVICE_TYPE_CPU)).is_same(reglage.low)
	assert_object(reglage.choose(rien, "", RenderingDevice.DEVICE_TYPE_DISCRETE_GPU)).is_same(reglage.high)


func test_la_qualite_basse_allege_le_rendu() -> void:
	var main: Node3D = _main()
	var reglage: GraphicsQualityApplier = _reglage(main)
	var fenetre: SubViewport = auto_free(SubViewport.new()) as SubViewport
	add_child(fenetre)
	var partagee: Environment = load("res://5_data/environment/arena_environment.tres") as Environment
	var passes_hautes: int = 0
	reglage.apply(reglage.high, fenetre)
	passes_hautes = reglage.shadow_passes()
	reglage.apply(reglage.low, fenetre)
	var env: Environment = (main.get_node("World") as WorldEnvironment).environment
	assert_object(env).is_not_same(partagee)
	assert_bool(env.sdfgi_enabled or env.ssil_enabled or env.ssao_enabled or env.volumetric_fog_enabled).is_false()
	assert_bool(partagee.sdfgi_enabled).is_true()
	assert_bool((main.get_node("GroundMist") as Node3D).visible).is_false()
	assert_bool((main.get_node("MistLayers") as Node3D).visible).is_true()
	assert_float(fenetre.scaling_3d_scale).is_equal_approx(reglage.low.scale_3d, 0.001)
	assert_int(fenetre.scaling_3d_mode).is_equal(Viewport.SCALING_3D_MODE_FSR)
	var avec_ombres: Array[Light3D] = []
	for light: Light3D in reglage.lights:
		if light.shadow_enabled:
			avec_ombres.append(light)
		if light is OmniLight3D:
			assert_float((light as OmniLight3D).omni_range).is_less_equal(reglage.low.light_range_max)
	assert_array(avec_ombres).is_equal(reglage.lights.slice(0, reglage.low.shadow_lights))
	assert_float(float(reglage.shadow_passes())).is_less(passes_hautes * 0.25)


func test_revenir_a_la_haute_rend_tout() -> void:
	var main: Node3D = _main()
	var reglage: GraphicsQualityApplier = _reglage(main)
	var fenetre: SubViewport = auto_free(SubViewport.new()) as SubViewport
	add_child(fenetre)
	reglage.apply(reglage.high, fenetre)
	var ombres: int = reglage.shadow_passes()
	reglage.apply(reglage.low, fenetre)
	reglage.apply(reglage.high, fenetre)
	assert_int(reglage.shadow_passes()).is_equal(ombres)
	var env: Environment = (main.get_node("World") as WorldEnvironment).environment
	assert_bool(env.volumetric_fog_enabled).is_true()
	assert_bool((main.get_node("GroundMist") as Node3D).visible).is_true()
	assert_bool((main.get_node("MistLayers") as Node3D).visible).is_false()
	assert_float(fenetre.scaling_3d_scale).is_equal(1.0)
#@ 19+


func test_la_qualite_basse_coupe_la_lumiere_des_effets() -> void:
	var main: Node3D = _main()
	var reglage: GraphicsQualityApplier = _reglage(main)
	var fenetre: SubViewport = auto_free(SubViewport.new()) as SubViewport
	add_child(fenetre)
	var eclair: VfxBurst = main.get_node("Hero/Gun/MuzzleFlash") as VfxBurst
	var lumiere: Light3D = eclair.get_node("Light") as Light3D
	reglage.apply(reglage.low, fenetre)
	eclair.play()
	assert_bool(lumiere.visible).is_false()
	assert_bool((main.get_node("ImpactSparks/Flare") as VfxBurst).light_allowed).is_false()
	reglage.apply(reglage.high, fenetre)
	eclair.play()
	assert_bool(lumiere.visible).is_true()
#@ all
