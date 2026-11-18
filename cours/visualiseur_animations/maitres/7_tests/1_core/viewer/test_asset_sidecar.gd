extends GdUnitTestSuite
## Le fichier d'accompagnement dit les animations qui bouclent et la cadence d'un dossier d'images ; absent, rien ne
## boucle et la cadence est celle par défaut, sans erreur ; une cadence fausse est signalée.


func _entry(path: String, kind: AssetEntry.Kind) -> AssetEntry:
	var entry: AssetEntry = AssetEntry.new()
	entry.path = path
	entry.kind = kind
	return entry


func test_l_accompagnement_du_heros_dit_ses_boucles() -> void:
	var sidecar: AssetSidecar = AssetSidecar.load_for(_entry("res://6_assets/exemple/heros/heros.glb",
			AssetEntry.Kind.MODEL_3D))
	assert_array(sidecar.errors).is_empty()
	assert_bool(sidecar.loops_clip("course")).is_true()
	assert_bool(sidecar.loops_clip("attaque")).is_false()


func test_l_accompagnement_d_un_dossier_d_images_dit_sa_cadence() -> void:
	var sidecar: AssetSidecar = AssetSidecar.load_for(_entry("res://6_assets/exemple/effets/etincelle",
			AssetEntry.Kind.FRAMES_2D))
	assert_float(sidecar.fps).is_equal(16.0)


func test_sans_accompagnement_rien_ne_boucle() -> void:
	var sidecar: AssetSidecar = AssetSidecar.load_for(_entry("res://6_assets/exemple/absent.glb",
			AssetEntry.Kind.MODEL_3D))
	assert_array(sidecar.errors).is_empty()
	assert_array(sidecar.loops).is_empty()
	assert_float(sidecar.fps).is_equal(AssetSidecar.DEFAULT_FPS)


func test_une_cadence_fausse_est_signalee() -> void:
	var sidecar: AssetSidecar = AssetSidecar.parse("{\"ips\": 0}")
	assert_float(sidecar.fps).is_equal(AssetSidecar.DEFAULT_FPS)
	assert_array(sidecar.errors).is_equal(["« ips » doit être un nombre plus grand que 0"])
