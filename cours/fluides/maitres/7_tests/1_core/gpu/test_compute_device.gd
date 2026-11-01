extends GdUnitTestSuite
## Règles de l'appareil : il s'ouvre, un tampon rend ce qu'on y a mis, et `release` rend tout à la carte.
#@ 12+
## Une texture rend le champ qu'on y a mis, garde sa taille, et part de zéro même après une autre.
#@ 13+
## L'image des murs garde un octet par case.
#@ 14+
## `copy` recopie une texture sur la carte.
#@ 16+
## L'appareil du rendu ne se ferme pas : `release` lui rend seulement ce qu'on lui a pris.
#@ 17+
## Un volume a ses trois côtés et son format, et le filtre de la carte n'est créé qu'une fois.
#@ 20+
## Une image de couleur a quatre flottants par case et part de zéro.
#@ all

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	if _device.rd != null:
		_device.release()


func test_une_carte_s_ouvre() -> void:
	assert_object(_device).is_not_null()
	assert_object(_device.rd).is_not_null()


func test_un_tampon_rend_ce_qu_on_y_a_mis() -> void:
	var tampon: RID = _device.new_buffer(PackedFloat32Array([1.0, 2.5, -3.0]))
	assert_array(Array(_device.read_buffer(tampon))).is_equal([1.0, 2.5, -3.0])


func test_keep_rend_ce_qu_on_lui_donne() -> void:
	var tampon: RID = _device.rd.storage_buffer_create(4)
	assert_bool(_device.keep(tampon) == tampon).is_true()


#@ 12+
func test_une_texture_rend_le_champ_qu_on_y_a_mis() -> void:
	var champ: FluidField = FluidField.new(3, 2)
	champ.put(0, 0, 1.5)
	champ.put(2, 1, -4.0)
	var texture: RID = _device.new_texture(3, 2)
	_device.upload(texture, champ)
	var relu: FluidField = FluidField.new(3, 2)
	_device.download(texture, relu)
	assert_float(relu.at(0, 0)).is_equal(1.5)
	assert_float(relu.at(2, 1)).is_equal(-4.0)
	assert_float(relu.at(1, 0)).is_equal(0.0)


func test_une_texture_neuve_est_vide_meme_apres_une_autre() -> void:
	var format: RDTextureFormat = _device.rd.texture_get_format(_device.new_texture(8, 8))
	var plein: FluidField = FluidField.new(8, 8)
	plein.fill(7.0)
	for _i: int in 4:
		var ancienne: RID = _device.rd.texture_create(format, RDTextureView.new())
		_device.upload(ancienne, plein)
		_device.finish()
		_device.rd.free_rid(ancienne)
	_device.finish()
	var relu: FluidField = FluidField.new(8, 8)
	_device.download(_device.new_texture(8, 8), relu)
	assert_float(relu.peak()).is_equal(0.0)


func test_une_texture_garde_la_taille_demandee() -> void:
	var format: RDTextureFormat = _device.rd.texture_get_format(_device.new_texture(5, 7))
	assert_int(format.width).is_equal(5)
	assert_int(format.height).is_equal(7)


#@ 13+
func test_l_image_des_murs_garde_un_octet_par_case() -> void:
	var murs: ObstacleMask = ObstacleMask.new(3, 2)
	murs.add_box(1, 0, 1, 1)
	var image: RID = _device.new_mask(murs)
	assert_int(_device.rd.texture_get_format(image).format).is_equal(RenderingDevice.DATA_FORMAT_R8_UNORM)
	assert_array(Array(_device.rd.texture_get_data(image, 0))).is_equal(Array(murs.solid))


#@ 14+
func test_copy_recopie_une_texture_sur_la_carte() -> void:
	var champ: FluidField = FluidField.new(4, 3)
	champ.put(1, 2, 5.0)
	var source: RID = _device.new_texture(4, 3)
	_device.upload(source, champ)
	var cible: RID = _device.new_texture(4, 3)
	_device.copy(cible, source)
	_device.finish()
	var relu: FluidField = FluidField.new(4, 3)
	_device.download(cible, relu)
	assert_float(relu.at(1, 2)).is_equal(5.0)
	assert_float(relu.at(0, 0)).is_equal(0.0)


#@ 16+
func test_l_appareil_du_rendu_n_est_pas_ferme_par_release() -> void:
	var partage: ComputeDevice = ComputeDevice.shared()
	assert_bool(partage.rd == RenderingServer.get_rendering_device()).is_true()
	partage.finish()
	partage.release()
	assert_object(partage.rd).is_null()
	assert_object(RenderingServer.get_rendering_device()).is_not_null()


#@ 17+
func test_un_volume_a_ses_trois_cotes_et_son_format() -> void:
	var format: RDTextureFormat = _device.rd.texture_get_format(_device.new_volume(Vector3i(2, 3, 4), false))
	assert_int(format.texture_type).is_equal(RenderingDevice.TEXTURE_TYPE_3D)
	assert_int(format.width).is_equal(2)
	assert_int(format.height).is_equal(3)
	assert_int(format.depth).is_equal(4)
	assert_int(format.format).is_equal(RenderingDevice.DATA_FORMAT_R32_SFLOAT)


func test_un_volume_de_vitesse_a_quatre_flottants_par_case() -> void:
	var volume: RID = _device.new_volume(Vector3i(2, 2, 2), true)
	assert_int(_device.rd.texture_get_data(volume, 0).size()).is_equal(2 * 2 * 2 * 16)


func test_le_filtre_n_est_cree_qu_une_fois() -> void:
	var filtre: RID = _device.trilinear()
	assert_bool(filtre.is_valid()).is_true()
	assert_bool(_device.trilinear() == filtre).is_true()


#@ 20+
func test_une_image_de_couleur_a_quatre_flottants_et_part_de_zero() -> void:
	var image: RID = _device.new_color_texture(2, 3)
	var format: RDTextureFormat = _device.rd.texture_get_format(image)
	assert_int(format.format).is_equal(RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	assert_int(format.height).is_equal(3)
	var cases: PackedFloat32Array = _device.rd.texture_get_data(image, 0).to_float32_array()
	assert_int(cases.size()).is_equal(2 * 3 * 4)
	assert_float(cases[0]).is_equal(0.0)


#@ all
func test_release_ferme_l_appareil() -> void:
	_device.new_buffer(PackedFloat32Array([1.0]))
	_device.release()
	assert_object(_device.rd).is_null()
