# Tokyo · étape 010 · Devanture, rideau métallique, enseignes

**Pistes : Building et Shader.** Le rez-de-chaussée était une rangée de vitres. Il reçoit ce
qui fait vivre une rue : une boutique, avec son rideau métallique et son enseigne ; la porte
de l'immeuble ; un distributeur de boissons. Sur la façade, une enseigne en drapeau monte le
long des étages, une plaque par occupant. La nuit, tout cela s'allume.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Appuyer sur N. Deux groupes de plus dans
l'inspecteur : **Rez-de-chaussée** et **Enseignes**.

Si les enseignes affichent des carrés à la place des caractères, la machine n'a aucune police
japonaise : passer `japanese_signs` à faux, les enseignes s'écrivent alors en lettres latines.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Quatre fichiers nouveaux : `…_devanture.gd`,
`…_enseignes.gd`, `…_rideau.gdshader`, `…_enseigne.gdshader`. La palette de `5_data` s'allonge
beaucoup. Dans le script de l'immeuble, lire `_build_shop_level()` et `_build_entrance()`.

## Ce qu'on a fait, dans l'ordre

### 1. Un rez-de-chaussée à part : `_build_shop_level()`

Une devanture n'est pas une rangée de baies : c'est une seule grande ouverture. Le
rez-de-chaussée ne passe donc plus par `_build_level()` :

```gdscript
		if index == 0 and shop:
			base_y = _build_shop_level(levels[index], shutter_choice)
		else:
			base_y = _build_level(levels[index], index, base_y)
```

`_build_shop_level()` monte la structure, toujours avec des morceaux de mur : un bandeau de
80 cm en haut, sur toute la largeur ; un poteau à chaque bout ; un poteau entre la boutique
et la travée d'escalier. Puis elle confie les deux vides à d'autres : l'entrée à
`_build_entrance()`, la boutique à `ShopBuilder.build()`.

### 2. L'entrée de l'immeuble

Dans la travée d'escalier : une porte de verre du côté de la boutique, un pan de mur de
l'autre, du mur au-dessus. La porte est un rectangle instancié de plus, avec le shader de
fenêtre :

```gdscript
	_mesh.panel(door, Transform3D(Basis.IDENTITY, Vector3(door_x, 0.5 * door.y, -WINDOW_RECESS)), _materials.shop_window,
			Color(ShopBuilder.KIND_SHOP_DOOR, 0.0, 2.0, 0.0), frame_color)
```

La donnée de l'instance dit « porte », puis 2, qui veut dire « hall d'entrée ». Le dernier
argument est nouveau : c'est la **couleur de l'instance**. Ici, elle porte la teinte de la
menuiserie.

Si le pan de mur fait au moins 75 cm, un distributeur de boissons s'y adosse.

### 3. La devanture : `…_devanture.gd`

`ShopBuilder.build()` reçoit l'ouverture (de quelle abscisse à quelle abscisse, jusqu'à quelle
hauteur) et la remplit. D'abord les tirages :

```gdscript
	var entry: Array[Variant] = Palette.SHOPS[random.randi_range(0, Palette.SHOPS.size() - 1)]
	var kind: int = entry[2]
	var shop_name: String = entry[0] if japanese else entry[1]
```

Puis, selon la sorte de boutique :

- **un magasin** : une vitrine et une porte de verre. Deux rectangles instanciés ;
- **un service** : la même vitrine, couverte d'affichettes. Chaque feuille est un rectangle
  de plus ;
- **un restaurant** : un mur habillé de bois, une fenêtre en longueur, une porte, et devant
  elle trois pans de toile (le noren) et une lanterne rouge.

Dans les trois cas, un coffre sous le bandeau de mur, où s'enroule le rideau, et l'enseigne
sur le bandeau.

### 4. Le hasard entre dans le script

Le nom de la boutique, sa sorte, ses teintes : tout cela est tiré au sort. Mais un
générateur ne doit pas changer d'avis à chaque construction. Le dé est un
`RandomNumberGenerator`, et sa graine est fixée au début de `rebuild()` :

```gdscript
	_random.seed = 0
```

Même graine, mêmes tirages, dans le même ordre : même immeuble. L'étape 011 rendra cette
graine réglable.

### 5. Les données sortent du code : `5_data`

La liste des boutiques n'est pas dans le script de la devanture. Elle est dans la palette :

```gdscript
const SHOP_STORE: int = 0
const SHOP_RESTAURANT: int = 1
const SHOP_SERVICE: int = 2
```

Chaque ligne de `SHOPS` donne le nom en japonais, le même en lettres latines, et la sorte :
`["薬局", "YAKKYOKU", SHOP_STORE]`, une pharmacie. Ce sont des noms communs, pas des
marques. Ajouter une boutique, c'est ajouter une ligne : aucun script de `6_assets` à ouvrir.

La palette porte aussi les teintes (enseignes, rideaux, menuiseries, toiles), les occupants
des étages, et trois cotes de règlement, vues plus bas.

### 6. Le rideau métallique : un rectangle, une pente

Un rideau baissé est un rectangle instancié devant les vitrages. Sa hauteur est la part
baissée. Son shader, `…_rideau.gdshader`, dessine les lames :

```glsl
	float from_top = size.y - q.y;
	float slat = floor(from_top / slat_height);
	float in_slat = fract(from_top / slat_height);
	float slope = -slat_bulge * PI * cos(PI * in_slat) / slat_height * relief_fade;
```

Les lames se comptent depuis le haut : c'est de là que le rideau se déroule. Chaque lame est
bombée ; son profil est un arc, `sin()`. La pente de cet arc est sa dérivée, `cos()`, et
c'est elle qui penche la normale : le relief de l'étape 003, avec une pente qu'on sait
calculer exactement. `relief_fade` l'efface quand une lame devient plus fine que le pixel.

La teinte de la peinture vient de la couleur de l'instance. Un seul matériau sert à tous les
rideaux, de n'importe quelle couleur.

### 7. Une enseigne : trois choses superposées

Tout est dans `…_enseignes.gd` :

| Couche | Ce que c'est |
|---|---|
| Le caisson | une boîte de métal sombre |
| La face | un rectangle instancié : son shader fait le fond, le cadre, la lumière de nuit |
| Le texte | un `Label3D`, le nœud de Godot qui écrit du vrai texte dans la scène |

```gdscript
	mesh.panel(size, frame, materials.signage, Color(0.0, 0.0, seed_value, KIND_LIGHT_BOX), color)
	mesh.node(_label(text, ink_for(color), frame, size, vertical))
```

`mesh.node()` ajoute un nœud tout fait au résultat : l'outil de maillage ne sait pas écrire,
Godot si. `ink_for()` choisit l'encre : claire sur fond sombre, sombre sur fond clair.

### 8. Écrire en japonais, et de haut en bas

Le projet n'embarque aucun fichier de police. Les caractères viennent d'une police du
système :

```gdscript
		_font = SystemFont.new()
		_font.font_names = Palette.SIGN_FONTS
		_font.font_weight = 700
```

`SystemFont` prend la première police de la liste que la machine possède. La liste commence
par deux polices livrées avec Windows 11 (Yu Gothic, MS Gothic), puis celles de macOS et de
Linux.

Source : Microsoft Learn, « Windows 11 font list »,
<https://learn.microsoft.com/typography/fonts/windows_11_font_list>, lu le 12 octobre 2026.

Pour l'écriture verticale, un caractère par ligne : `_label()` insère un retour à la ligne
entre deux caractères, puis resserre les lignes (`line_spacing` négatif).

La taille se règle par `pixel_size` : un caractère de `FONT_SIZE` pixels doit mesurer tant de
mètres dans la scène.

### 9. L'enseigne en drapeau

`SignBuilder.projecting()` accroche un caisson vertical au bord de la façade, perpendiculaire
à elle. Sur chacune de ses deux faces, une plaque par occupant. Les repères des faces sont
tournés d'un quart de tour, dans un sens puis dans l'autre :

```gdscript
		for face_side: float in [-1.0, 1.0]:
			var frame: Transform3D = Transform3D(Basis(Vector3.UP, face_side * 0.5 * PI), Vector3(x + face_side * (0.5 * thickness + 0.004), plate_y, middle.z))
			_face(mesh, materials, tenant[0] if japanese else tenant[1], color, frame, plate, true)
```

Les noms sont tirés sans remise : `_shuffle()` mélange la liste, on prend les premiers.

Trois cotes viennent de la palette, et d'un règlement : une enseigne en drapeau ne dépasse
pas d'un mètre au-dessus de la voie, une enseigne murale de 30 cm, et leur point le plus bas
est à 2,50 m au moins du sol.

Source : Bureau des routes nationales de Tokyo, « 占用許可申請の詳細 »,
<https://www.ktr.mlit.go.jp/toukoku/toukoku00078.html>, lu le 11 octobre 2026. Ce sont les
règles de ce gestionnaire, pour les routes qu'il gère.

### 10. Le shader des enseignes

`…_enseigne.gdshader` reçoit deux données par rectangle : la couleur de l'instance (le
fond), et la donnée libre (la sorte d'enseigne, entre autres).

La nuit, un caisson s'éclaire de l'intérieur :

```glsl
	ALBEDO = pc_color_out(col * (1.0 - 0.6 * night * lit));
	EMISSION = pc_color_out(col) * night * lit * glow;
```

Comme la pièce derrière une vitre, il sort par `EMISSION` : sa couleur ne dépend plus de
l'éclairage de la rue. Avec `glow` au-dessus de 1, il éblouit ; en Forward+ et en Mobile, la
visite lui ajoute un halo.

Le même shader dessine la façade du distributeur : trois rangées de canettes, par deux
`floor()`, une teinte par canette, par un hachage. Rien de nouveau.

Il sait aussi écrire de faux caractères, avec `glyph()` : trois traits horizontaux et trois
verticaux, placés par un hachage. À cette étape, seules les affichettes s'en servent. On
verra pourquoi à l'étape 013.

### 11. La lanterne, et la nuit

La lanterne est faite de deux troncs de cône dos à dos. Son matériau est un
`StandardMaterial3D` ordinaire, avec une émission que `set_night()` règle :

```gdscript
	if lantern != null:
		lantern.emission_energy_multiplier = 1.4 * value
```

`set_night()` règle maintenant trois matériaux à shader (fenêtres, vitrines, enseignes) et celui-ci.

### 12. Dans le shader de fenêtre

Deux sortes de pièce de plus : `KIND_SHOP`, une vitrine aux glaces fixes entre des montants ;
`KIND_SHOP_DOOR`, une porte de verre. Et une fonction de plus, `shop_surface()` : des
rayonnages de paquets colorés, ou, pour un restaurant, des murs de bois et le menu en bandes
de papier.

La teinte de la menuiserie peut maintenant venir de l'instance :

```glsl
	vec3 frame_albedo = frame_color_from_instance ? v_tint : pc_color_in(frame_color);
```

D'où un second matériau, `shop_window` : le même shader, avec `frame_color_from_instance` à
vrai et une pièce plus profonde.

### 13. Des matériaux à la demande

Les boîtes unies (bois d'un restaurant, toile d'un noren, carrosserie d'un distributeur)
n'ont pas de couleur d'instance : il leur faut un matériau par teinte. `lacquer()` les
fabrique à la demande et les garde :

```gdscript
func lacquer(color: Color) -> StandardMaterial3D:
	if not _plain_colors.has(color):
		_plain_colors[color] = _plain(color, 0.5, 0.2)
	return _plain_colors[color]
```

Deux boîtes de la même teinte partagent le même matériau, donc le même maillage.

## Ce qu'il faut retenir

1. Une partie qui ne ressemble pas aux autres (le rez-de-chaussée) a sa propre fonction.
2. Le hasard d'un générateur est un dé à graine fixe : même graine, même résultat.
3. Les listes où le hasard tire sont des données : elles vont dans `5_data`.
4. Deux données par rectangle : la couleur de l'instance et la donnée libre. Un matériau
   pour mille variantes.
5. Ce que le moteur sait déjà faire (écrire du texte), on le lui laisse : `mesh.node()`.
6. Ce qui éclaire sort par `EMISSION`.

## À essayer

- `shutter` : « À moitié baissé », puis « Baissé ».
- `shop` à faux : un rez-de-chaussée de bureaux, avec la porte de l'immeuble.
- `japanese_signs` à faux.
- `roof_sign` à vrai. `projecting_sign` à faux.
- `core_side` : « Aucune ». La boutique prend toute la largeur.
- Dans la palette, ajouter une ligne à `SHOPS`, puis changer `_random.seed = 0` en
  `_random.seed = 3` dans `rebuild()` pour voir d'autres tirages.
- Dans le shader des enseignes : `glow` à 4, de nuit.
{TWIN}
## Étape suivante

011 : la graine. L'immeuble sait tout faire, mais c'est toujours le même : on lui donne une
variable qui change tous ses tirages à la fois.
