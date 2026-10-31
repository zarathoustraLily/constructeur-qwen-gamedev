extends GdUnitTestSuite
#@ 13-18
## Règles des étincelles des tirs : l'impact d'un projectile de la réserve, relayé par elle, fait jaillir une salve au
## point touché ; les salves préparées servent à tour de rôle.

const SPARKS := preload("res://6_assets/VFX/combat/hit_sparks.tscn")
#@ 19+
## Règles des impacts des tirs : l'impact d'un projectile de la réserve, relayé par elle, fait jaillir une salve au point
## touché, tournée selon la surface ; les salves préparées servent à tour de rôle ; une seule lumière suit le dernier
## impact, devant la surface.

const SPARKS := preload("res://3_entities/hero/shot_impact.tscn")
#@ all
const PROJECTILE := preload("res://1_core/combat/projectile.tscn")


func test_chaque_impact_fait_jaillir_une_salve_au_point_touche_a_tour_de_role() -> void:
	var pool: ProjectilePool = auto_free(ProjectilePool.new()) as ProjectilePool
	pool.scene = PROJECTILE
	pool.size = 2
	add_child(pool)
	var etincelles: ImpactSparks = auto_free(ImpactSparks.new()) as ImpactSparks
	etincelles.pool = pool
#@ 19+
	var flare: VfxBurst = VfxBurst.new()
	flare.name = "Flare"
	etincelles.add_child(flare)
#@ all
	for _i: int in 2:
		etincelles.add_child(SPARKS.instantiate())
	add_child(etincelles)
	(pool.get_child(0) as Projectile).impacted.emit(Vector3(1.0, 2.0, 3.0), Vector3.UP, 12.0)
#@ 13-18
	var premiere: GPUParticles3D = etincelles.get_child(0) as GPUParticles3D
	assert_bool(premiere.emitting).is_true()
	assert_vector(premiere.global_position).is_equal_approx(Vector3(1.0, 2.05, 3.0), Vector3.ONE * 0.001)
	pool.impacted.emit(Vector3(-1.0, 0.0, 0.0), Vector3.RIGHT, 0.0)
	var seconde: GPUParticles3D = etincelles.get_child(1) as GPUParticles3D
	assert_bool(seconde.emitting).is_true()
	assert_vector(seconde.global_position).is_equal_approx(Vector3(-0.95, 0.0, 0.0), Vector3.ONE * 0.001)
#@ 19+
	var premiere: VfxBurst = etincelles.get_child(1) as VfxBurst
	assert_bool(premiere.visible).is_true()
	assert_vector(premiere.global_position).is_equal_approx(Vector3(1.0, 2.05, 3.0), Vector3.ONE * 0.001)
	assert_vector(premiere.global_basis.y).is_equal_approx(Vector3.UP, Vector3.ONE * 0.001)
	assert_float(flare.flare).is_equal(1.0)
	assert_vector(flare.global_position).is_equal_approx(Vector3(1.0, 2.0 + ImpactSparks.FLARE_LIFT, 3.0), Vector3.ONE * 0.001)
	pool.impacted.emit(Vector3(-1.0, 0.0, 0.0), Vector3.RIGHT, 0.0)
	var seconde: VfxBurst = etincelles.get_child(2) as VfxBurst
	assert_bool(seconde.visible).is_true()
	assert_vector(seconde.global_position).is_equal_approx(Vector3(-0.95, 0.0, 0.0), Vector3.ONE * 0.001)
	assert_vector(seconde.global_basis.y).is_equal_approx(Vector3.RIGHT, Vector3.ONE * 0.001)
	assert_vector(flare.global_position).is_equal_approx(Vector3(-1.0 + ImpactSparks.FLARE_LIFT, 0.0, 0.0), Vector3.ONE * 0.001)
#@ all
	assert_int(etincelles.next).is_equal(0)
