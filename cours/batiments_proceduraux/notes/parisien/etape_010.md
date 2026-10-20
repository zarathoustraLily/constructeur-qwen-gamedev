# Paris · étape 010 · Porte, boutiques, enseignes

**Pistes : Building et Shader.** Le rez-de-chaussée était une rangée de fenêtres. Il reçoit ce
qui fait une rue : une porte d'entrée, des boutiques avec leurs enseignes et leurs stores.
Deux scripts, deux shaders, et le premier fichier de `5_data`.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` : un groupe « Rez-de-chaussée », et `door_color` dans « Aspect ».

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Cinq fichiers nouveaux : la porte, la
boutique, la palette, le shader du bois et celui des stores.

## Ce qu'on a fait, dans l'ordre

### 1. Trois sortes de baies au rez-de-chaussée

Dans `_build_level()`, chaque travée du rez-de-chaussée est maintenant une porte, une boutique
ou une fenêtre :

```gdscript
var is_door: bool = index == 0 and bay == door_bay
var is_shop: bool = index == 0 and shops and not is_door
```

Le mur autour du trou se construit de la même façon dans les trois cas : seule la taille du
trou change. La porte a la sienne et n'a pas d'allège.

Ce qui remplit le trou est délégué :

```gdscript
if is_door:
	DoorBuilder.build(_mesh, _materials, door_choice, x, base_y, size.x, size.y, ...)
elif is_shop:
	shop_bays.append(x)      # on note l'abscisse ; les boutiques sont montées après la boucle
else:
	_mesh.panel(...)         # une fenêtre, comme avant
```

Les boutiques ne sont pas montées dans la boucle parce qu'une boutique peut occuper deux
travées : il faut les connaître toutes avant de les regrouper.

### 2. La porte : `…_porte.gd`

Trois formes : rectangulaire à imposte, plein cintre, anse de panier. Deux outils nouveaux de
`MeshBuilder` :

- `arch_wall()` : le mur redescend jusqu'à l'arc. On ne perce toujours pas : on remplit, au-dessus
  d'une demi-ellipse, le rectangle qui monte jusqu'au linteau ;
- `sweep()` : un profil balayé le long d'un arc. C'est l'extrusion de l'étape 008, sur une
  ligne courbe : l'archivolte est le chambranle, plié.

Les vantaux sont des boîtes ; leurs panneaux moulurés, de petites boîtes en relief. Le bouton
est un cône de laiton. L'imposte est vitrée et grillée : la grille est un rectangle qui porte
le shader de ferronnerie de l'étape 007, auquel on a ajouté un quatrième motif, l'éventail.

### 3. Les boutiques : `…_boutique.gd`

Deux sortes :

- **la devanture de bois en applique** : un bandeau d'enseigne, des pilastres devant les
  trumeaux, une vitrine sur soubassement, une porte vitrée, parfois un store ;
- **la vitrine pleine surface** : une glace du seuil au linteau, un cadre de métal fin, la
  pierre laissée nue autour.

`ShopBuilder.build()` fait trois choses avant de monter quoi que ce soit :

1. il regroupe les travées en boutiques d'une ou deux travées ;
2. il mélange la liste des noms et les distribue : pas deux fois la même enseigne ;
3. il désigne les boutiques à vitrine pleine surface. `showcase_share` est un minimum dès
   qu'il y a deux boutiques.

### 4. Le hasard entre dans le script

Les boutiques tirent au sort leurs noms, leurs teintes, leur regroupement. L'immeuble a donc
un générateur de nombres aléatoires, et lui donne toujours la même graine :

```gdscript
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
...
_random.seed = 0     # au début de rebuild()
```

Sans cette ligne, l'immeuble changerait de boutiques à chaque reconstruction, c'est-à-dire à
chaque variable touchée dans l'inspecteur. Avec elle, les mêmes variables donnent le même
immeuble. L'étape 011 rendra cette graine réglable.

### 5. Les données sortent du code : `5_data`

Les noms d'enseigne et les teintes ne sont pas dans le script de la boutique. Ils sont dans
`5_data/DECORS/Building/…_palette.gd`, un fichier qui ne contient que des constantes :

```gdscript
const SHOP_NAMES: PackedStringArray = ["BOULANGERIE", "CAFÉ", "LIBRAIRIE", ...]
const SHOP_WOOD_COLORS: Array[Color] = [Color(0.07, 0.20, 0.14), ...]
```

Le script les lit par `Palette.SHOP_NAMES`. Ajouter une boutique à la liste ne demande pas
d'ouvrir un script de `6_assets`.

### 6. Les enseignes : un nœud tout fait

Une enseigne est un `Label3D`, un nœud de Godot qui affiche du texte dans l'espace. L'outil de
maillage sait aussi transporter un nœud tout fait : `mesh.node(label)`. Il sera ajouté sous le
nœud interne avec le reste.

`_sign()` règle la taille des lettres pour que le nom tienne dans la largeur du bandeau.

### 7. La teinte par instance

Chaque boutique a sa couleur de bois, mais toutes les vitrines partagent un seul matériau. La
teinte de la menuiserie voyage avec l'instance, par le cinquième argument de `panel()` :

```gdscript
mesh.panel(glass, Transform3D(...), materials.shop_window, Color(0.0, 0.0, 0.0, 0.0), color)
```

Dans le shader de fenêtre, elle arrive par `COLOR` :

```glsl
vec3 frame_albedo = frame_color_from_instance ? v_tint : pc_color_in(frame_color);
```

Après la forme à l'étape 009, c'est la seconde donnée par instance.

### 8. Les matériaux à la demande

Le bois peint de chaque boutique a sa teinte, et on ne sait pas d'avance lesquelles seront
tirées. Le script des matériaux les fabrique à la demande et les garde :

```gdscript
func painted_wood(color: Color) -> ShaderMaterial:
	if not _painted_wood.has(color):
		_painted_wood[color] = _shader_material(WOOD_SHADER, {...})
	return _painted_wood[color]
```

Deux boutiques vertes partagent le même matériau, donc le même maillage.

### 9. Le shader du bois : un motif en volume

Jusqu'ici, les motifs étaient plaqués sur une face. Le bois est calculé **en volume** : le fil
suit un axe, et les cernes sont des cylindres autour du cœur de l'arbre. Une face coupée dans
le sens du fil montre des veines, une face en bout montre des cernes, sans rien régler. Il lui
faut un bruit à trois dimensions : `pc_noise3` et `pc_fbm3`, partie « ÉTAPE 010 » du fichier
commun.

L'immeuble s'en sert peint (`paint` à 1) : il en reste le relief des coups de pinceau.

### 10. Le shader des stores

Le plus court du projet, quarante lignes : des rayures par une onde triangulaire, un tissage
par un bruit fin, une décoloration par un bruit large. Il est vu des deux côtés
(`cull_disabled`) : la toile n'a pas d'épaisseur.

## Ce qu'il faut retenir

1. Un script par objet : la porte et la boutique ont le leur, comme le toit.
2. Le hasard d'un générateur procédural repart toujours de la même graine.
3. Les listes sont des données : elles vivent dans `5_data`.
4. Une donnée par instance (forme, teinte) vaut mieux qu'un matériau par variante.

## À essayer

- `door_bay` de 0 à 4, puis -1 : pas de porte.
- `door_style` : les trois formes.
- `shops` décoché : le rez-de-chaussée de l'étape 009, avec une porte.
- `showcase_share` à 0, puis à 1.
- Dans la palette : ajouter un nom à `SHOP_NAMES`, une teinte à `SHOP_WOOD_COLORS`.
- Dans `rebuild()` : `_random.seed = 1`. D'autres boutiques.
{TWIN}
## Étape suivante

011 : la graine devient une variable. Un même script, un immeuble différent à chaque tirage.
