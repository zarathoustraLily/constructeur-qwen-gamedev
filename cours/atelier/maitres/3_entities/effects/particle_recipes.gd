class_name ParticleRecipes extends RefCounted
## Les gerbes de particules du jeu, construites en code : un ParticleProcessMaterial (direction, cône, vitesse,
## gravité, taille au fil de la vie, couleur au fil de la vie) et le GPUParticles3D qui l'émet une fois.


## Le dégradé de couleur d'une particule au fil de sa vie, de `colors[0]` (naissance) à la dernière couleur (mort),
## à intervalles égaux.
static func color_ramp(colors: PackedColorArray) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	var offsets: PackedFloat32Array = PackedFloat32Array()
	for i: int in colors.size():
		offsets.append(float(i) / float(maxi(colors.size() - 1, 1)))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture: GradientTexture1D = GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## La taille d'une particule au fil de sa vie : pleine à la naissance, nulle à la mort (elle rétrécit).
static func shrink_curve() -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture: CurveTexture = CurveTexture.new()
	texture.curve = curve
	return texture


## Le matériau des étincelles : projetées vers le haut dans un cône, à une vitesse tirée entre les deux bornes,
## retombant sous la gravité, rétrécissant et fondant au fil de leur vie.
static func sparks_material(settings: VfxSettings) -> ParticleProcessMaterial:
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = settings.spark_spread
	material.initial_velocity_min = settings.spark_speed.x
	material.initial_velocity_max = settings.spark_speed.y
	material.gravity = Vector3(0.0, -9.8, 0.0)
	material.scale_curve = shrink_curve()
	material.color_ramp = color_ramp(settings.spark_colors)
	return material


## Le matériau de la poussière : elle s'étale sur le sol (direction horizontale, cône complet), lentement, sans
## gravité, et monte un peu.
static func dust_material() -> ParticleProcessMaterial:
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 180.0
	material.flatness = 1.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.5
	material.gravity = Vector3(0.0, 0.4, 0.0)
	material.damping_min = 1.0
	material.damping_max = 2.0
	material.scale_curve = shrink_curve()
	return material


## Un émetteur qui lâche `amount` particules d'un coup (one_shot, explosiveness 1) avec le matériau `material`,
## chacune vivant `lifetime` secondes. Il n'émet pas encore : `emitting` reste faux jusqu'à ce qu'on le lance.
static func burst(material: ParticleProcessMaterial, amount: int, lifetime: float) -> GPUParticles3D:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.process_material = material
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = false
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	particles.draw_pass_1 = quad
	return particles
