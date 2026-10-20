# Tokyo · étape 011 · La graine : un immeuble différent à chaque tirage

**Piste : Variation.** L'immeuble sait tout faire, mais c'est toujours le même. On lui donne
une graine : un seul nombre, qui change tous ses tirages à la fois. Et on laisse à cette
graine quelques grands choix, dont le plus visible : de quoi est faite la façade.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Dans l'inspecteur de l'immeuble, tout en
bas du groupe **Aspect** : `variation_seed`. Changer sa valeur, une unité à la fois.

Pour voir tout ce que la graine sait décider, mettre aussi `cladding`, `tile_format` et
`shutter` sur « Selon la graine ».

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Aucun fichier nouveau. Six fichiers
modifiés : chercher « NOUVEAU » dans chacun, les ajouts sont courts.

## Ce qu'on a fait, dans l'ordre

### 1. Une graine, et un ordre fixe

```gdscript
	_random.seed = hash(variation_seed)
```

À l'étape 010, la graine du dé valait toujours 0. Elle vient maintenant d'une variable.
`hash()` la brouille : deux graines voisines, 4 et 5, donnent des suites de tirages sans
rapport.

Une graine ne donne le même immeuble que si les tirages se font toujours **dans le même
ordre**. C'est pourquoi les grands choix sont tirés d'un bloc, au début de `rebuild()`, avant
toute géométrie.

### 2. « Selon la graine » : laisser le choix au hasard, ou l'imposer

Les listes de l'inspecteur gagnent une première ligne :

```gdscript
@export_enum("Selon la graine", "Barreaux", "Muret plein", "Panneaux translucides") var railing_style: int = 0
```

À 0, la graine choisit. Sinon, on impose. Une petite fonction fait les deux :

```gdscript
func _pick(choice: int, count: int) -> int:
	var drawn: int = _random.randi_range(1, count)
	return choice if choice > 0 else drawn
```

Le dé est lancé **dans les deux cas**. Si on ne le lançait que quand la graine choisit,
imposer un garde-corps décalerait tous les tirages suivants : la boutique changerait de nom
parce qu'on a changé de garde-corps.

Cinq choix passent par `_pick()` : la travée d'escalier, le garde-corps, le rideau de la
boutique, le revêtement, le format des carreaux.

```gdscript
	_core_choice = _pick(core_side, 3)
	_railing_choice = _pick(railing_style, 3)
	var shutter_choice: int = _pick(shutter, 3)
	var cladding_choice: int = _pick(cladding, 3)
	var format_choice: int = _pick(tile_format, Palette.TILE_FORMATS.size())
```

### 3. Pencher le dé

Trois revêtements, mais pas à parts égales : dans une rue, le carrelage domine.

```gdscript
	var favour_tile: bool = _random.randf() < 0.5
	if cladding == 0 and favour_tile:
		cladding_choice = 1
```

Un tirage sur trois donne déjà le carrelage ; la moitié des autres y est ramenée : deux
façades sur trois sont carrelées. Là encore, le dé est lancé même si le revêtement est
imposé.

### 4. Trois matières pour une façade

Depuis l'étape 002, le matériau du mur sur rue s'appelle `facade`. Le script de l'immeuble
ne sait pas de quoi il est fait : il écrit `_materials.facade` partout. Changer de matière ne
touche donc qu'au script des matériaux :

```gdscript
	if cladding == CLADDING_TILE:
		facade = _shader_material(TILE_SHADER, {
```

```gdscript
		var raw: bool = cladding == CLADDING_CONCRETE
		facade = _shader_material(CONCRETE_SHADER, {
			"concrete_color": Color(0.62, 0.62, 0.60) if raw else tile_color,
			"formwork": 1.0 if raw else 0.0,
```

- **le carrelage**, dans l'un des quatre formats de la palette ;
- **le béton brut** : le shader de l'étape 009, tel quel ;
- **l'enduit peint** : le même shader du béton, avec `formwork` à 0. Plus de joints, plus de
  trous d'écarteur : il reste une surface unie, ses nuages et ses coulures, à la teinte
  voulue.

Trois matières, deux shaders, aucune ligne changée dans l'immeuble.

### 5. Les formats de carreaux sont des données

```gdscript
const TILE_FORMATS: Array[Array] = [
	[Vector2(0.235, 0.068), 0.5], [Vector2(0.116, 0.068), 0.5], [Vector2(0.100, 0.050), 0.0], [Vector2(0.050, 0.050), 0.0],
]
```

Chaque ligne : la taille du carreau, joint compris, et le décalage d'un rang sur deux. Les
deux premiers formats se posent à joints croisés, les deux petits à joints alignés. Le
shader de l'étape 002 avait déjà les deux uniformes qu'il faut, `tile_size` et `stagger`.

Ces cotes sont citées de mémoire : à vérifier dans un catalogue de fabricant avant de s'y
fier.

### 6. La graine descend dans les shaders

Deux immeubles voisins, du même carrelage, ne doivent pas avoir les mêmes taches aux mêmes
endroits. Or le motif vient de la position dans l'immeuble : il serait identique. Le script
des matériaux tire donc un décalage de la graine, et le donne aux shaders des murs :

```gdscript
	var offset: Vector2 = Vector2(float(variation_seed) * 1.37, float(variation_seed) * 0.61)
```

```glsl
	float u = dot(v_pos, t) + pattern_offset.x;
	float v = dot(v_pos, b) + pattern_offset.y;
```

Tout le motif glisse. Le shader de fenêtre, lui, reçoit la graine dans son uniforme `seed`,
qui entre dans le hachage des pièces : mêmes fenêtres, autres bureaux.

### 7. Des fenêtres qui ne se ressemblent pas

Le shader de fenêtre gagne des détails tirés par fenêtre. Aucun n'est une technique
nouvelle :

| Détail | Comment |
|---|---|
| La moustiquaire | un des deux vantaux, tiré au sort, est grisé et moins brillant |
| Le verre armé | un quadrillage en losanges, visible de près seulement |
| La saleté | un bruit, plus fort dans les angles des vitres |
| Les vitres de travers | la normale de chaque vantail penche un peu : deux reflets différents |
| Les tatamis | des nattes de 90 cm sur 180, par `fract()`, avec leur galon sombre |
| Les cloisons de papier | un quadrillage de baguettes sur un fond clair, lumineux la nuit |

Le verre armé est le quadrillage de l'étape 005, tourné d'un huitième de tour :

```glsl
		vec2 diagonal = vec2(q.x + q.y, q.x - q.y) * 0.7071;
		wire = grid_lines(diagonal, vec2(0.022), 0.0006, 0.6 * footprint) * (1.0 - smoothstep(0.002, 0.008, footprint));
```

Additionner et soustraire les deux coordonnées fait tourner le repère de 45°.

### 8. Un tirage au milieu de la construction

Un balcon sur quatre a un futon qui sèche sur son garde-corps :

```gdscript
	var futon: bool = _random.randf() < 0.25
	var futon_x: float = middle + _random.randf_range(-0.25, 0.25) * span
	var futon_color: Color = Color(0.90, 0.89, 0.86).lerp(Color(0.62, 0.70, 0.80), _random.randf())
	if futon and style != RAILING_PANELS:
```

Ces tirages-là se font pendant la construction, dans `_build_balcony()`. C'est permis : les
balcons sont toujours montés dans le même ordre, de bas en haut. Les trois tirages se font à
chaque balcon, qu'il reçoive un futon ou non : le nombre de coups de dé ne doit pas dépendre
d'un coup de dé.

Mais il reste une conséquence. Ajouter un étage de logements ajoute trois tirages, et décale
ceux qui viennent après : la forme du réservoir, les plaques de l'enseigne en drapeau. La
boutique, elle, est tirée avant, avec le rez-de-chaussée : elle ne change pas. Pour rendre
ces tirages indépendants, il faudrait un dé à part pour chaque partie, comme le fera la rue.

### 9. Ce que la graine ne décide pas

Les dimensions, le nombre d'étages, la teinte du revêtement, la largeur de la voie restent
des variables. La graine ne choisit que ce qui est sans conséquence pour le reste : des
formes et des détails. C'est le rôle de l'étape suivante de tirer aussi les variables.

## Ce qu'il faut retenir

1. Une graine, un ordre fixe : même graine, même immeuble.
2. Lancer le dé même quand le choix est imposé, pour ne pas décaler les tirages suivants.
3. Un dé peut être penché.
4. Un matériau nommé d'après son rôle (`facade`) peut changer de matière sans que la
   géométrie le sache.
5. Un décalage de motif suffit à distinguer deux objets du même matériau.

## À essayer

- `variation_seed` de 0 à 10.
- `cladding` sur « Béton brut », puis « Enduit peint » avec `tile_color` à (0,80 ; 0,68 ; 0,64).
- `tile_format` sur « Mosaïque », avec un carrelage brun.
- Mettre `railing_style` sur « Muret plein », puis changer la graine : le garde-corps reste,
  tout le reste change.
- Dans `_pick()`, ne lancer le dé que si `choice` vaut 0, puis imposer un garde-corps : la
  boutique change. Remettre comme avant.
- Dans le shader de fenêtre : `wired` à 1, `screens` à 1, et s'approcher.
{TWIN}
## Étape suivante

012 : la rue. Un second script crée des dizaines d'immeubles et règle leurs variables par
des tirages. Pas de hauteur imposée : chacun bâtit ce qu'il veut, sous le gabarit oblique.
