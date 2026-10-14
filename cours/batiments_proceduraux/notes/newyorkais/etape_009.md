# New York · étape 009 · Couronnement : flèche, château d'eau, machinerie

**Piste : Building + Shader.** Une tour se reconnaît de loin à son sommet. On couronne les trois
familles : une flèche d'acier, des gradins de pierre ou une pyramide de cuivre pour la tour de
brique, avec son château d'eau de bois sur une terrasse ; un écran de ventelles qui cache les
machines du toit de la tour de 1961 ; une couronne de verre, éclairée la nuit, pour la tour
d'aujourd'hui. Un nouveau shader dessine les quatre matières du couronnement.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Les trois tours ont leur sommet. Appuyer sur
**N** : des projecteurs éclairent la flèche par en dessous, et la couronne de verre s'allume. Dans
l'inspecteur de la tour de brique, le groupe **Couronnement** : `crown`, `water_tank`,
`crown_lights`.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Deux fichiers nouveaux : le script du couronnement
`…_couronne.gd` et son shader `…_couronne.gdshader`. Le script de la tour ne fait que les appeler.

## Ce qu'on a fait, dans l'ordre

### 1. Le couronnement a son propre script

Le sommet de la tour ne sait presque rien d'elle : un rectangle, le toit du dernier gradin, la
hauteur à laquelle il est posé, et deux cotes, la travée et l'étage. Il a donc son propre script,
dont toutes les fonctions sont `static` : on les appelle sans créer d'objet, et elles ne reçoivent
que des arguments.

```gdscript
		FAMILY_BRICK:
			peak = CrownBuilder.brick_crown(_mesh, _materials, last.rect, last.top_y, crown, bay_width, floor_height)
			if water_tank:
				_place_water_tank(tiers)
		FAMILY_GLASS_1961:
			peak = CrownBuilder.louvred_screen(_mesh, _materials, last.rect, last.top_y, floor_height)
		_:
			peak = CrownBuilder.glass_crown(_mesh, _materials, last.rect, last.top_y, GLASS_CROWN_STOREYS * floor_height)
```

Chaque fonction renvoie la hauteur de son point le plus haut : la tour en a besoin pour régler
les projecteurs. Les signatures disent ce qu'un couronnement doit savoir de la tour, et rien de
plus.

### 2. Quatre sommets pour la tour de brique

`crown` choisit le sommet de la tour de brique :

| Choix | Ce qu'on monte |
|---|---|
| Toit plat | la salle des machines des ascenseurs, une boîte de brique sous une dalle débordante |
| Gradins | trois boîtes de pierre, chacune en retrait d'une travée sur la précédente, et un mât |
| Flèche | deux gradins, puis une pyramide d'acier très haute et une aiguille |
| Pyramide de cuivre | une pyramide sur tout le toit, un peu plus raide que 45 degrés |

Les gradins de couronne reprennent l'idée des gradins de la tour, en plus petit :

```gdscript
	for index: int in range(steps):
		step = step.grow(-unit)
		if step.size.x < 2.0 * unit or step.size.y < 2.0 * unit:
			break
		var height: float = 1.2 * storey
		_slab(mesh, step, y, y + height, materials.stone)
		_slab(mesh, step.grow(0.12), y + height, y + height + 0.15, materials.stone)
		y += height + 0.15
```

`Rect2.grow(-unit)` rentre le rectangle d'une travée de chaque côté. Si le toit est trop petit, la
boucle s'arrête d'elle-même.

### 3. Une pyramide : quatre triangles

```gdscript
	for index: int in range(4):
		var a: Vector3 = corners[index]
		var b: Vector3 = corners[(index + 1) % 4]
		var normal: Vector3 = (b - a).cross(apex - a).normalized()
		mesh.triangle(a, b, apex, normal, normal, normal, material)
```

Chaque face monte d'un côté de la base vers la pointe. Sa normale est le produit vectoriel de deux
de ses côtés : elle regarde vers le dehors et vers le haut. On revient ici au triangle de l'étape
001 : l'outil de maillage n'a pas de fonction « pyramide », et n'en a pas besoin.

### 4. Le château d'eau

Une cuve de bois cerclée d'acier, sous un toit conique, sur un pied de quatre poteaux et une
plateforme : le château d'eau des toits de New York. Un cylindre est un tronc de cône à deux
rayons égaux ; le toit, un tronc de cône presque pointu.

Où le poser ? Sur la terrasse la plus large que la tour laisse autour d'elle, au milieu de cette
bande de terrasse. `_place_water_tank()` mesure la terrasse de chaque côté de la tour, garde la
plus large, et ne pose la cuve que si elle a au moins 7 m (`TANK_TERRACE`). Sans terrasse assez
large, il va sur le toit de la tour, s'il est plat ; sinon, il n'y en a pas.

### 5. La machinerie de la tour de 1961

Le toit d'une tour de verre porte ses machines. On ne les dessine pas : on les cache derrière un
écran de ventelles, une boîte en retrait du bord du toit, haute de deux étages.

### 6. La couronne de verre de la tour d'aujourd'hui

Le verre continue au-dessus du dernier étage, sur trois étages de haut, sans planchers derrière
lui. Ce sont quatre rectangles de plus, dessinés par le shader du mur-rideau, en **mode
couronne** :

```gdscript
	crown_glass = curtain.duplicate() as ShaderMaterial
	crown_glass.set_shader_parameter("crown", true)
```

`duplicate()` copie le matériau du mur-rideau avec tous ses réglages ; un seul change. Dans le
shader, en mode couronne, il n'y a plus d'étages ni de bureaux : du verre entre les meneaux, et
derrière lui la charpente d'acier qui le tient, des croix de Saint-André.

```glsl
		vec2 cell = vec2(xl / unit, fract(q.y / unit));
		float brace = min(abs(cell.x - cell.y), abs(cell.x + cell.y - 1.0)) * unit;
		float strut = 1.0 - smoothstep(0.03, 0.03 + 1.5 * footprint, brace);
```

Dans chaque case carrée d'un module de côté, la distance aux deux diagonales. La nuit, des
projecteurs posés en bas l'éclairent, de moins en moins en montant.

### 7. Un shader, quatre matières

Le cuivre, l'acier, les ventelles et le bois du château d'eau sortent d'un même shader :
l'uniforme `finish` choisit la matière, et le script des matériaux en fait quatre jeux de nombres.

```gdscript
	copper = _shader_material(CROWN_SHADER, {"finish": FINISH_COPPER, "base_color": Color(0.70, 0.42, 0.22), "pitch": 0.45})
	steel = _shader_material(CROWN_SHADER, {"finish": FINISH_STEEL, "base_color": Color(0.76, 0.77, 0.79), "pitch": 0.3})
	louvres = _shader_material(CROWN_SHADER, {"finish": FINISH_LOUVRES, "base_color": metal_color, "pitch": 0.15})
	tank_wood = _shader_material(CROWN_SHADER, {"finish": FINISH_WOOD, "base_color": Color(0.46, 0.39, 0.31), "pitch": 0.12})
```

Le test sur `finish` porte sur un uniforme, pas sur le pixel : tous les pixels d'un matériau
prennent la même branche, et la carte graphique ne paie que celle-là.

- **le cuivre** : des bandes de tôle à joints debout, une ligne en relief tous les 45 cm. Et le
  vert-de-gris, la patine verte que le cuivre prend à l'air : un bruit étiré vers le bas, plus
  fort sous les joints, où l'eau coule, seuillé en plaques ;
- **l'acier** : des côtes verticales en dents de scie très douces, qui accrochent la lumière ;
- **les ventelles** : une lame inclinée tous les 15 cm, claire en haut, l'interstice sombre
  dessous ;
- **le bois** : des douelles verticales, serrées par des cerclages d'acier.

### 8. Compter les douelles sans connaître le centre de la cuve

La cuve est un cylindre à vingt facettes. Le shader ne sait pas où est son centre ; mais les
normales des facettes rayonnent autour de l'axe. Leur angle donne la position sur le tour de la
cuve, et donc le numéro de la douelle :

```glsl
		float angle = atan(n.z, n.x);
		float around = angle * tank_radius / pitch;
		float stave = floor(around);
```

L'angle fois le rayon, c'est une longueur sur le tour de la cuve ; divisée par la largeur d'une
douelle, `floor()` en fait un numéro. Les cerclages, eux, se resserrent vers le bas, là où l'eau
pousse le plus fort :

```glsl
		float hoop_pitch = mix(0.3, 0.55, clamp(y / 5.0, 0.0, 1.0));
```

C'est pour cela que le script donne au shader la hauteur du fond de la cuve (`set_tank_base()`).

### 9. Les projecteurs, la nuit

```glsl
	float rise = clamp((v_pos.y - flood_base) / flood_reach, 0.0, 1.0);
	float flood = flood_energy * night * (1.0 - 0.75 * rise);
	EMISSION = pc_color_out(col * pc_color_in(flood_color) * flood);
```

Il n'y a pas de lumière dans la scène : le cuivre et l'acier s'éclairent eux-mêmes, d'une lumière
qui faiblit en montant, comme sous des projecteurs posés au pied du couronnement. La tour dit au
shader où commence le couronnement et jusqu'où il monte. `crown_lights` les éteint.

## Ce qu'il faut retenir

1. Une partie de l'objet qui sait peu de choses du reste a son propre script, `static`, qui ne
   reçoit que des arguments.
2. Une forme simple s'écrit en triangles : une pyramide, quatre triangles et quatre normales.
3. Un matériau dupliqué garde ses réglages : un seul uniforme change le mode.
4. Un shader peut porter plusieurs matières, aiguillées par un uniforme.
5. Les normales d'un objet rond disent où l'on est sur son tour.

## À essayer

- `crown` : les quatre sommets, l'un après l'autre.
- `water_tank` : avec et sans.
- N, puis `crown_lights` à faux.
- Dans le shader du couronnement, la valeur par défaut de `patina` à 0 (cuivre neuf), puis à 1,
  avec la pyramide de cuivre.
- Dans le script de la tour, `GLASS_CROWN_STOREYS` à 8 : une couronne de verre très haute.
{TWIN}
## Étape suivante

010 : le rez-de-chaussée. Le hall et ses portes tambour, le numéro de la tour, et des boutiques
tout autour, avec leurs enseignes.
