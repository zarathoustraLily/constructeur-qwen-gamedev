class_name FluidImage extends RefCounted
## Le passage d'un champ à une image : le code du fluide ne connaît pas l'écran, la scène montre ce qu'on lui rend.


## L'image en niveaux de gris du champ : 0 donne du noir, `brightest` et au-delà du blanc.
static func gray(field: FluidField, brightest: float) -> Image:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(field.data.size())
	for i: int in field.data.size():
		bytes[i] = clampi(roundi(field.data[i] / brightest * 255.0), 0, 255)
	return Image.create_from_data(field.width, field.height, false, Image.FORMAT_L8, bytes)
#@ 10+


## L'image en couleurs du champ : chaque case lit `ramp` à la hauteur de sa valeur, 0 à gauche, `brightest` à droite.
static func colored(field: FluidField, ramp: Gradient, brightest: float) -> Image:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(field.data.size() * 3)
	for i: int in field.data.size():
		var color: Color = ramp.sample(field.data[i] / brightest)
		bytes[i * 3] = color.r8
		bytes[i * 3 + 1] = color.g8
		bytes[i * 3 + 2] = color.b8
	return Image.create_from_data(field.width, field.height, false, Image.FORMAT_RGB8, bytes)
#@ all
