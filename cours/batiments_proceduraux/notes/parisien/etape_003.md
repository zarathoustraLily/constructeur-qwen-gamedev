# Paris · étape 003 · Le bruit : teinte par bloc, suie, relief

**Piste : Shader.** Le mur de l'étape 002 est trop parfait : tous les blocs ont la même teinte
et la même longueur, la façade est propre et plate. On y met du hasard, à trois échelles.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` et changer une variable du nœud racine : il y en a une de plus, `soot`.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Dans les trois fichiers modifiés, le code
ajouté est encadré par `>>> NOUVEAU À L'ÉTAPE 003` et `<<< FIN DU NOUVEAU`. La leçon est dans
le shader `…_pierre.gdshader`, puis dans les parties « ÉTAPE 003 » de
`procedural_commun.gdshaderinc`.

## Ce qu'on a fait, dans l'ordre

### 1. Un dé qui retombe toujours du même côté : le hachage

Un shader ne peut rien retenir d'une image à l'autre, ni d'un pixel à l'autre. Pour qu'un bloc
soit « un peu plus sombre », il faut retrouver cette information à partir de rien. La réponse
est le hachage : une fonction qui transforme un nombre en un autre, d'apparence aléatoire,
mais toujours le même pour la même entrée.

```glsl
float hb = pc_hash2(vec2(block_x, row) + vec2(31.0, 57.0));   // un tirage entre 0 et 1 pour ce bloc
float hb2 = pc_rehash(hb, 1.0);                                // un second, indépendant du premier
```

`block_x` et `row` sont les numéros du bloc, ceux que `floor()` donnait à l'étape 002. Tous
les pixels d'un même bloc obtiennent donc le même `hb`.

Les fonctions `pc_hash1`, `pc_hash2` et `pc_rehash` sont dans `procedural_commun.gdshaderinc`.
Elles travaillent sur des entiers, ce qui donne le même résultat sur toutes les cartes
graphiques.

### 2. Se servir du tirage

**La teinte.** Chaque bloc tire sa couleur entre deux teintes de pierre, puis sa clarté :

```glsl
vec3 col = mix(stone, stone_2, clamp(hb * block_variation * 1.4, 0.0, 1.0));
col *= 1.0 + (hb2 - 0.5) * 0.16 * block_variation;
```

Un troisième tirage, `hb3`, désigne un bloc sur vingt : il a été remplacé lors d'un
ravalement, il est plus clair et plus propre que ses voisins.

**La forme du motif.** Les blocs n'ont plus tous la même longueur. `block_edge(k, row)` tire
la position de chaque joint vertical autour du milieu de sa cellule. Un pixel regarde s'il est
à gauche ou à droite de la limite de sa cellule : cela lui dit dans quel bloc il se trouve.

### 3. Le bruit : des taches continues

Le hachage donne une valeur par case, sans rapport avec la case voisine. Pour des salissures,
il faut des taches qui s'étalent. C'est le rôle du bruit :

- `pc_noise2(p)` : on tire une valeur à chaque coin d'une grille et on fond de l'une à l'autre.
  On obtient des taches douces, de la taille d'une case ;
- `pc_fbm2(p, octaves, footprint)` : on additionne plusieurs bruits de plus en plus fins et de
  moins en moins forts. On obtient des taches qui ont du détail.

La **fréquence** règle la taille des taches. On multiplie la position avant d'appeler le bruit :

| Appel | Taille des taches | Sert à |
|---|---|---|
| `pc_fbm2(p * 0.23, …)` | 4 m environ | le voile de suie |
| `pc_fbm2(p * 0.45, …)` | 2 m | de grandes plages claires ou sombres |
| `pc_fbm2(in_block * 85.0, …)` | 1 cm | le grain de la pierre |

Le dernier paramètre, `footprint`, est la taille d'un pixel dans l'unité du bruit. Les octaves
plus fines que le pixel sont éteintes, et même pas calculées : pas de scintillement au loin, et
un shader moins cher quand on s'éloigne. C'est déjà un niveau de détail ; l'étape 013 y revient.

### 4. Étirer le bruit : les coulures

Un bruit a la même allure dans toutes les directions. Si on l'étire, il prend un sens :

```glsl
float run = pc_fbm2(vec2(u * 9.0, v * 0.55), 4, max(fu * 9.0, fv * 0.55));   // serré en largeur, lâche en hauteur
```

Les taches deviennent de longues traînées verticales. `smoothstep()` n'en garde que les plus
marquées, et un second bruit, très large, décide dans quelles zones du mur elles apparaissent.

### 5. Salir là où la saleté se met

Trois salissures, chacune avec sa logique :

- le voile (`film`) : par grandes plages, d'après le bruit large ;
- le bord des joints (`edge_dirt`) : `exp(-d / 0.02)` vaut 1 dans le joint et retombe en 2 cm ;
- le pied du mur (`splash`) : `exp(-above_ground / 0.42)` vaut 1 au sol et retombe en 40 cm.
  La position sert donc aussi à savoir à quelle hauteur on est.

### 6. Du relief sans carte de normales

Le mur reste plat : on ne déplace aucun sommet. On change seulement la direction de la normale,
celle qui sert au calcul de la lumière.

Au bord d'un joint, la surface descend de `joint_recess` sur la largeur du chanfrein. On en
connaît donc la pente exacte. `pc_ramp_d()` renvoie cette pente, et `pc_slope_normal()` penche
`NORMAL` d'autant, le long de `t` ou de `b`. Le joint accroche la lumière d'un côté et reste dans
l'ombre de l'autre.

Le grain ajoute un relief très fin avec `pc_bump()`, qui déduit la pente d'une hauteur à partir
des pixels voisins.

### 7. Les détails de près

Deux raffinements ne se voient qu'à quelques mètres, et ne sont calculés que là : les arêtes
épaufrées (`chip`, la largeur du joint varie un peu) et les piqûres (`pits`, de petits trous de
coquille). Chacun a son test : `if (chip_fade > 0.0)`. De loin, le test échoue et le bruit
n'est pas calculé.

### 8. Côté scripts : presque rien

Le script de l'immeuble expose une variable de plus, `soot`, et la donne aux matériaux. Celui
des matériaux règle aussi la seconde teinte et celle des joints d'après la première : une
façade claire garde ainsi des joints clairs. **Quand une étape est une étape de shader, les
scripts ne bougent presque pas.**

## Ce qu'il faut retenir

1. Hachage : un tirage par case, toujours le même pour la même case.
2. Bruit : des taches continues ; la fréquence règle leur taille.
3. Étirer un bruit lui donne une direction.
4. Le relief se fait en penchant la normale, pas en déplaçant la surface.
5. Un détail plus fin que le pixel ne se calcule pas.

## À essayer

- `soot` de 0 à 1.
- `stone_color` à (0,95 ; 0,92 ; 0,86) et `soot` à 0,05 : une façade ravalée.
- Dans le shader, écrire `ALBEDO = vec3(veil);` juste avant la fin : on voit le bruit du voile, seul.
- Dans le shader : valeur par défaut de `block_variation` à 0, puis à 1.
{TWIN}
## Étape suivante

004 : des fenêtres dans les baies. Un rectangle par baie, et un shader qui part des UV du
rectangle, et non plus de la position.
