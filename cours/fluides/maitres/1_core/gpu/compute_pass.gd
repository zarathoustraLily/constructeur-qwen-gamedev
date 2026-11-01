class_name ComputePass extends RefCounted
## Un shader de calcul prêt à tourner. Godot importe un `.glsl` en `RDShaderFile` : ce n'est encore qu'une ressource. Son SPIR-V
## devient un shader de la carte, puis un pipeline ; chaque lancement y attache ses données et dit combien de groupes tourner.
#@ 12+

## Le côté des groupes des shaders de grille : `layout(local_size_x = 8, local_size_y = 8)`.
const GRID_GROUP := 8
#@ all

var _device: ComputeDevice
var _shader: RID
var _pipeline: RID


func _init(device: ComputeDevice, path: String) -> void:
	_device = device
	var spirv: RDShaderSPIRV = (load(path) as RDShaderFile).get_spirv()
	if not spirv.compile_error_compute.is_empty():
		push_error("%s : %s" % [path, spirv.compile_error_compute])
		return
	_shader = device.keep(device.rd.shader_create_from_spirv(spirv))
	_pipeline = device.keep(device.rd.compute_pipeline_create(_shader))


## Vrai si le shader a compilé.
func is_ready() -> bool:
	return _pipeline.is_valid()


## Le nombre de groupes de `group_size` invocations qu'il faut pour couvrir `count` éléments.
static func groups_for(count: int, group_size: int) -> int:
	return ceili(float(count) / group_size)
#@ 12+


## Les groupes qui couvrent une grille de `width` × `height` cases.
static func grid_groups(width: int, height: int) -> Vector3i:
	return Vector3i(groups_for(width, GRID_GROUP), groups_for(height, GRID_GROUP), 1)
#@ all


## Lance `groups` groupes sur les données `resources`, dans l'ordre des `binding` du shader. `constants` doit faire exactement la
## taille du bloc déclaré par le shader : Godot refuse tout autre nombre d'octets.
func run(resources: Array[RID], constants: PackedFloat32Array, groups: Vector3i) -> void:
	var rd: RenderingDevice = _device.rd
	var uniform_set: RID = rd.uniform_set_create(_uniforms(resources), _shader, 0)
	var list: int = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, _pipeline)
	rd.compute_list_bind_uniform_set(list, uniform_set, 0)
	var bytes: PackedByteArray = constants.to_byte_array()
	if not bytes.is_empty():
		rd.compute_list_set_push_constant(list, bytes, bytes.size())
	rd.compute_list_dispatch(list, groups.x, groups.y, groups.z)
	rd.compute_list_end()
	rd.free_rid(uniform_set)


## Une entrée de jeu d'uniformes par donnée, numérotée dans l'ordre.
func _uniforms(resources: Array[RID]) -> Array[RDUniform]:
	var uniforms: Array[RDUniform] = []
	for i: int in resources.size():
		var uniform: RDUniform = RDUniform.new()
#@ 11
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
#@ 12+
		var image: bool = _device.rd.texture_is_valid(resources[i])
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE if image else RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
#@ all
		uniform.binding = i
		uniform.add_id(resources[i])
		uniforms.append(uniform)
	return uniforms
