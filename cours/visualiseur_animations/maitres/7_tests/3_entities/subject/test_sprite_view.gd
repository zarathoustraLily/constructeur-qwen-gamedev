extends GdUnitTestSuite
## Une animation 2D montrée avance image par image, en boucle ou jusqu'à la dernière ; chaque image se pose dans le
## cadre là où l'atlas la place, cadre posé par le milieu de son bord bas ; une image réduite garde sa taille à
## l'écran ; une animation « additif » s'ajoute à ce qui est derrière elle.
#@ 3+
## Une animation 2D faite pour un angle passe à la variante la plus proche de la caméra.
#@ all

const FLAME: String = "res://6_assets/exemple/effets/flamme/flamme.atlas.json"
const METERS_PER_PIXEL: float = 0.01


func _subject(sprites: SpriteSet, loops: Array[String]) -> SpriteView:
	var subject: SpriteView = auto_free(SpriteView.new())
	subject.manual = true
	add_child(subject)
	var sidecar: AssetSidecar = AssetSidecar.new()
	sidecar.loops = loops
	assert_bool(subject.show_sprites(sprites, sidecar, METERS_PER_PIXEL)).is_true()
	return subject


func _one_frame(frame: SpriteFrame, frame_size: Vector2i, clip: String = "seule") -> SpriteSet:
	var image: Image = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var sprites: SpriteSet = SpriteSet.new()
	sprites.pages.append(ImageTexture.create_from_image(image))
	var animation: SpriteAnimation = SpriteAnimation.new()
	animation.name = clip
	animation.frame_size = frame_size
	animation.frames.append(frame)
	sprites.animations[clip] = animation
	return sprites


func test_l_animation_avance_en_boucle_ou_s_arrete_sur_la_derniere_image() -> void:
	var looping: SpriteView = _subject(SpriteLoader.load_atlas(FLAME), ["flamme"])
	looping.play("flamme")
	assert_int(looping.frame_index()).is_equal(0)
	looping.advance(1.25)
	assert_int(looping.frame_index()).is_equal(3)
	var once: SpriteView = _subject(SpriteLoader.load_atlas(FLAME), [])
	once.play("flamme")
	once.advance(5.0)
	assert_int(once.frame_index()).is_equal(11)


func test_une_image_se_pose_dans_le_cadre_par_le_bas() -> void:
	var frame: SpriteFrame = SpriteFrame.new()
	frame.page = 0
	frame.region = Rect2i(4, 8, 20, 30)
	frame.offset = Vector2i(10, 50)
	frame.size = Vector2i(20, 30)
	var subject: SpriteView = _subject(_one_frame(frame, Vector2i(100, 100)), [])
	subject.play("seule")
	var sprite: Sprite3D = subject.sprite()
	assert_bool(sprite.visible).is_true()
	assert_object(sprite.region_rect).is_equal(Rect2(4, 8, 20, 30))
	assert_float(sprite.pixel_size).is_equal_approx(METERS_PER_PIXEL, 0.000001)
	# Milieu de l'image dans le cadre : x = 10 + 10 - 50 = -30 ; y = 100 - 50 - 15 = 35 (vers le haut).
	assert_vector(sprite.offset).is_equal(Vector2(-30, 35))


func test_une_image_reduite_garde_sa_taille_a_l_ecran() -> void:
	var frame: SpriteFrame = SpriteFrame.new()
	frame.page = 0
	frame.region = Rect2i(0, 0, 10, 15)
	frame.offset = Vector2i(10, 50)
	frame.size = Vector2i(20, 30)
	var subject: SpriteView = _subject(_one_frame(frame, Vector2i(100, 100)), [])
	subject.play("seule")
	var sprite: Sprite3D = subject.sprite()
	assert_float(sprite.pixel_size).is_equal_approx(METERS_PER_PIXEL * 2.0, 0.000001)
	assert_vector(sprite.offset * sprite.pixel_size).is_equal_approx(Vector2(-0.3, 0.35), Vector2.ONE * 0.000001)


func test_une_animation_additive_s_ajoute_a_ce_qui_est_derriere() -> void:
	var frame: SpriteFrame = SpriteFrame.new()
	frame.page = 0
	frame.region = Rect2i(0, 0, 8, 8)
	frame.size = Vector2i(8, 8)
	var sprites: SpriteSet = _one_frame(frame, Vector2i(8, 8))
	sprites.blend = "additif"
	var subject: SpriteView = _subject(sprites, [])
	subject.play("seule")
	var material: StandardMaterial3D = subject.sprite().material_override as StandardMaterial3D
	assert_int(material.blend_mode).is_equal(BaseMaterial3D.BLEND_MODE_ADD)
	assert_object(material.albedo_texture).is_same(subject.sprite().texture)
#@ 3+


func test_une_animation_2d_faite_pour_un_angle_prend_la_variante_proche() -> void:
	var frame: SpriteFrame = SpriteFrame.new()
	frame.page = 0
	frame.region = Rect2i(0, 0, 8, 8)
	frame.size = Vector2i(8, 8)
	var sprites: SpriteSet = _one_frame(frame, Vector2i(8, 8), "marche_angle_0")
	var back: SpriteAnimation = SpriteAnimation.new()
	back.name = "marche_angle_180"
	back.frame_size = Vector2i(8, 8)
	back.frames.append(frame)
	sprites.animations[back.name] = back
	var subject: SpriteView = _subject(sprites, [])
	subject.set_view_angle(170.0)
	assert_bool(subject.play_base("marche")).is_true()
	assert_str(subject.current_clip()).is_equal("marche_angle_180")
	subject.set_view_angle(10.0)
	assert_str(subject.current_clip()).is_equal("marche_angle_0")
#@ all
