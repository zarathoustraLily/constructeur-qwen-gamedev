extends GdUnitTestSuite
## La recherche de la palette : l'identifiant exact vient d'abord, puis ce qui commence par la requête ; chaque mot doit
## se trouver (un « et ») ; majuscules et accents ne comptent pas ; une catégorie se cherche aussi ; une requête vide
## rend tout, par ordre alphabétique.

var _search: AssetSearch


func before_test() -> void:
	_search = AssetSearch.new()
	_search.setup(ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef)


func test_l_identifiant_exact_vient_d_abord() -> void:
	assert_array(_search.search("lampe")).is_equal([&"lampe"])
	assert_array(_search.search("caisse cargo")).is_equal([&"caisse_cargo"])


func test_ce_qui_commence_par_la_requete_vient_ensuite() -> void:
	var found: Array[StringName] = _search.search("sol")
	assert_array(found.slice(0, 4)).contains_exactly_in_any_order([&"sol_beton", &"sol_caoutchouc", &"sol_panneaux",
			&"sol_tole"])


func test_chaque_mot_doit_se_trouver() -> void:
	assert_array(_search.search("sol tole")).is_equal([&"sol_tole"])
	assert_array(_search.search("sol licorne")).is_empty()


func test_majuscules_et_accents_ne_comptent_pas() -> void:
	assert_array(_search.search("Tôle")).is_equal([&"sol_tole"])
	assert_str(AssetSearch.normalize("Détail_Huile")).is_equal("detail huile")


func test_une_categorie_se_cherche_aussi() -> void:
	var found: Array[StringName] = _search.search("avant plan")
	assert_array(found).contains_exactly_in_any_order([&"tuyaux_plafond", &"cables_pendants", &"lampe"])


func test_une_requete_vide_rend_tout_par_ordre_alphabetique() -> void:
	var found: Array[StringName] = _search.search("")
	assert_int(found.size()).is_equal(20)
	assert_str(String(found[0])).is_equal("cables_pendants")
