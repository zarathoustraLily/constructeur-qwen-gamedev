extends GdUnitTestSuite
## Règles de la couche des chiffres de dégâts : show_damage() y pose un chiffre, qui écrit les dégâts et suit le
## point du monde donné.

const NUMBERS := preload("res://4_ui/hud/damage_numbers/damage_numbers.tscn")


func test_show_damage_pose_un_chiffre_au_dessus_du_point_donne() -> void:
	var numbers: DamageNumbers = auto_free(NUMBERS.instantiate())
	add_child(numbers)
	var number := numbers.show_damage(Vector3(2.0, 1.0, -3.0), 5.0)
	assert_object(number.get_parent()).is_same(numbers)
	assert_str(number.label.text).is_equal("5.0")
	assert_vector(number.target_position).is_equal(Vector3(2.0, 1.0, -3.0))
