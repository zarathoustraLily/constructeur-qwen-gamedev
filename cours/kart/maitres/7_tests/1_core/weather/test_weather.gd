extends GdUnitTestSuite
## Règles de la météo : s'il pleut au départ, la route part mouillée, sinon sèche ; le mouillage rejoint la
## pluie à sa vitesse ; sous l'averse, les éclairs tombent à des délais pris entre le plus court et le plus long ;
## sous une pluie faible, aucun ; une même graine redonne le même orage.


func _settings(intensity: float, start_wet: bool, random_seed: int = 0) -> WeatherSettings:
	var settings := WeatherSettings.new()
	settings.intensity = intensity
	settings.wetness_speed = 0.5
	settings.start_wet = start_wet
	settings.lightning_min_intensity = 0.5
	settings.lightning_interval_min = 1.0
	settings.lightning_interval_max = 2.0
	settings.random_seed = random_seed
	return settings


## Les instants des éclairs pendant `seconds`, par pas de 1/60 s.
func _strikes(weather: Weather, seconds: float) -> Array[float]:
	var times: Array[float] = []
	var step := 1.0 / 60.0
	for frame: int in int(seconds / step):
		if weather.update(step):
			times.append(frame * step)
	return times


func test_s_il_pleut_au_depart_la_route_part_mouillee() -> void:
	assert_float(Weather.new(_settings(0.8, true)).wetness).is_equal(0.8)
	assert_float(Weather.new(_settings(0.8, false)).wetness).is_equal(0.0)


func test_le_mouillage_rejoint_la_pluie_a_sa_vitesse() -> void:
	var weather := Weather.new(_settings(0.8, false))
	weather.update(1.0)
	assert_float(weather.wetness).is_equal_approx(0.5, 0.0001)
	weather.update(1.0)
	assert_float(weather.wetness).is_equal_approx(0.8, 0.0001)


func test_sous_l_averse_les_eclairs_tombent_entre_les_deux_delais() -> void:
	var times := _strikes(Weather.new(_settings(0.8, true)), 20.0)
	assert_int(times.size()).is_between(9, 20)
	for index: int in range(1, times.size()):
		assert_float(times[index] - times[index - 1]).is_between(1.0 - 0.02, 2.0 + 0.02)


func test_sous_une_pluie_faible_aucun_eclair() -> void:
	assert_array(_strikes(Weather.new(_settings(0.3, true)), 20.0)).is_empty()


func test_une_meme_graine_redonne_le_meme_orage() -> void:
	var first := _strikes(Weather.new(_settings(0.8, true, 3)), 20.0)
	assert_array(_strikes(Weather.new(_settings(0.8, true, 3)), 20.0)).is_equal(first)
	assert_array(_strikes(Weather.new(_settings(0.8, true, 4)), 20.0)).is_not_equal(first)
