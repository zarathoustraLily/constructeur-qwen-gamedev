# New York · étape 003 · Le bruit : teinte par brique, suie, coulures

**Piste : Shader.** Le mur de l'étape 002 est trop parfait : toutes les briques ont la même
teinte, la tour est propre et plate. On y met du hasard, à trois échelles : la brique, la
plage de quelques mètres, le pan de façade.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler la tour, ouvrir `{NAME}.tscn`
et changer une variable du nœud racine : il y en a une de plus, `grime`, l'encrassement.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Dans les trois fichiers modifiés, le code ajouté
est encadré par `>>> NOUVEAU À L'ÉTAPE 003` et `<<< FIN DU NOUVEAU`. La leçon est dans le shader
`…_brique.gdshader`, puis dans les parties « ÉTAPE 003 » de `procedural_commun.gdshaderinc`.

## Ce qu'on a fait, dans l'ordre

### 1. Un dé qui retombe toujours du même côté : le hachage

Un shader ne peut rien retenir d'une image à l'autre, ni d'un pixel à l'autre. Pour qu'une
brique soit « un peu plus sombre », il faut retrouver cette information à partir de rien. La
réponse est le hachage : une fonction qui transforme un nombre en un autre, d'apparence
aléatoire, mais toujours le même pour la même entrée.

```glsl
	float hb = pc_hash2(vec2(column, row) + vec2(17.0, 43.0));
	float hb2 = pc_rehash(hb, 1.0);
	float hb3 = pc_rehash(hb, 2.0);
```

`column` et `row` sont les numéros de la brique, ceux que `floor()` donnait à l'étape 002. Tous
les pixels d'une même brique obtiennent donc le même `hb`. `pc_rehash()` en tire deux autres,
indépendants du premier : trois dés pour une brique.

Les fonctions `pc_hash2` et `pc_rehash` sont dans `procedural_commun.gdshaderinc`. Elles
travaillent sur des entiers, ce qui donne le même résultat sur toutes les cartes graphiques.

### 2. Se servir des trois dés

```glsl
	vec3 col = mix(pc_color_in(brick_color), pc_color_in(brick_color_2), clamp(pick * brick_variation, 0.0, 1.0));
	col *= 1.0 + (hb2 - 0.5) * 0.3 * brick_variation * brick_fade;
	float dark = step(hb3, dark_bricks) * brick_fade;
	col = mix(col, col * vec3(0.68, 0.6, 0.56), dark);
```

- le premier dé place la teinte de la brique entre deux couleurs : les briques d'un même mur
  ne sortent pas du four avec la même couleur ;
- le deuxième la rend un peu plus claire ou plus sombre que sa voisine ;
- le troisième désigne les briques plus cuites, presque brunes : `step(hb3, dark_bricks)` vaut
  1 pour 6 % d'entre elles.

La seconde couleur n'est pas un réglage de plus pour l'utilisateur : le script des matériaux la
déduit de la première, plus sombre et plus rouge.

```gdscript
	var brick_2: Color = Color(brick_color.r * 0.82, brick_color.g * 0.72, brick_color.b * 0.70)
```

### 3. De loin, les briques se fondent

Une brique fait 7 cm de haut. À 80 m, c'est moins d'un pixel : si chaque pixel tombe sur une
brique différente, avec sa propre teinte, l'image fourmille. On mesure donc la taille du pixel
(`fw`) par rapport à celle d'une brique, et l'on ramène peu à peu chaque tirage vers la moyenne :

```glsl
	float brick_fade = 1.0 - smoothstep(0.35, 1.2, fw / brick_size.y);
	float pick = mix(0.5, hb, brick_fade);
```

De près, `brick_fade` vaut 1 et chaque brique a sa teinte. De loin, il vaut 0 : toutes les
briques prennent la teinte du milieu. Sur une tour, ce n'est pas un détail : la plupart des
briques sont vues de loin.

### 4. Le bruit : des taches continues

Le hachage donne une valeur par case, sans rapport avec la case voisine. Pour des salissures,
il faut des taches qui s'étalent. C'est le rôle du bruit :

- `pc_noise2(p)` : on tire une valeur à chaque coin d'une grille et on fond de l'une à l'autre.
  On obtient des taches douces, de la taille d'une case ;
- `pc_fbm2(p, octaves, footprint)` : on additionne plusieurs bruits de plus en plus fins et de
  moins en moins forts. On obtient des taches qui ont du détail.

La **fréquence** règle la taille des taches. On multiplie la position avant d'appeler le bruit :

| Appel | Taille des taches | Sert à |
|---|---|---|
| `pc_fbm2(p * 0.4, …)` | 2,5 m environ | des plages plus claires ou plus sombres |
| `pc_fbm2(p * 0.12 + …, …)` | 8 m environ | la suie |
| `pc_fbm2(vec2(u * 7.0, v * 0.25), …)` | 14 cm de large, 4 m de haut | les coulures |

Le dernier paramètre, `footprint`, est la taille d'un pixel dans l'unité du bruit. Les octaves
plus fines que le pixel sont éteintes, et même pas calculées : pas de scintillement au loin, et
un shader moins cher quand on s'éloigne. C'est déjà un niveau de détail ; l'étape 013 y revient.

### 5. La suie, par grandes plages

```glsl
	float soot = smoothstep(0.35, 0.8, pc_fbm2(p * 0.12 + vec2(23.0, 7.0), 4, fw * 0.12));
	float film = grime * (0.12 + 0.55 * soot);
```

Le bruit large varie doucement entre 0 et 1. `smoothstep(0.35, 0.8, …)` le seuille : en dessous
de 0,35, pas de suie ; au-dessus de 0,8, la plage la plus noire. Entre les deux, un bord doux.
On obtient des plages franches, et non un voile uniforme. `grime`, la variable de la tour, règle
la force de l'ensemble : à 0, une façade lavée.

### 6. Étirer le bruit : les coulures

Un bruit a la même allure dans toutes les directions. Si on l'étire, il prend un sens :

```glsl
		float run = pc_fbm2(vec2(u * 7.0, v * 0.25), 4, max(fu * 7.0, fv * 0.25));
		float run_zone = smoothstep(0.35, 0.7, pc_fbm2(p * vec2(0.5, 0.15) + 31.0, 3, fw * 0.5));
		runs = streaks * smoothstep(0.5, 0.85, run) * run_zone;
```

Serré en largeur, lâche en hauteur : les taches deviennent de longues traînées verticales.
`smoothstep()` n'en garde que les plus marquées, et un second bruit, très large, décide dans
quelles zones du mur elles apparaissent. La pluie ne coule pas partout.

### 7. Salir là où la saleté se met

Deux salissures de plus, chacune avec sa logique :

- le bord des briques (`edge_dirt`) : `exp(-d / 0.006)` vaut 1 dans le joint et retombe en
  6 mm. `d` est la distance au joint le plus proche, calculée à l'étape 002 ;
- le pied du mur (`splash`) : `exp(-max(v_pos.y, 0.0) / 0.5)` vaut 1 au sol et retombe en
  50 cm. La position sert donc aussi à savoir à quelle hauteur on est.

Et un joint encrassé est plus sombre qu'un joint propre :

```glsl
	col = mix(col, pc_color_in(joint_color) * (1.0 - 0.55 * dirt), joint_mask);
```

### 8. Du relief sans carte de normales

Le mur reste plat : on ne déplace aucun sommet. On change seulement la direction de la normale,
celle qui sert au calcul de la lumière.

Au bord d'un joint, la surface descend de `joint_recess` (4 mm) sur la largeur de l'arrondi
(`bevel`, 5 mm). On en connaît donc la pente exacte. `pc_ramp_d()` renvoie cette pente, et
`pc_slope_normal()` penche `NORMAL` d'autant, le long de `t` ou de `b` :

```glsl
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
```

`NORMAL` est donné en espace vue, alors que `t` et `b` sont en espace objet : la première ligne
fabrique de quoi passer de l'un à l'autre. Le joint accroche la lumière d'un côté et reste dans
l'ombre de l'autre.

Enfin, `AO` assombrit un peu le fond des joints, et la rugosité monte avec la saleté : la brique
est mate, la suie la rend plus mate encore.

### 9. Côté scripts : presque rien

Le script de la tour expose une variable de plus, `grime`, et la donne aux matériaux. Celui des
matériaux règle la seconde teinte d'après la première. **Quand une étape est une étape de
shader, les scripts ne bougent presque pas.**

## Ce qu'il faut retenir

1. Hachage : un tirage par case, toujours le même pour la même case.
2. Bruit : des taches continues ; la fréquence règle leur taille, `smoothstep()` les découpe.
3. Étirer un bruit lui donne une direction.
4. Ce qui devient plus petit qu'un pixel revient à sa moyenne, ou n'est pas calculé.
5. Le relief se fait en penchant la normale, pas en déplaçant la surface.

## À essayer

- `grime` de 0 à 1.
- `brick_color` à (0,40 ; 0,28 ; 0,22) : une brique brun sombre, sur laquelle la suie se voit
  moins.
- Dans le shader, écrire `ALBEDO = vec3(soot);` juste avant la fin : on voit les plages de suie,
  seules.
- Dans le shader : valeur par défaut de `brick_variation` à 0, puis à 1.
- Dans le shader, remplacer `mix(0.5, hb, brick_fade)` par `hb`, et reculer : la tour fourmille.
{TWIN}
## Étape suivante

004 : des fenêtres dans les baies. Un rectangle par baie, et un shader qui part des UV du
rectangle pour dessiner une fenêtre à guillotine.
