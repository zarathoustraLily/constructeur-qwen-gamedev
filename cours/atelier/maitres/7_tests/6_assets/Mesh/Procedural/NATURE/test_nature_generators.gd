extends GdUnitTestSuite
## Règles des générateurs : l'arbre pose son bois et ses feuilles à l'ouverture, et les reconstruit sans doublon
## quand ses réglages changent ; le champ de nuages et la galaxie portent un MultiMesh du bon nombre de copies ; sans
## réglages, rien n'est construit.

const TREE := preload("res://6_assets/Mesh/Procedural/NATURE/tree.tscn")
const CLOUDS := preload("res://6_assets/Mesh/Procedural/NATURE/clouds.tscn")
const GALAXY := preload("res://6_assets/Mesh/Procedural/NATURE/galaxy.tscn")


func test_l_arbre_pose_son_bois_et_ses_feuilles() -> void:
	var tree: TreeGenerator = auto_free(TREE.instantiate())
	add_child(tree)
	var wood: MeshInstance3D = tree.get_node("Wood") as MeshInstance3D
	var leaves: MultiMeshInstance3D = tree.get_node("Leaves") as MultiMeshInstance3D
	assert_int(wood.mesh.get_surface_count()).is_equal(1)
	assert_int(leaves.multimesh.instance_count).is_equal(27 * tree.settings.leaves_per_tip)


func test_changer_les_reglages_reconstruit_sans_doublon() -> void:
	var tree: TreeGenerator = auto_free(TREE.instantiate())
	add_child(tree)
	var other: TreeSettings = tree.settings.duplicate() as TreeSettings
	other.depth = 2
	tree.settings = other
	assert_int(tree.get_child_count()).is_equal(2)
	assert_int((tree.get_node("Leaves") as MultiMeshInstance3D).multimesh.instance_count).is_equal(9 * other.leaves_per_tip)


func test_les_nuages_et_la_galaxie_portent_leurs_copies() -> void:
	var clouds: CloudField = auto_free(CLOUDS.instantiate())
	var galaxy: GalaxyGenerator = auto_free(GALAXY.instantiate())
	add_child(clouds)
	add_child(galaxy)
	assert_int(clouds.multimesh.instance_count).is_equal(clouds.settings.puff_count)
	assert_int(galaxy.multimesh.instance_count).is_equal(galaxy.settings.star_count)
	assert_bool((galaxy.material_override as StandardMaterial3D).vertex_color_use_as_albedo).is_true()


func test_sans_reglages_rien_n_est_construit() -> void:
	var clouds: CloudField = auto_free(CloudField.new())
	add_child(clouds)
	assert_object(clouds.multimesh).is_null()
