extends GdUnitTestSuite
## Règles de la plaque de turbo : un kart qui passe dessus la fait signaler, avec sa durée de turbo.

const PANEL := preload("res://3_entities/interactables/boost_panel/boost_panel.tscn")
const KART := preload("res://3_entities/kart/kart.tscn")


func test_un_kart_qui_passe_dessus_la_fait_signaler() -> void:
	var panel: BoostPanel = auto_free(PANEL.instantiate())
	add_child(panel)
	var crossings: Array[float] = []
	panel.crossed.connect(func(_body: Node3D, boost_time: float) -> void: crossings.append(boost_time))
	var kart: Kart = auto_free(KART.instantiate())
	kart.input = null
	kart.position = Vector3(0.0, 3.0, 0.0)
	add_child(kart)
	for _frame: int in 30:
		await get_tree().physics_frame
	assert_array(crossings).is_equal([panel.boost_time])
	assert_float(panel.boost_time).is_greater(0.0)
