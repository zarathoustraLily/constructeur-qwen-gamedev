class_name VolumeCheck extends RefCounted
## Ce que partagent les suites des volumes. Il n'y a pas de solveur 3D sur le processeur pour les juger, mais un volume qui ne varie
## pas en profondeur doit donner, tranche par tranche, ce que donne le solveur 2D : `extruded` le fabrique, `slice` en lit une tranche.


## Les octets d'un volume de vitesse dont chaque tranche vaut (`u`, `v`), sans vitesse en profondeur.
static func velocity_of(u: FluidField, v: FluidField, depth: int) -> PackedByteArray:
	var values: PackedFloat32Array = PackedFloat32Array()
	values.resize(u.data.size() * depth * 4)
	for z: int in depth:
		for i: int in u.data.size():
			var cell: int = (z * u.data.size() + i) * 4
			values[cell] = u.data[i]
			values[cell + 1] = v.data[i]
			values[cell + 2] = 0.0
			values[cell + 3] = 0.0
	return values.to_byte_array()


## Les octets d'un volume dont chaque tranche vaut `field`.
static func scalar_of(field: FluidField, depth: int) -> PackedByteArray:
	var values: PackedFloat32Array = PackedFloat32Array()
	for _z: int in depth:
		values.append_array(field.data)
	return values.to_byte_array()


## La tranche `z` d'un volume de `channels` flottants par case, canal `channel`, comme un champ de `width` × `height`.
static func slice(device: ComputeDevice, volume: RID, width: int, height: int, z: int, channels: int, channel: int) -> FluidField:
	device.finish()
	var values: PackedFloat32Array = device.rd.texture_get_data(volume, 0).to_float32_array()
	var field: FluidField = FluidField.new(width, height)
	var first: int = z * width * height * channels
	for i: int in field.data.size():
		field.data[i] = values[first + i * channels + channel]
	return field


## Tout un volume d'un flottant par case, lu d'un coup.
static func cells_of(device: ComputeDevice, volume: RID) -> PackedFloat32Array:
	device.finish()
	return device.rd.texture_get_data(volume, 0).to_float32_array()


## Le centre de gravité d'un volume d'un flottant par case, de taille `size`.
static func center_of(data: PackedFloat32Array, size: Vector3i) -> Vector3:
	var sum: Vector3 = Vector3.ZERO
	var total: float = 0.0
	for z: int in size.z:
		for y: int in size.y:
			for x: int in size.x:
				var value: float = data[(z * size.y + y) * size.x + x]
				sum += Vector3(x, y, z) * value
				total += value
	return sum / total
