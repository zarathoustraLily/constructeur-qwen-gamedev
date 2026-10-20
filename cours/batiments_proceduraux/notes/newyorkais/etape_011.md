# New York · étape 011 · La graine : une tour différente à chaque tirage

**Piste : Variation.** Jusqu'ici, la tour faisait ce que disaient ses variables. On laisse
maintenant une partie des choix au hasard, mais un hasard **maîtrisé** : un seul nombre, la
graine, décide de tout ce qu'on lui confie. La même graine redonne toujours la même tour ; une
autre graine, une autre tour. Famille, couronnement, petits bois, proportions, teintes, pièces
derrière les vitres, boutiques : tout peut venir de la graine.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. La visite montre quatre tours côte à côte :
la même scène, quatre fois, avec tout laissé au hasard, sous quatre graines. Dans l'inspecteur de
la tour, le groupe **Graine** : `variation_seed`, `window_lights`, `random_massing`,
`random_colors`. Les listes `family_choice` et `crown_choice` commencent par « Selon la graine ».

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le cœur de l'étape est la fonction `_resolve()`,
à la fin du script de la tour.

## Ce qu'on a fait, dans l'ordre

### 1. Ce que demande l'inspecteur, ce que la tour retient

Une variable comme `family` avait une seule valeur : celle de l'inspecteur. Il en faut maintenant
deux : ce que l'inspecteur demande (peut-être « Selon la graine »), et ce que la tour retient
après le tirage.

```gdscript
@export_enum("Selon la graine", "Brique (1916)", "Verre et allèges (1961)", "Tout en verre (aujourd'hui)") var family_choice: int = 1
```

La variable exportée devient `family_choice`, et sa liste gagne une première ligne, « Selon la
graine ». Le choix retenu garde l'ancien nom, `family`, mais n'est plus exporté : tout le reste
du script le lit sans changer une ligne. Même chose pour le couronnement (`crown_choice` et
`crown`), et pour les proportions et les teintes : `_tower_share`, `_floor_count`,
`_brick_color`… sont les valeurs retenues.

### 2. `_resolve()` : tous les choix, dans un ordre fixe

```gdscript
func _resolve() -> void:
	var dice: RandomNumberGenerator = RandomNumberGenerator.new()
	dice.seed = hash(variation_seed)
```

Un `RandomNumberGenerator` est un dé : à partir d'une graine, il tire une suite de nombres,
toujours la même pour la même graine. `_resolve()` crée son propre dé, à chaque appel, et tire
**toujours dans le même ordre** : la famille, le couronnement, les petits bois, les proportions,
les teintes.

```gdscript
	var roll: float = dice.randf()
	var drawn: int = FAMILY_BRICK if roll < 0.45 else (FAMILY_GLASS_1961 if roll < 0.67 else FAMILY_ALL_GLASS)
	family = drawn if family_choice == 0 else family_choice - 1
```

La famille n'est pas tirée à parts égales : la brique un peu moins d'une fois sur deux, 1961 une
fois sur cinq, le tout en verre le reste du temps. Un dé n'a pas besoin d'être équitable : il
peut être penché vers ce qu'on veut voir le plus souvent.

### 3. Lancer le dé même quand le choix est imposé

```gdscript
func _pick(dice: RandomNumberGenerator, choice: int, count: int) -> int:
	var drawn: int = dice.randi_range(1, count)
	return choice if choice > 0 else drawn
```

C'est la règle la plus importante de l'étape. Si l'on fixe le couronnement à la main, le dé est
**quand même** lancé, et son résultat jeté. Pourquoi ? Parce que les tirages suivants (les petits
bois, les proportions, les teintes) doivent rester les mêmes. Si l'on sautait un tirage, tous les
suivants glisseraient d'un cran : fixer le couronnement changerait la couleur de la brique.

Même chose pour les proportions et les teintes : elles sont toujours tirées, et gardées seulement
si `random_massing` ou `random_colors` le demandent.

```gdscript
	var setbacks: int = dice.randi_range(2, 4)
	var share: float = dice.randf_range(0.16, 0.25)
	var glass_share: float = dice.randf_range(0.25, 0.4)
	var podium: int = [0, 0, 3, 5][dice.randi_range(0, 3)]
	var floors: int = roundi(float(floor_count) * dice.randf_range(0.75, 1.25))
	_setback_bays = setbacks if random_massing else setback_bays
```

Les bornes des tirages restent dans le règlement : une tour de 1916 couvre au plus le quart du
terrain, une tour de 1961 au plus 40 %. La graine choisit une tour **parmi celles que le
règlement permet** ; c'est toujours le règlement qui la construit.

### 4. Les teintes : des listes dans `5_data`

```gdscript
const BRICK_COLORS: Array[Color] = [
	Color(0.78, 0.66, 0.50), Color(0.70, 0.55, 0.40), Color(0.62, 0.36, 0.26), Color(0.55, 0.40, 0.30), Color(0.40, 0.28, 0.22),
]
```

La graine ne tire pas une couleur au hasard dans tout le spectre : elle choisit dans une liste.
Des briques chamois, havane, rouge, brun, brun sombre ; des pierres claires, grises ou roses ; des
châssis vert sombre, noirs, blanc cassé ou bruns ; et pour les tours de verre, des jeux de trois
teintes qui vont ensemble : le verre, les allèges, le métal. Ces listes sont des données : elles
vivent dans la palette. Ce sont des teintes plausibles, choisies à l'œil.

Les petits bois aussi : un sur un, deux sur deux, six sur six, trois sur un. Chaque entrée de
`WINDOW_LIGHTS` donne les carreaux du châssis du haut, puis du bas.

### 5. Deux dés, pas un

`_resolve()` a son propre dé. Les boutiques et le numéro de la tour ont le leur, qui part de la
même graine, décalée :

```gdscript
	_random.seed = hash(variation_seed + 7919)
```

Pourquoi deux dés ? `_resolve()` est appelée à chaque fois qu'on a besoin des gradins : pour
construire, mais aussi pour mesurer le règlement (le test le fait). Si elle partageait le dé des
boutiques, chaque mesure décalerait les tirages des boutiques. Avec deux dés, la tour peut refaire
ses choix à tout moment sans rien déranger.

### 6. La graine descend jusqu'aux shaders

Deux tours de même famille, côte à côte, ne doivent pas avoir les mêmes briques aux mêmes
endroits, ni les mêmes pièces allumées. La graine entre donc dans les shaders, de deux façons :

- **un décalage des motifs** : le script en tire un déplacement, que le shader de la brique
  ajoute aux coordonnées du mur. Tout le motif glisse : les briques, les plages, la suie ;

```glsl
	float u = dot(v_pos, t) + pattern_offset.x;
	float v = dot(v_pos, b) + pattern_offset.y;
```

- **la clé des pièces** : la graine entre dans chaque hachage des pièces, derrière les fenêtres
  comme derrière le mur-rideau.

```glsl
	float r0 = pc_hash3(vec3(v_key.x, room_id, v_key.z + 17.0 + seed * 101.0));
```

### 7. Le test essaie huit graines

```gdscript
	for seed_value: int in range(1, 9):
		for property: String in ["family_choice", "crown_choice", "window_lights"]:
			subject.set(property, 0)
		subject.set("random_massing", true)
		subject.set("random_colors", true)
		subject.set("variation_seed", seed_value)
		subject.call("rebuild")
```

Tout laissé au hasard, huit graines : chaque tirage doit donner des triangles, rester sous son
règlement, sous sa part du terrain et sous son coefficient. Le test dit aussi combien de tours de
chaque famille il a vues : sur ces huit graines, quatre de brique, deux de 1961, deux tout en verre.

## Ce qu'il faut retenir

1. Une graine, un dé, des tirages toujours dans le même ordre : la même graine redonne la même
   tour.
2. Lancer le dé même quand le choix est imposé, pour ne pas décaler les tirages suivants.
3. Séparer ce que demande l'inspecteur de ce que la tour retient.
4. Le hasard choisit dans des listes et entre des bornes : il ne sort jamais du règlement.
5. Un dé par usage : ceux qu'on relance souvent ne doivent pas déranger les autres.

## À essayer

- `variation_seed` de 1 à 20, avec `family_choice` et `crown_choice` sur « Selon la graine ».
- Sans changer de graine, passer `family_choice` de « Selon la graine » à une famille fixée : la
  famille change, mais les teintes, les petits bois et les proportions tirés restent les mêmes.
- `random_massing` à faux : les proportions de l'inspecteur reviennent, la graine ne choisit plus
  que le reste.
- Dans la palette, ajouter une teinte de brique à `BRICK_COLORS`.
{TWIN}
## Étape suivante

012 : le quartier. Une avenue, des rues, des îlots de 200 pieds, une tour sur chaque terrain,
chacune avec sa graine.
