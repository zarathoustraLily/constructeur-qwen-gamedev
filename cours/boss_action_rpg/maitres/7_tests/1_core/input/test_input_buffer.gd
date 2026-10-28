extends GdUnitTestSuite
## Règles de la mémoire d'appui : un appui se consomme une seule fois ; un appui plus ancien que sa fenêtre est
## oublié ; sans appui, rien.

var _buffer: InputBuffer


func before_test() -> void:
	_buffer = auto_free(InputBuffer.new())
	_buffer.window = 0.25


func test_un_appui_se_consomme_une_seule_fois() -> void:
	_buffer.press()
	_buffer.tick(0.2)
	assert_bool(_buffer.is_pending()).is_true()
	assert_bool(_buffer.consume()).is_true()
	assert_bool(_buffer.consume()).is_false()


func test_un_appui_trop_ancien_est_oublie() -> void:
	_buffer.press()
	_buffer.tick(0.3)
	assert_bool(_buffer.is_pending()).is_false()
	assert_bool(_buffer.consume()).is_false()


func test_sans_appui_rien() -> void:
	assert_bool(_buffer.consume()).is_false()
