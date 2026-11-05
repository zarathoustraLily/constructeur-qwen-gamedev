class_name BenchView
extends SubViewportContainer
## Le banc d'essai : une petite scène 3D à part (sa propre `SubViewport`, son sol, sa lumière, sa caméra), où l'on pose le
## modèle d'une définition d'animation pour jouer ses clips, voir ses transitions et lui ajouter des effets en aperçu.
## Le banc ne lit ni ne modifie jamais la salle ouverte : c'est un aperçu, rendu par Godot, pas une partie.
## Les effets sont des `CPUParticles3D` réglés d'après la définition d'effet (débit, durée de vie, taille, couleur).

## Le nom donné au nœud du modèle posé sur le banc.
const MODEL_NAME: StringName = &"Modele"

var _viewport: SubViewport = SubViewport.new()
var _stage: Node3D = Node3D.new()
var _camera: Camera3D = Camera3D.new()
var _model: Node3D
var _player: AnimationPlayer
var _definition: AnimationDef
var _effects: Array[CPUParticles3D] = []
var _motion: BenchMotion = BenchMotion.new()
var _settings: EditorSettingsDef


## Construit la scène du banc, selon les réglages (distance de la caméra, vitesse de marche).
func setup(settings: EditorSettingsDef) -> void:
	_settings = settings
	stretch = true
	_viewport.own_world_3d = true
	add_child(_viewport)
	_viewport.add_child(_stage)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2.ONE * settings.bench_floor_m
	floor_mesh.mesh = plane
	_stage.add_child(floor_mesh)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation = Vector3(-PI / 3.0, PI / 4.0, 0.0)
	_stage.add_child(light)
	_stage.add_child(_camera)
	_place_camera()


## Pose le modèle de `definition` sur le banc (à la place du précédent) et joue son clip de repos.
func show_animation(definition: AnimationDef) -> bool:
	clear_effects()
	if _model != null:
		_stage.remove_child(_model)
		_model.free()
		_model = null
		_player = null
	_definition = definition
	if definition == null or definition.model == null:
		return false
	_model = definition.model.instantiate() as Node3D
	_model.name = MODEL_NAME
	_stage.add_child(_model)
	var players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
	_player = null if players.is_empty() else players[0] as AnimationPlayer
	_motion = BenchMotion.new()
	return play_state(&"idle")


## Joue le clip de l'état `state`, à sa vitesse, avec le fondu de la définition ; rend false s'il n'y en a pas.
func play_state(state: StringName) -> bool:
	if _player == null or not _definition.clips.has(state):
		return false
	var clip: StringName = _definition.clips[state]
	if not _player.has_animation(clip):
		return false
	_player.play(clip, _definition.blend_s, _definition.speeds.get(state, 1.0))
	return true


## Le clip en cours.
func current_clip() -> StringName:
	return &"" if _player == null else StringName(_player.current_animation)


## La vitesse de lecture du clip en cours.
func current_speed() -> float:
	return 0.0 if _player == null else _player.get_playing_speed()


## Fait marcher le modèle d'un pas dans `direction` (x, z), et passe du repos à la course et inversement.
func step(direction: Vector2, delta: float) -> void:
	if _model == null:
		return
	var before: StringName = _motion.state
	_motion.step(direction, delta, _settings.bench_move_speed_mps)
	_model.position = _motion.position
	_model.rotation.y = _motion.facing
	if _motion.state != before:
		play_state(_motion.state)
	_place_camera()


## La position du modèle sur le banc.
func model_position() -> Vector3:
	return _motion.position


## Ajoute au modèle un aperçu de l'effet `effect`.
func add_effect(effect: FxDef) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.amount = EffectPreview.count(effect)
	particles.lifetime = effect.lifetime_s
	particles.scale_amount_min = effect.size_m
	particles.scale_amount_max = effect.size_m
	particles.color = effect.color
	particles.name = String(effect.id)
	(_model if _model != null else _stage).add_child(particles)
	_effects.append(particles)
	return particles


## Les effets ajoutés au banc.
func effects() -> Array[CPUParticles3D]:
	return _effects.duplicate()


## Retire tous les effets du banc.
func clear_effects() -> void:
	for particles: CPUParticles3D in _effects:
		particles.get_parent().remove_child(particles)
		particles.free()
	_effects.clear()


func _place_camera() -> void:
	var target: Vector3 = _motion.position + Vector3.UP
	_camera.position = target + Vector3(0.0, 1.0, 1.0).normalized() * _settings.bench_camera_distance_m
	if _camera.is_inside_tree():
		_camera.look_at(target)
