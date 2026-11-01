extends GdUnitTestSuite
## Règles de la scène principale : elle montre une image à la taille de la grille.
#@ 5+
## À chaque image de physique, la source nourrit le fluide.
#@ 10+
## C'est un feu : la chaleur se montre en couleurs, et un glissé de la souris pousse le fluide.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func _main() -> Control:
	var main: Control = auto_free(MAIN.instantiate())
	add_child(main)
	return main


func test_elle_montre_une_image() -> void:
	var main: Control = _main()
	var vue: TextureRect = main.get_node("View") as TextureRect
	assert_object(vue.texture).is_not_null()
#@ 1-4
	assert_int(vue.texture.get_width()).is_equal(64)
#@ 5-9
	assert_int(vue.texture.get_width()).is_equal(main.get("settings").width)
#@ 5+


func test_la_source_nourrit_le_fluide() -> void:
	var main: Control = _main()
	for _i: int in 6:
		await get_tree().physics_frame
	var fluide: FluidSolver = main.get("_solver")
#@ 5-9
	assert_float(fluide.density.total()).is_greater(0.0)
#@ 10+
	assert_float(fluide.temperature.total()).is_greater(0.0)
	assert_object(fluide.fire).is_not_null()


func test_un_glisse_de_la_souris_pousse_le_fluide() -> void:
	var main: Control = _main()
	await get_tree().physics_frame
	var geste: InputEventMouseMotion = InputEventMouseMotion.new()
	geste.button_mask = MOUSE_BUTTON_MASK_LEFT
	geste.position = Vector2(20.0, 20.0)
	geste.relative = Vector2(30.0, 0.0)
	var fluide: FluidSolver = main.get("_solver")
	var avant: float = fluide.u.peak()
	main.call("_unhandled_input", geste)
	assert_float(fluide.u.peak()).is_greater(avant)
#@ all
