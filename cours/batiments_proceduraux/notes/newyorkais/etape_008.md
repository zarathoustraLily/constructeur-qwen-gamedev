# New York · étape 008 · Profils : chaperons, ailettes, marquise

**Piste : Building.** Les tours sont justes, mais leurs arêtes sont nues : un parapet s'arrête
net, le socle de pierre rejoint la brique sans transition, le mur-rideau est une surface plate.
On ajoute les profils : le chaperon qui coiffe chaque parapet, un bandeau en gradins au-dessus du
socle, les ailettes de métal de la tour de 1961, et la marquise au-dessus de l'entrée.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. S'approcher des trois tours : le haut de
chaque gradin a son chaperon, le socle de la tour de brique son bandeau ; la tour de 1961 est
rayée de haut en bas par ses ailettes ; une marquise abrite chaque entrée.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le nouveau script `…_profils.gd` ne contient que
des listes de points. Le script de la tour les pose : chercher « NOUVEAU ».

## Ce qu'on a fait, dans l'ordre

### 1. Un profil : une coupe, sur du papier millimétré

Une moulure est un contour en deux dimensions qu'on fait glisser le long d'une ligne. Le script
des profils ne dessine que ce contour : une liste de points, comme une coupe sur du papier
millimétré. C'est l'outil de maillage qui en fait un volume :

```gdscript
func extrude(profile: PackedVector2Array, frame: Transform3D, length: float, material: Material, caps: bool = true) -> void:
```

Le profil est donné dans le plan XY du repère `frame`, et extrudé sur `length` le long de son
axe Z. Les deux bouts sont fermés par des polygones.

La convention des profils de la tour : `x` est la saillie vers le dehors, 0 au nu du mur ou du
verre ; `y` est la hauteur pour une moulure horizontale, la largeur pour une ailette verticale.

### 2. Le chaperon

La pierre plate (ou la tôle) qui coiffe un parapet. Elle déborde de chaque côté, avec une goutte
d'eau dessous, une petite entaille pour que la pluie tombe loin du mur ; son dessus penche vers le
toit.

```gdscript
static func coping(thickness: float, overhang: float, height: float) -> PackedVector2Array:
	var back: float = -thickness - overhang
	var drip: float = minf(0.03, 0.25 * overhang)
	return PackedVector2Array([
		Vector2(overhang, -0.02), Vector2(overhang, height), Vector2(back, 0.8 * height), Vector2(back, -0.02),
		Vector2(back + drip, -0.02), Vector2(back + drip, 0.0), Vector2(overhang - drip, 0.0), Vector2(overhang - drip, -0.02),
	])
```

Huit points, dans l'ordre, en faisant le tour. Le profil reçoit ses cotes en arguments : la tour
de brique pose un chaperon de pierre de 16 cm de débord, les tours de verre un chaperon de métal
plus mince. Même profil, autres nombres.

### 3. Poser un profil le long d'une façade

```gdscript
			_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (run.x + run.y), top, 0.0)), run.y - run.x, material)
```

`along_x()` donne le repère d'une moulure qui court le long de X, sa saillie vers l'avant. Composé
avec le repère de la façade, il la fait courir le long de la façade, vers le dehors. Deux règles
de plus :

- le chaperon dépasse aux deux bouts de son débord : aux angles, les chaperons des deux façades
  se croisent et couvrent le coin ;
- là où le gradin du dessus continue la façade, il n'y a pas de parapet, donc pas de chaperon.
  `_covered_span()`, écrite à l'étape 006 pour le parapet, coupe aussi le chaperon.

Le chaperon est sur le parapet : il compte dans la hauteur du gradin. `_parapet_top()` l'ajoute,
et la marge sous l'enveloppe de 1916 passe de 70 à 55 cm. Le test le vérifie toujours.

### 4. Le bandeau en gradins

Au-dessus du socle de pierre, là où la brique commence, un bandeau marque la limite : trois
marches qui avancent chacune un peu plus que celle du dessous. Des arêtes vives, pas de courbes,
à la manière Art déco.

```gdscript
static func stepped_band(height: float, depth: float) -> PackedVector2Array:
	var step: float = height / 3.0
	return PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.4 * depth, 0.0), Vector2(0.4 * depth, step), Vector2(0.7 * depth, step),
		Vector2(0.7 * depth, 2.0 * step), Vector2(depth, 2.0 * step), Vector2(depth, height), Vector2(0.0, height),
	])
```

Il fait le tour du gradin où passe le haut du socle, sauf contre un mur mitoyen. À un angle, il
dépasse de sa saillie pour rejoindre celui de la façade voisine.

### 5. Les ailettes de la tour de 1961

La tour de verre de 1961 n'a que des profils verticaux : un profilé en T devant chaque meneau, du
pied au sommet. Son âme, mince, part du verre ; son aile, plus large, la termine.

Les meneaux sont dessinés par le shader du mur-rideau ; les ailettes sont de la géométrie, posée
par le script. Il faut qu'elles tombent au même endroit. Le script refait donc **le même calcul**
que le shader :

```gdscript
		var modules: int = maxi(1, roundi(width / module_width))
		var unit: float = width / float(modules)
```

```glsl
	float modules = max(1.0, floor(w / module_width + 0.5));
	float unit = w / modules;
```

Un nombre entier de modules remplit la façade, des deux côtés. Quand deux morceaux de code
décrivent la même chose, ils doivent faire le même calcul, et c'est au lecteur de le vérifier :
rien ne le garantit.

Une ailette est extrudée vers le haut. Son repère d'extrusion se compose à partir de celui de la
façade : `x`, la saillie vers le dehors ; `y`, la largeur le long de la façade ; `z`, l'axe
d'extrusion, vers le haut.

```gdscript
		var fin_basis: Basis = Basis(frame.basis.z, frame.basis.x, frame.basis.y)
```

La tour tout en verre n'a pas d'ailettes : son verre affleure. C'est une différence de style, et
de triangles : 2 492 pour la tour de 1961, 252 pour celle d'aujourd'hui.

### 6. La marquise

Un auvent au milieu de la façade de devant, au-dessus de l'entrée : une boîte, tenue par deux
tirants accrochés plus haut dans le mur. Bronze sur la tour de brique, métal clair sur les tours
de verre. Un tirant est une barre ronde entre deux points : un cylindre, c'est-à-dire un cône à
deux rayons égaux, tourné vers son extrémité.

```gdscript
func _rod(a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var axis: Vector3 = (b - a).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
	_mesh.cone(0.5 * (a + b), radius, radius, a.distance_to(b), material, Basis(side, axis, side.cross(axis)), 6)
```

Pour tourner le cylindre, il faut un repère dont l'axe `y` est la barre. On le fabrique avec deux
produits vectoriels : un axe de côté, perpendiculaire à la barre, puis le troisième,
perpendiculaire aux deux.

### 7. Les matériaux

Deux matériaux unis de plus : le métal des ailettes, des chaperons et de la marquise des tours de
verre, et le bronze de la marquise de brique. Le chaperon et le bandeau de la tour de brique sont
en pierre : le matériau du socle.

## Ce qu'il faut retenir

1. Un profil est une liste de points ; `extrude()` en fait un volume le long d'une ligne.
2. Un profil reçoit ses cotes en arguments : un même profil sert à plusieurs tours.
3. Un repère composé (`frame * along_x(...)`) pose une moulure le long de n'importe quelle façade.
4. Quand un script et un shader décrivent la même grille, ils doivent faire le même calcul.

## À essayer

- Dans le script de la tour, `COPING_OVERHANG` à 0,4 : un chaperon très débordant.
- `BAND_DEPTH` à 0,6 : un bandeau qui avance comme une corniche.
- `FIN_DEPTH` à 0,5 : des ailettes profondes, la tour de 1961 devient une grille de lames.
- `module_width` de la tour de 1961 à 3 : les ailettes s'espacent avec les meneaux.
- `stone_floors` à 6 : le bandeau monte avec le socle.
{TWIN}
## Étape suivante

009 : le couronnement. Une flèche, des gradins de couronne, le château d'eau de bois sur le toit,
l'écran qui cache les machines ; et la couronne de verre éclairée la nuit.
