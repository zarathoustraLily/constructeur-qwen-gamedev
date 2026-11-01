extends GdUnitTestSuite
## Règles du transport : sans vitesse, rien ne bouge ; une vitesse uniforme déplace la matière d'autant ; à grande vitesse, rien
## ne dépasse le plus haut de départ ; le courant décide de la direction.
#@ 7+
## MacCormack garde la matière plus nette que le transport simple, sans jamais dépasser le plus haut de départ.
#@ all


## La position moyenne de la matière, le long de x.
func _centre_x(champ: FluidField) -> float:
	var somme: float = 0.0
	for y: int in champ.height:
		for x: int in champ.width:
			somme += x * champ.at(x, y)
	return somme / champ.total()


func test_sans_vitesse_rien_ne_bouge() -> void:
	var source: FluidField = FluidField.new(16, 16)
	source.add_disc(8.0, 8.0, 4.0, 1.0)
	var cible: FluidField = FluidField.new(16, 16)
	Advection.semi_lagrangian(cible, source, FluidField.new(16, 16), FluidField.new(16, 16), 0.5)
	assert_float(cible.at(8, 8)).is_equal_approx(source.at(8, 8), 0.0001)
	assert_float(cible.total()).is_equal_approx(source.total(), 0.0001)


func test_une_vitesse_uniforme_deplace_la_matiere_d_autant() -> void:
	var source: FluidField = FluidField.new(32, 16)
	source.add_disc(8.0, 8.0, 4.0, 1.0)
	var u: FluidField = FluidField.new(32, 16)
	u.fill(10.0)
	var cible: FluidField = FluidField.new(32, 16)
	Advection.semi_lagrangian(cible, source, u, FluidField.new(32, 16), 1.0)
	assert_float(_centre_x(cible)).is_equal_approx(18.0, 0.01)


func test_le_courant_decide_de_la_direction() -> void:
	var source: FluidField = FluidField.new(16, 32)
	source.add_disc(8.0, 20.0, 3.0, 1.0)
	var v: FluidField = FluidField.new(16, 32)
	v.fill(-5.0)
	var cible: FluidField = FluidField.new(16, 32)
	Advection.semi_lagrangian(cible, source, FluidField.new(16, 32), v, 1.0)
	assert_float(cible.at(8, 15)).is_equal_approx(source.at(8, 20), 0.0001)


func test_a_grande_vitesse_rien_ne_depasse_le_plus_haut_de_depart() -> void:
	var source: FluidField = FluidField.new(16, 16)
	source.add_disc(8.0, 8.0, 4.0, 1.0)
	var u: FluidField = FluidField.new(16, 16)
	var v: FluidField = FluidField.new(16, 16)
	for i: int in u.data.size():
		u.data[i] = sin(i * 0.7) * 300.0
		v.data[i] = cos(i * 1.3) * 300.0
	var cible: FluidField = FluidField.new(16, 16)
	Advection.semi_lagrangian(cible, source, u, v, 0.1)
	assert_float(cible.peak()).is_less_equal(source.peak() + 0.0001)
#@ 7+


func _transporte(net: bool) -> FluidField:
	var champ: FluidField = FluidField.new(48, 16)
	var cible: FluidField = FluidField.new(48, 16)
	var avant: FluidField = FluidField.new(48, 16)
	var arriere: FluidField = FluidField.new(48, 16)
	var u: FluidField = FluidField.new(48, 16)
	var v: FluidField = FluidField.new(48, 16)
	u.fill(7.3)
	champ.add_disc(10.0, 8.0, 5.0, 1.0)
	for _i: int in 3:
		if net:
			Advection.mac_cormack(cible, champ, u, v, 1.0, avant, arriere)
		else:
			Advection.semi_lagrangian(cible, champ, u, v, 1.0)
		champ.copy_from(cible)
	return champ


func test_mac_cormack_garde_la_matiere_plus_nette() -> void:
	assert_float(_transporte(true).peak()).is_greater(_transporte(false).peak() * 1.03)


func test_mac_cormack_ne_depasse_pas_le_plus_haut_de_depart() -> void:
	assert_float(_transporte(true).peak()).is_less_equal(1.0001)
#@ all
