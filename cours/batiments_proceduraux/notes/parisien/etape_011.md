# Paris · étape 011 · La graine : un immeuble différent à chaque tirage

**Piste : Variation.** L'immeuble sait tout faire, mais c'est toujours le même. On lui donne
une variable de plus, `variation_seed`, et on lui apprend à tirer au sort ce qu'on ne lui
impose pas. Une même graine redonne toujours le même immeuble.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour voir l'effet, ouvrir `{NAME}.tscn` et
changer `variation_seed` : la porte, les garde-corps, les lucarnes, les boutiques et les pièces
derrière les fenêtres changent.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Cinq fichiers modifiés : l'immeuble, les
matériaux et trois shaders.

## Ce qu'on a fait, dans l'ordre

### 1. Une graine, et un ordre fixe

```gdscript
@export var variation_seed: int = 0
...
_random.seed = hash(variation_seed)    # au début de rebuild()
```

Un générateur de nombres aléatoires n'a rien d'aléatoire : il déroule une suite qui ne dépend
que de sa graine. Deux conditions pour qu'une graine donne toujours le même immeuble :

- fixer la graine au début de chaque construction ;
- **tirer toujours dans le même ordre**.

### 2. « Selon la graine » : laisser le choix au hasard, ou l'imposer

Les listes de l'inspecteur gagnent une première ligne :

```gdscript
@export_enum("Selon la graine", "Barreaux", "Volutes", "Croisillons") var railing_motif: int = 0
```

À 0, le motif est tiré au sort. Sinon, il est imposé. La fonction qui décide tient en deux
lignes, et la première est la plus importante :

```gdscript
func _pick(choice: int, count: int) -> int:
	var drawn: int = _random.randi_range(1, count)
	return choice if choice > 0 else drawn
```

**Le dé est lancé dans les deux cas**, même quand son résultat ne sert pas. Si on ne le lançait
que pour les choix laissés libres, imposer le motif des garde-corps décalerait tous les
tirages suivants : les lucarnes et les boutiques changeraient aussi. Ici, fixer un choix ne
touche à rien d'autre.

Trois variables fonctionnent ainsi : `door_style`, `railing_motif`, `dormer_style`. Les
lucarnes gagnent une option, « Alternée » : deux formes différentes, une travée sur deux.

### 3. Un dé à part pour ce qu'on ajoute après coup

La luminosité du zinc varie un peu d'un immeuble à l'autre. Ce tirage a été ajouté tard. S'il
passait par le dé de l'immeuble, il décalerait tout ce qui est tiré après lui, et toutes les
graines déjà choisies donneraient un autre immeuble. Il a donc son propre générateur :

```gdscript
var zinc_random: RandomNumberGenerator = RandomNumberGenerator.new()
zinc_random.seed = hash([variation_seed, "zinc"])
```

La graine est le hachage d'un tableau : la graine de l'immeuble, plus un mot. Autant de dés
indépendants qu'on veut, tous commandés par la même variable.

### 4. La graine descend dans les shaders

Deux immeubles voisins sortis du même script avaient les mêmes pierres aux mêmes endroits.
Le script des matériaux tire de la graine un décalage du motif :

```gdscript
var offset: Vector2 = Vector2(float(variation_seed) * 1.37, float(variation_seed) * 0.61)
```

et le donne aux shaders de la pierre et du zinc, qui l'ajoutent à leurs coordonnées :

```glsl
float u = dot(v_pos, t) + pattern_offset.x;
float v = dot(v_pos, b) + pattern_offset.y;
```

Tout le motif glisse. Les fenêtres reçoivent la graine telle quelle (`seed`) : elle entre dans
la clé de tirage des pièces.

### 5. Des pièces qui ne se ressemblent pas

Le shader de fenêtre s'enrichit, et tout ce qu'il ajoute est tiré par fenêtre :

- sur le mur du fond, une cheminée et son miroir, ou une porte à deux vantaux ;
- sur les murs latéraux, un tableau, à une place et d'une taille tirées ;
- au sol, un parquet en point de Hongrie et parfois un tapis ;
- au plafond, une rosace autour du lustre.

Tout est fait de la même brique, `rect()` : le masque d'un rectangle à bords adoucis. Une
cheminée, c'est trois rectangles.

Le vitrage aussi : chaque carreau est posé un peu de travers (`pane_tilt`), le verre ancien
ondule (`waviness`), la saleté s'accumule dans les angles (`dirt`). La normale du verre n'est
plus tout à fait celle du rectangle, et chaque carreau reflète un morceau de ciel différent.

Les boutiques et les combles ont des pièces nues : `furnished` à `false`.

### 6. Ce que la graine ne décide pas

La teinte de la pierre, le nombre d'étages, la largeur : ce sont des variables, pas des
tirages. La graine ne décide que de ce qu'on lui laisse. C'est la rue, à l'étape suivante, qui
tirera ces variables-là, une fois par immeuble.

## Ce qu'il faut retenir

1. Hasard reproductible : une graine fixée au début, des tirages toujours dans le même ordre.
2. Lancer le dé même quand on n'en a pas besoin : un choix imposé ne décale rien.
3. Un dé à part, à la graine dérivée, pour tout tirage ajouté après coup.
4. La même graine alimente les scripts et les shaders.

## À essayer

- `variation_seed` de 0 à 10.
- `railing_motif` sur « Volutes » : seuls les garde-corps changent. Le reste de l'immeuble est
  le même qu'avant.
- `dormer_style` sur « Alternée ».
- Dans `_pick()`, ne lancer le dé que si `choice` vaut 0, puis refaire l'essai précédent : tout
  l'immeuble change.
- N pour la nuit, de près : les pièces meublées.
{TWIN}
## Étape suivante

012 : la rue. Un second générateur, qui se sert de l'immeuble comme d'une brique.
