# Tokyo · étape 003 · Le bruit : teinte par carreau, coulures, relief

**Piste : Shader.** Le mur de l'étape 002 est trop parfait : tous les carreaux ont la même
teinte, la façade sort de l'usine. On y met du hasard, à trois échelles : le carreau (teinte,
faux aplomb, brillant), la façade (crasse, coulures de pluie), le joint (creux).

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. L'immeuble a une variable de plus :
`grime`, l'encrassement. Tourner autour du mur, de près : les carreaux ne renvoient pas tous
le ciel de la même façon.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le shader est le fichier à lire. Dans les
fichiers modifiés, ce qui est nouveau est encadré par `>>> NOUVEAU À L'ÉTAPE 003` et
`<<< FIN DU NOUVEAU`.

## Ce qu'on a fait, dans l'ordre

### 1. Un dé qui retombe toujours du même côté : le hachage

Un hachage transforme un nombre en un autre nombre qui a l'air tiré au hasard, mais qui est
toujours le même pour la même entrée. C'est le dé de tout le procédural : « le carreau
numéro 12 du rang 7 » donne toujours la même valeur, sans rien stocker nulle part.

Il faut d'abord un numéro par carreau. Le rang, on l'avait ; la colonne s'obtient de la même
façon :

```glsl
	float column = floor(uu);
	float ht = pc_hash2(vec2(column, row) + vec2(13.0, 71.0));
	float ht2 = pc_rehash(ht, 1.0);
	float ht3 = pc_rehash(ht, 2.0);
```

`pc_hash2()` donne un nombre entre 0 et 1 à partir du numéro du carreau. `pc_rehash()` en
tire d'autres, indépendants du premier : un tirage pour la teinte, un pour la clarté, un pour
le brillant.

Le hachage du fichier commun travaille sur des entiers. Il donne le même résultat sur toutes
les cartes graphiques, contrairement aux hachages en `sin()` qu'on trouve partout.

### 2. Se servir du tirage : la teinte

```glsl
	vec3 col = mix(pc_color_in(tile_color), pc_color_in(tile_color_2), clamp(pick * tile_variation, 0.0, 1.0));
	col *= 1.0 + (ht2 - 0.5) * 0.12 * tile_variation * tile_fade;
```

Chaque carreau tire sa teinte entre deux couleurs, puis sa clarté. Ce sont les écarts de
cuisson : d'une fournée à l'autre, un émail ne sort jamais tout à fait pareil.

`pick` et `tile_fade` règlent un problème propre aux petits carreaux. De loin, un carreau
est plus petit qu'un pixel : si chacun gardait sa teinte, l'image fourmillerait. On va donc
vers la teinte moyenne à mesure que le carreau rapetisse à l'écran :

```glsl
	float tile_fade = 1.0 - smoothstep(0.35, 1.2, fw / tile_size.y);
	float pick = mix(0.5, ht, tile_fade);
```

`fw / tile_size.y` est la taille du pixel comptée en carreaux. C'est le même filtrage qu'à
l'étape 002, appliqué cette fois à un tirage au lieu d'une ligne.

### 3. Le hasard touche aussi la lumière : le faux aplomb

Aucun carreau n'est posé parfaitement à plat. Chacun tire une pente minuscule :

```glsl
	slope_u += (ht2 - 0.5) * 0.02 * tilt_fade;
	slope_v += (ht3 - 0.5) * 0.02 * tilt_fade;
```

Sa normale penche d'un rien, et le reflet du ciel change de l'un à l'autre. C'est ce qui
fait qu'une façade carrelée scintille quand on se déplace : la couleur ne bouge pas, c'est
la lumière qui bouge. La pierre de Paris, mate, n'a pas besoin de cela.

### 4. Le bruit : des taches continues

Le hachage donne une valeur par case, sans rapport avec ses voisines. Pour des taches qui
s'étendent, il faut un **bruit** : on tire une valeur à chaque coin d'une grille et on fond
de l'une à l'autre (`pc_noise2`). En additionnant plusieurs bruits de plus en plus fins, on
obtient des taches qui ont du détail : c'est le bruit fractal, `pc_fbm2`.

```glsl
	float broad = pc_fbm2(p * 0.5, 3, fw * 0.5);
	col *= 0.93 + 0.14 * broad;
```

Le premier argument règle la taille des taches : `p * 0.5` donne des plages de 2 m, qui
enjambent les carreaux. Le deuxième est le nombre d'octaves. Le troisième est la taille du
pixel : les octaves plus fines que lui ne sont même pas calculées.

Le voile de crasse est le même bruit, plus large encore, et seuillé pour faire des plages
nettes :

```glsl
	float veil = smoothstep(0.4, 0.75, pc_fbm2(p * 0.27 + vec2(40.0, 13.0), 4, fw * 0.27));
	float film = grime * (0.1 + 0.5 * veil);
```

### 5. Étirer le bruit : les coulures

```glsl
		float run = pc_fbm2(vec2(u * 11.0, v * 0.35), 4, max(fu * 11.0, fv * 0.35));
```

Un bruit étiré a une direction. `u * 11.0` le serre en largeur, `v * 0.35` le relâche en
hauteur : cela dessine des traînées verticales. Sur un émail lisse, la pluie trace des
coulures nettes et sombres, plus marquées que sur de la pierre : `streaks` vaut 0,45 par
défaut.

### 6. Salir là où la saleté se met

- au bord des carreaux et dans les joints : `exp(-d / 0.008)`, une salissure qui décroît vite
  quand on s'éloigne du joint ;
- en pied de mur : `exp(-max(v_pos.y, 0.0) / 0.35)`, le rejaillissement de la pluie.
  `v_pos.y` est la hauteur au-dessus du sol : c'est l'avantage de travailler en mètres dans
  le repère de l'immeuble.

### 7. Du relief sans carte de normales

Au bord d'un joint, le carreau descend de `joint_recess` sur la largeur de son arrondi. On
connaît donc la pente de la surface à cet endroit : `pc_ramp_d()` la calcule. Il suffit de
pencher la normale d'autant.

```glsl
		pc_ramp_d(half_joint, half_joint + bevel, dx, 2.0 * fu, ramp_slope);
		slope_u += joint_recess * ramp_slope * sign_u;
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
```

`sign_u` dit de quel côté est le joint. `to_view` amène les axes du mur dans l'espace de la
caméra, où le moteur attend la normale.

### 8. Le brillant suit la matière

```glsl
	float tile_roughness = mix(0.75, 0.22, glaze) + (ht3 - 0.5) * 0.1 * tile_fade + 0.5 * dirt;
	ROUGHNESS = clamp(mix(tile_roughness, 0.92, joint_mask), 0.08, 0.97);
```

`glaze` va du grès mat à l'émail très lisse. Chaque carreau a son brillant, la crasse ternit
l'émail, et le joint reste mat.

### 9. Côté scripts : presque rien

L'immeuble gagne la variable `grime` et la donne aux matériaux. Le script des matériaux
calcule la seconde teinte des carreaux à partir de la première, un peu plus sombre et plus
chaude, puis passe le tout au shader.

## Ce qu'il faut retenir

1. Un hachage est un dé qui retombe toujours du même côté pour le même numéro.
2. De loin, un tirage par carreau doit se fondre dans sa moyenne, comme une ligne trop fine.
3. Le hasard peut porter sur la lumière (la normale, le brillant), pas seulement la couleur.
4. Un bruit fait des taches continues ; sa fréquence règle leur taille ; étiré, il a un sens.
5. Une pente connue suffit à faire du relief : pas besoin de carte de normales.

## À essayer

- `grime` à 0, puis à 1.
- Dans le shader : `tile_variation` à 0, puis à 1.
- `tilt` à 1, et tourner autour du mur. Puis `glaze` à 0 (grès mat) et à 1.
- `streaks` à 1.
- Pour voir un ingrédient seul, écrire `ALBEDO = vec3(veil);` juste avant la fin.
{TWIN}
## Étape suivante

004 : le shader de fenêtre. Il part des UV d'un rectangle, et non plus de la position.
