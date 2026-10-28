extends GdUnitTestSuite
## Règles de l'éclair d'un coup : le maillage prend un voile non éclairé, transparent, de la couleur des réglages ;
## le voile s'efface puis disparaît après la durée de l'éclair ; un nouveau coup relance l'éclair.

const SETTINGS := preload("res://5_data/vfx/vfx.tres")


func _flash() -> HitFlash:
	var mesh: MeshInstance3D = auto_free(MeshInstance3D.new())
	mesh.mesh = BoxMesh.new()
	add_child(mesh)
	var flash: HitFlash = auto_free(HitFlash.new())
	flash.mesh = mesh
	flash.settings = SETTINGS
	add_child(flash)
	return flash


func test_le_voile_est_non_eclaire_transparent_et_de_la_bonne_couleur() -> void:
	var overlay: StandardMaterial3D = HitFlash.make_overlay(SETTINGS.flash_color)
	assert_int(overlay.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_int(overlay.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_that(overlay.albedo_color).is_equal(SETTINGS.flash_color)


func test_un_coup_pose_le_voile() -> void:
	var flash: HitFlash = _flash()
	flash.flash()
	assert_bool(flash.is_flashing()).is_true()
	assert_float((flash.mesh.material_overlay as StandardMaterial3D).albedo_color.a).is_equal_approx(SETTINGS.flash_color.a, 0.0001)


func test_le_voile_s_efface_puis_disparait() -> void:
	var flash: HitFlash = _flash()
	flash.flash()
	await get_tree().create_timer(SETTINGS.flash_duration * 0.5).timeout
	var overlay: StandardMaterial3D = flash.mesh.material_overlay as StandardMaterial3D
	assert_float(overlay.albedo_color.a).is_less(SETTINGS.flash_color.a)
	await get_tree().create_timer(SETTINGS.flash_duration + 0.1).timeout
	assert_bool(flash.is_flashing()).is_false()


func test_un_nouveau_coup_relance_l_eclair() -> void:
	var flash: HitFlash = _flash()
	flash.flash()
	await get_tree().create_timer(SETTINGS.flash_duration * 0.8).timeout
	flash.flash()
	await get_tree().create_timer(SETTINGS.flash_duration * 0.5).timeout
	assert_bool(flash.is_flashing()).is_true()
