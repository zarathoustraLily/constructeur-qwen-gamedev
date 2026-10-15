extends GdUnitTestSuite
## La grille de captures : cases rangées de gauche à droite puis de haut en bas.

const CAPTURE := preload("res://0_autoload/capture.gd")


func _image(color: Color) -> Image:
	var img := Image.create_empty(10, 6, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img


func test_grille() -> void:
	var shots: Array[Image] = [_image(Color.RED), _image(Color.GREEN), _image(Color.BLUE)]
	var sheet: Image = CAPTURE.compose(shots, 2)
	assert_int(sheet.get_width()).is_equal(2 * 10 + 3 * CAPTURE.GAP)
	assert_int(sheet.get_height()).is_equal(2 * 6 + 3 * CAPTURE.GAP)
	assert_that(sheet.get_pixel(CAPTURE.GAP, CAPTURE.GAP)).is_equal(Color.RED)
	assert_that(sheet.get_pixel(2 * CAPTURE.GAP + 10, CAPTURE.GAP)).is_equal(Color.GREEN)
	assert_that(sheet.get_pixel(CAPTURE.GAP, 2 * CAPTURE.GAP + 6)).is_equal(Color.BLUE)


func test_images_triees() -> void:
	assert_array(Array(CAPTURE.parse_frames("90, 30,60"))).is_equal([30, 60, 90])


func test_touches() -> void:
	var press: CAPTURE.Press = CAPTURE.parse_press("move_up:10-90")
	assert_str(String(press.action)).is_equal("move_up")
	assert_int(press.first).is_equal(10)
	assert_int(press.last).is_equal(90)
	assert_object(CAPTURE.parse_press("voler:10-90")).is_null()


func test_inerte_sans_argument() -> void:
	assert_bool(Capture.capturing).is_false()
