extends GdUnitTestSuite
## Règles de la réserve d'objets : elle prépare ses objets d'avance, cachés et arrêtés ; un objet pris est montré et
## tourne ; rendu, il resservira (même instance, aucune nouvelle création) ; au maximum, elle refuse ; rendre un objet
## qui n'est pas en service ne change rien ; un projectile tiré revient à la réserve à la fin de sa course.

const PROJECTILE := preload("res://3_entities/projectile/projectile.tscn")
const SETTINGS := preload("res://5_data/memory/projectile_pool.tres")


func _pool(settings: PoolSettings = SETTINGS) -> ObjectPool:
	var pool: ObjectPool = auto_free(ObjectPool.new())
	pool.scene = PROJECTILE
	pool.settings = settings
	add_child(pool)
	return pool


func test_elle_prepare_ses_objets_d_avance_caches_et_arretes() -> void:
	var pool: ObjectPool = _pool()
	assert_int(pool.available_count()).is_equal(SETTINGS.prewarm)
	assert_int(pool.get_child_count()).is_equal(SETTINGS.prewarm)
	var node: Node3D = pool.get_child(0) as Node3D
	assert_bool(node.visible).is_false()
	assert_int(node.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)


func test_un_objet_pris_est_montre_et_tourne() -> void:
	var pool: ObjectPool = _pool()
	var node: Node3D = pool.acquire() as Node3D
	assert_bool(node.visible).is_true()
	assert_int(node.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(pool.active_count()).is_equal(1)
	assert_int(pool.available_count()).is_equal(SETTINGS.prewarm - 1)


func test_rendu_il_resservira_sans_nouvelle_creation() -> void:
	var pool: ObjectPool = _pool()
	var node: Node = pool.acquire()
	pool.release(node)
	assert_that(pool.acquire()).is_same(node)
	assert_int(pool.get_child_count()).is_equal(SETTINGS.prewarm)


func test_au_maximum_elle_refuse() -> void:
	var small: PoolSettings = PoolSettings.new()
	small.prewarm = 1
	small.max_size = 2
	var pool: ObjectPool = _pool(small)
	assert_object(pool.acquire()).is_not_null()
	assert_object(pool.acquire()).is_not_null()
	assert_object(pool.acquire()).is_null()
	assert_int(pool.total()).is_equal(2)


func test_rendre_un_objet_hors_service_ne_change_rien() -> void:
	var pool: ObjectPool = _pool()
	var stranger: Node = auto_free(Node.new())
	pool.release(stranger)
	pool.release(pool.get_child(0))
	assert_int(pool.available_count()).is_equal(SETTINGS.prewarm)


func test_un_projectile_revient_a_la_reserve_en_fin_de_course() -> void:
	var pool: ObjectPool = _pool()
	var shot: Projectile = pool.acquire() as Projectile
	shot.expired.connect(func(p: Projectile) -> void: pool.release(p))
	shot.launch(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 0.5)
	shot.travel(0.25)
	assert_float(shot.position.x).is_equal_approx(2.5, 0.0001)
	assert_int(pool.active_count()).is_equal(1)
	shot.travel(0.3)
	assert_int(pool.active_count()).is_equal(0)
	assert_bool(shot.visible).is_false()
