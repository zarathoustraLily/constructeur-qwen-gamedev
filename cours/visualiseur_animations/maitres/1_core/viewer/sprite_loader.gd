class_name SpriteLoader extends RefCounted
## Lit une animation 2D à l'exécution, sans l'import de Godot, sous ses deux formes :
## - un atlas de l'optimiseur de l'éditeur de cartes (format « atlas_animation », version 1) : des pages, et pour
##   chaque image sa zone dans la page, son coin dans le cadre et sa taille d'origine ;
## - un dossier d'images numérotées : une animation, au nom du dossier, une page par image, dans l'ordre des numéros.
## Les PNG se lisent octet par octet (FileAccess, puis Image.load_png_from_buffer) : Image.load_from_file sur un chemin
## res:// avertit que cela ne marchera pas une fois le projet exporté.

## Le format attendu d'un atlas.
const ATLAS_FORMAT: String = "atlas_animation"
## La version attendue d'un atlas.
const ATLAS_VERSION: int = 1


## Les animations de l'atlas `path`, ou son erreur.
static func load_atlas(path: String) -> SpriteSet:
	var sprites: SpriteSet = SpriteSet.new()
	if not FileAccess.file_exists(path):
		sprites.error = "atlas introuvable : " + path
		return sprites
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not JsonValues.is_object(json.data):
		sprites.error = "atlas illisible (JSON) : " + path
		return sprites
	var data: Dictionary[String, Variant] = JsonValues.object(json.data)
	if data.get("format", "") != ATLAS_FORMAT or int(data.get("version", 0)) != ATLAS_VERSION:
		sprites.error = "pas un atlas « %s » version %d : %s" % [ATLAS_FORMAT, ATLAS_VERSION, path]
		return sprites
	sprites.blend = str(data.get("melange", "normal"))
	for page: Variant in JsonValues.list(data.get("pages", [])):
		var texture: Texture2D = _read_png(path.get_base_dir().path_join(str(page)))
		if texture == null:
			sprites.error = "page introuvable ou illisible : " + str(page)
			return sprites
		sprites.pages.append(texture)
	var animations: Dictionary[String, Variant] = JsonValues.object(data.get("animations", {}))
	for clip_name: String in animations:
		var source: Dictionary[String, Variant] = JsonValues.object(animations[clip_name])
		var animation: SpriteAnimation = SpriteAnimation.new()
		animation.name = clip_name
		animation.fps = float(source.get("ips", AssetSidecar.DEFAULT_FPS))
		animation.frame_size = _vector(source.get("cadre", [0, 0]))
		for image: Variant in JsonValues.list(source.get("images", [])):
			animation.frames.append(_frame(JsonValues.object(image), sprites.pages.size()))
		sprites.animations[animation.name] = animation
	return sprites


## L'animation du dossier d'images `folder`, à `fps` images par seconde, ou son erreur.
static func load_frames(folder: String, fps: float) -> SpriteSet:
	var sprites: SpriteSet = SpriteSet.new()
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.to_lower().get_extension() == "png":
			files.append(file)
	files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	if files.is_empty():
		sprites.error = "aucune image dans " + folder
		return sprites
	var animation: SpriteAnimation = SpriteAnimation.new()
	animation.name = folder.get_file()
	animation.fps = fps
	for file: String in files:
		var texture: Texture2D = _read_png(folder.path_join(file))
		if texture == null:
			sprites.error = "image illisible : " + file
			return sprites
		var frame: SpriteFrame = SpriteFrame.new()
		frame.page = sprites.pages.size()
		frame.region = Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
		frame.size = frame.region.size
		sprites.pages.append(texture)
		animation.frames.append(frame)
		animation.frame_size = animation.frame_size.max(frame.size)
	sprites.animations[animation.name] = animation
	return sprites


static func _read_png(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func _frame(image: Dictionary[String, Variant], page_count: int) -> SpriteFrame:
	var frame: SpriteFrame = SpriteFrame.new()
	var zone_value: Variant = image.get("zone", [])
	frame.page = int(image.get("page", -1))
	var zone: Array[Variant] = JsonValues.list(zone_value)
	if frame.page >= page_count or zone.size() != 4:
		frame.page = -1
		return frame
	frame.region = Rect2i(int(zone[0]), int(zone[1]), int(zone[2]), int(zone[3]))
	frame.offset = _vector(image.get("decalage", [0, 0]))
	# « taille » manque dans les vieux atlas : l'image n'a alors pas été réduite.
	frame.size = _vector(image.get("taille", [frame.region.size.x, frame.region.size.y]))
	return frame


static func _vector(pair: Variant) -> Vector2i:
	var values: Array[Variant] = JsonValues.list(pair)
	if values.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(values[0]), int(values[1]))
