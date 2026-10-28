extends GdUnitTestSuite
## Règles de l'arme du héros : elle tire vers le point visé ; dix tirs par seconde, images de 1/60 s comprises (huit
## tirs en 48 images) ; dix tirs d'affilée la font surchauffer, et elle ne tire plus avant d'avoir refroidi ; sans
## réserve, elle ne tire pas.

const GUN_SETTINGS := preload("res://5_data/hero/hero_gun.tres")
const HEAT_SETTINGS := preload("res://5_data/hero/hero_gun_heat.tres")
const PROJECTILE := preload("res://1_core/combat/projectile.tscn")
const DT: float = 1.0 / 60.0
const TARGET := Vector3(0.0, 0.0, -20.0)

var _gun: HeroGun
var _shots: Array[Vector3] = []


func before_test() -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var pool: ProjectilePool = ProjectilePool.new()
	pool.scene = PROJECTILE
	pool.size = 32
	world.add_child(pool)
	_gun = HeroGun.new()
	_gun.settings = GUN_SETTINGS
	var heat: HeatComponent = HeatComponent.new()
	heat.name = "Heat"
	heat.settings = HEAT_SETTINGS
	_gun.add_child(heat)
	world.add_child(_gun)
	_gun.pool = pool
	_gun.fired.connect(_on_fired)
	_shots.clear()


func _on_fired(_origin: Vector3, direction: Vector3) -> void:
	_shots.append(direction)


## Gâchette tenue `frames` images, dans l'ordre du jeu : les minuteurs passent, puis l'arme essaie de tirer.
func _hold(frames: int) -> void:
	for _i: int in frames:
		_gun.tick(DT)
		_gun.heat.tick(DT)
		_gun.pull(TARGET)


func test_elle_tire_vers_le_point_vise() -> void:
	assert_bool(_gun.pull(TARGET)).is_true()
	assert_vector(_shots[0]).is_equal_approx(Vector3.FORWARD, Vector3.ONE * 0.0001)


func test_dix_tirs_par_seconde_images_comprises() -> void:
	_hold(48)
	assert_int(_shots.size()).is_equal(8)
	assert_bool(_gun.heat.is_overheated).is_false()


func test_surchauffee_elle_ne_tire_plus_avant_d_avoir_refroidi() -> void:
	_hold(60)
	assert_int(_shots.size()).is_equal(10)
	assert_bool(_gun.heat.is_overheated).is_true()
	_hold(60)
	assert_int(_shots.size()).is_equal(10)
	_hold(90)
	assert_int(_shots.size()).is_greater(10)


func test_sans_reserve_elle_ne_tire_pas() -> void:
	_gun.pool = null
	assert_bool(_gun.pull(TARGET)).is_false()
