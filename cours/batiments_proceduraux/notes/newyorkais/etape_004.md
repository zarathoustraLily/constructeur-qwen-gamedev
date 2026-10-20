# New York · étape 004 · Fenêtres à guillotine

**Piste : Building + Shader.** Les baies étaient des trous noirs. On y pose des fenêtres : le
script ne pose qu'un rectangle par baie, et un shader y dessine une fenêtre à guillotine, son
dormant, ses deux châssis, ses petits bois, sa vitre. 1 320 fenêtres, un seul appel de dessin.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. S'approcher d'une fenêtre : une sur sept
environ a son châssis du bas levé. Dans l'inspecteur de la tour, `frame_color` règle la teinte
des châssis.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le nouveau shader `…_fenetre.gdshader` est la
leçon ; dans le script de la tour, trois lignes suffisent.

## Ce qu'on a fait, dans l'ordre

### 1. Un rectangle par baie : `panel()`

Une fenêtre en vraie géométrie, avec son dormant, ses châssis et ses petits bois, ferait une
centaine de triangles. Multipliée par 1 320, la tour en compterait plus de cent mille. On pose
donc un simple rectangle au fond de chaque baie, et c'est le shader qui dessine la fenêtre.

```gdscript
		for bay: int in range(bays):
			var center: Vector3 = Vector3(-0.5 * width + (float(bay) + 0.5) * bay_width, sill_y + 0.5 * opening.y, -WINDOW_RECESS)
			_mesh.panel(opening, frame * Transform3D(Basis.IDENTITY, center), _materials.window)
```

Le rectangle a la taille de la baie, `opening`, et il est posé 12 cm en retrait derrière le nu
des bandeaux (`WINDOW_RECESS`) : la fenêtre est au fond de son tableau, comme dans un vrai mur.
Son repère est celui de la façade, déplacé au centre de la baie.

`panel()` ne fabrique pas de triangles : elle range le rectangle dans une liste, et `commit()`
en fait un `MultiMesh`, un seul maillage dessiné autant de fois qu'il a d'instances. Chaque
instance a sa propre matrice : sa position, son orientation et sa taille. La tour passe de
2 028 à 4 668 triangles : deux par fenêtre. Et les 1 320 fenêtres partent en **un seul appel de
dessin**.

### 2. Le shader part des UV

La brique partait de la position du pixel dans la tour. Une fenêtre a sa propre géométrie : on
part de ses coordonnées UV, qui vont de 0 à 1 sur le rectangle. Mais le rectangle de base fait
un mètre de côté, et sa vraie taille est l'échelle de son instance. Le shader la retrouve dans
la matrice :

```glsl
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
```

Dans un `MultiMesh`, `MODEL_MATRIX` est la matrice de l'instance : la longueur de ses deux
premiers axes est la taille de la fenêtre, en mètres. Puis :

```glsl
	vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
	float footprint = max(fwidth(q.x), fwidth(q.y));
```

`q` est en mètres, l'origine en bas à gauche de la fenêtre (les UV de Godot partent d'en haut).
Tout le dessin se fait sur `q`.

Ces deux valeurs sont `flat` : un `varying flat` n'est pas fondu d'un sommet à l'autre, il est
le même sur tout le rectangle. C'est ce qu'il faut pour une donnée propre à la fenêtre entière.

### 3. Chaque fenêtre tire ses dés

La position de la fenêtre dans la tour sert de clé de tirage :

```glsl
	v_key = MODEL_MATRIX[3].xyz;
```

```glsl
	float r0 = pc_hash3(v_key * 8.0);
	float r1 = pc_rehash(r0, 1.0);
	float r2 = pc_rehash(r0, 2.0);
```

Deux fenêtres n'ont jamais la même position, donc jamais les mêmes tirages ; et une fenêtre
garde les siens à chaque image. Le premier dé décide si la fenêtre est ouverte (`open_share`,
15 %), le second de combien.

### 4. La fenêtre à guillotine

Deux châssis se rencontrent au milieu de la baie. Celui du haut est fixe, côté rue ; celui du
bas glisse vers le haut, derrière lui. `lift` dit de combien il est levé :

```glsl
	float lift = r1 < open_share ? mix(0.08, 0.45, r2) * (mid - frame_width) : 0.0;
	vec4 upper_box = vec4(frame_width, w - frame_width, mid - meeting_rail, h - frame_width);
	vec4 lower_box = vec4(frame_width, w - frame_width, frame_width + lift, mid + lift);
```

Chaque châssis est décrit par ses quatre bords : gauche, droit, bas, haut. Celui du bas monte
de `lift` ; sous lui, la baie est ouverte, sans bois ni vitre.

### 5. Une distance signée par châssis

Tout se joue sur une distance, comme le joint de la brique : positive dans un carreau, négative
sur le bois. La fonction `sash_glass()` la calcule pour un châssis : la distance au bord du
cadre de bois (montants et traverses), puis aux petits bois.

```glsl
	vec2 g0 = vec2(box.x + stile_width, box.z + rail_low);
	vec2 g1 = vec2(box.y - stile_width, box.w - rail_high);
	float inside = min(min(q.x - g0.x, g1.x - q.x), min(q.y - g0.y, g1.y - q.y));
```

`g0` et `g1` sont les coins du verre. `inside` est la distance au bord du verre le plus proche :
le minimum des quatre. Les petits bois s'y ajoutent de la même façon que les joints : `floor()`
donne le numéro du petit bois le plus proche, et l'on prend la distance à lui.

```glsl
	if (lights.x > 1) {
		float k = clamp(floor((q.x - g0.x) / cell.x + 0.5), 1.0, float(lights.x - 1));
		inside = min(inside, abs(q.x - g0.x - k * cell.x) - 0.5 * muntin_width);
	}
```

`upper_lights` et `lower_lights` donnent les carreaux de chaque châssis, en colonnes et
rangées. Un sur un, deux sur deux, six sur six : la même fonction dessine tous les modèles.

### 6. Ce qu'on voit en premier

```glsl
	bool in_upper = q.y >= upper_box.z;
	bool in_lower = q.y >= lower_box.z && q.y <= lower_box.w;
	float front = in_upper ? upper_in : (in_lower ? lower_in : 1.0);
	float edge = min(min(q.x, w - q.x), min(q.y, h - q.y));
	front = min(front, edge - frame_width);
	float glass_cover = pc_step(0.0, front, footprint);
```

Au-dessus du milieu, c'est le châssis du haut qu'on voit ; plus bas, celui du bas, s'il est là ;
sous le châssis levé, rien. Le dormant fait le tour. `glass_cover` vaut 1 sur la vitre (ou le
vide), 0 sur le bois, avec un bord large d'un pixel.

Deux cas de plus. Derrière la vitre du haut peut passer le châssis du bas levé : son bois se
devine à travers (`wood_behind`), ailleurs on regarde à travers deux vitres (`double_glass`).
Et sous le châssis levé, la baie est ouverte (`open_cover`) : noire, sans reflet.

### 7. Le bois en relief, la vitre qui reflète

Le bois dépasse de la vitre de 2 cm. Comme le joint de la brique, ce relief ne déplace rien :
`pc_bump()` déduit une normale d'une hauteur, qui monte de 0 à 2 cm au bord du verre.

```glsl
	ALBEDO = pc_color_out(mix(frame_albedo, seen, glass_cover));
	NORMAL = normalize(mix(n_frame, normalize(NORMAL), glass_cover));
	ROUGHNESS = mix(mix(0.55, glass_roughness, glass), 1.0, open_cover);
	SPECULAR = mix(0.5, 0.85, glass) * (1.0 - open_cover);
```

La vitre est sombre, lisse et très réfléchissante : le moteur y reflète le ciel. Le bois peint
est mat. La baie ouverte ne renvoie rien. L'étape 005 mettra un bureau derrière la vitre.

## Ce qu'il faut retenir

1. Un rectangle instancié par fenêtre, un shader pour le dessin : 1 320 fenêtres, un appel de
   dessin, deux triangles chacune.
2. Dans un `MultiMesh`, `MODEL_MATRIX` est la matrice de l'instance : on y lit la taille et la
   position du rectangle.
3. Un objet dessiné par shader se décrit par des distances signées : positive dedans, négative
   dehors, le minimum pour combiner.
4. La position d'une instance est une clé de tirage toute trouvée.

## À essayer

- `frame_color` à (0,82 ; 0,80 ; 0,74) : des châssis blanc cassé.
- Dans le shader, `upper_lights` à (3, 2) et `lower_lights` à (3, 2) : six sur six.
- Dans le shader, `open_share` à 1 : toutes les fenêtres ouvertes, à des hauteurs différentes.
- Dans le script, `WINDOW_RECESS` à 0 : la fenêtre au nu du mur, la façade devient plate.
- Dans le shader, remplacer `v_key * 8.0` par `vec3(0.0)` : toutes les fenêtres tirent le même dé.
{TWIN}
## Étape suivante

005 : un bureau derrière chaque vitre, sans un triangle de plus. Et la nuit, les étages
s'allument.
