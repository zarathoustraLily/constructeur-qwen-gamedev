# New York · étape 013 · Niveaux de détail et occultation

**Piste : Performance.** Le quartier de l'étape 012 est juste, mais il dessine tout, partout :
les piliers de brique d'une tour à 400 m, ses 1 300 fenêtres, les portes tambour et les
enseignes de toutes les boutiques, même derrière une autre tour. Trois outils pour ne dessiner que
ce qui se voit : les **niveaux de détail**, une **façade lointaine** dessinée sur un seul
rectangle, et l'**occultation**. C'est le projet à utiliser.

De près, rien ne change dans l'image. Ce qui change : ce qu'on dessine au loin, ce qui porte une
ombre, ce qu'on ne dessine pas parce qu'une tour le cache, la finesse des shaders, et les réglages
du moteur.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer avec F5 : on est sur le trottoir de l'avenue.
3. Clic droit maintenu et souris : regarder. ZQSD : se déplacer. A et E : descendre, monter.
   Maj : aller vite. **N** : jour ou nuit. **F** : recadrer. Échap : quitter.
4. **P** : qualité basse, moyenne, haute. **R** : résolution du rendu 3D. **V** : synchro
   verticale.

La ligne de mesure, en haut de l'écran, donne le temps par image, la qualité en cours, la
résolution du rendu et le nom de la carte graphique. Une seconde ligne, nouvelle, dit **ce que le
moteur a dessiné** pendant la dernière image : combien d'objets, de triangles, d'appels de
dessin, pour l'image puis pour les ombres. Monter au-dessus des toits (E) et regarder ces nombres
baisser à mesure qu'on s'éloigne.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Dans chaque fichier modifié, le code de cette
étape est encadré par `>>> NOUVEAU À L'ÉTAPE 013` et `<<< FIN DU NOUVEAU`. Commencer par
`1_core/procedural/mesh_builder.gd` : toute la mécanique des niveaux de détail y est. Puis le
nouveau shader `…_facade_lointaine.gdshader`.

## Le diagnostic : compter avant de toucher

On ne corrige pas une lenteur au jugé. La visite sait mesurer :

```text
godot --path . -- --bench=20 --quality=1
```

rend 20 images, écrit le temps moyen et ce qui a été dessiné, puis quitte. Avec
`--set-near_distance=0.0 --set-far_distance=0.0`, le quartier n'a plus de niveaux de détail ;
avec `--set-occluders=false`, plus d'occultation. Deux vues : celle de la visite, sur le
trottoir ; et une vue lointaine, à 400 m, au-dessus des toits
(`--cam=-260,140,300 --look=0,60,-130`).

Mesuré en 1280 × 720, qualité moyenne, moteur Compatibilité, **en rendu logiciel** (sur
processeur, sans carte graphique) :

| Vue | Réglage | Objets | Triangles | Temps par image |
|---|---|---|---|---|
| Trottoir | tout | 558 | 47 000 | 257 ms |
| Trottoir | sans occultation | 588 | 49 900 | 261 ms |
| Trottoir | sans niveaux de détail | 647 | 62 500 | 261 ms |
| Trottoir | sans l'un ni l'autre | 688 | 69 700 | 279 ms |
| Lointaine | tout | 350 | 6 700 | 66 ms |
| Lointaine | sans occultation | 391 | 7 900 | 67 ms |
| Lointaine | sans niveaux de détail | 555 | 67 800 | 129 ms |
| Lointaine | sans l'un ni l'autre | 732 | 89 100 | 141 ms |

Il faut lire ce tableau honnêtement.

- **Les nombres d'objets et de triangles ne dépendent pas de la machine.** Ce sont eux que les
  niveaux de détail et l'occultation font baisser : de loin, treize fois moins de triangles et
  deux fois moins d'objets. Chaque moteur de rendu les compte à sa façon : on ne compare que des
  nombres d'un même moteur.
- **Les temps, eux, viennent d'un rendu logiciel**, où ce sont les pixels qui coûtent, pas les
  triangles. Sur le trottoir, les tours proches couvrent tout l'écran : les niveaux de détail n'y
  peuvent presque rien, et le temps ne baisse que de 8 %. De loin, il est divisé par deux.
- **L'occultation gagne peu dans ces deux vues** : 30 à 40 objets. Dans l'avenue, presque chaque
  tour dépasse un peu de celle de devant ; au-dessus des toits, on voit tout. Elle gagne quand une
  tour proche cache vraiment ce qui est derrière : dans une rue transversale, au pied d'une tour.
- L'étape 012, sur la vue du trottoir, mettait 351 ms. Une bonne part de l'écart vient de la
  qualité moyenne des shaders (section 8), qui allège chaque pixel de brique.

Le même quartier en Forward+, le moteur de rendu par défaut des projets, toujours sans carte
graphique (elle est émulée par le processeur, d'où des temps bien plus longs) :

| Vue | Réglage | Objets | Triangles | Ombres : objets | Ombres : triangles | Temps par image |
|---|---|---|---|---|---|---|
| Trottoir | tout | 246 | 47 000 | 312 | 45 900 | 9,3 s |
| Trottoir | sans l'un ni l'autre | 384 | 69 700 | 304 | 53 300 | 12,7 s |
| Lointaine | tout | 213 | 6 700 | 137 | 4 900 | 1,9 s |
| Lointaine | sans l'un ni l'autre | 557 | 89 100 | 175 | 27 300 | 6,9 s |

Le même écart, compté par un autre moteur : de loin, deux fois et demie moins d'objets, treize
fois moins de triangles, et une image trois fois et demie plus rapide. Sur le trottoir, le temps
baisse d'un quart. Et un prix apparaît : les ombres comptent un peu plus d'objets avec les
niveaux de détail que sans, parce que chaque gradin est devenu un objet (section 3).

Sur une vraie carte graphique, les proportions seront autres. La ligne de mesure de la visite
donne le vrai chiffre sur la machine où elle tourne.

## Ce qu'on a fait, dans l'ordre

### 1. Trois zones de distance

La tour a trois variables de plus, dans le groupe « Niveaux de détail » :

| Variable | Défaut | Effet |
|---|---|---|
| `near_distance` | 60 m | Jusque-là, un gradin est dessiné en entier. |
| `far_distance` | 250 m | Au-delà, une façade de brique n'est plus qu'un rectangle. |
| `occluders` | vrai | Chaque gradin pose une boîte d'occultation. |

Elles découpent l'espace en trois zones : proche, moyenne, lointaine. Mettre les deux distances à
0 coupe les niveaux de détail. Le quartier a les mêmes variables, et les donne à chacune de ses
tours.

### 2. Dire à chaque pièce où elle vit : `set_zones()`

Toute la mécanique est dans l'outil de maillage, `1_core/procedural/mesh_builder.gd`, commun aux
trois villes. Avant d'émettre une pièce, on lui dit dans quelles zones elle sera dessinée :

```gdscript
			_mesh.set_zones(MeshBuilder.ZONE_NEAR)
			_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (run.x + run.y), top, 0.0)), run.y - run.x, material)
			_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
			var deep: float = thickness + 2.0 * overhang
			_box_in(frame, Vector3(run.y - run.x, height, deep), Vector3(0.5 * (run.x + run.y), top + 0.5 * height, overhang - 0.5 * deep), material)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
```

C'est le chaperon : de près, le profil de l'étape 008 ; au-delà, une boîte de la même taille ;
puis retour à la normale, pour que la suite n'hérite pas d'une zone.

L'outil range les triangles par matériau **et par case** : une case est une combinaison de
zones. À la fin, `commit()` fait un maillage par matériau et par case, et règle sur chacun deux
propriétés que tout nœud de géométrie de Godot possède :

```gdscript
	instance.visibility_range_begin = begin
	instance.visibility_range_end = end
```

La première est la distance où la pièce apparaît, la seconde celle où elle disparaît. C'est
ensuite le moteur qui affiche ou cache chaque maillage, à chaque image, d'après la distance de
la caméra. **Aucun script ne tourne pendant le jeu.**

Le moteur mesure cette distance jusqu'au **centre de la boîte englobante** de chaque maillage. Le
profil d'un chaperon et sa boîte n'ont pas la même boîte englobante, donc pas le même centre : ils
ne basculeraient pas au même moment. `commit()` leur donne donc à tous la même boîte, par la
propriété `custom_aabb`, et la bascule se fait d'un coup.

### 3. Une tour est trop haute pour un seul niveau de détail

À Paris et à Tokyo, un immeuble entier partage une boîte. Une tour de 150 m, non : la distance
serait comptée jusqu'à son centre, à 75 m de haut. Au pied de la tour, on serait déjà « à
mi-distance », et le rez-de-chaussée perdrait ses enseignes sous le nez du passant.

On fait donc de **chaque gradin un objet**, avec sa boîte :

```gdscript
		_mesh.commit(_root)
		if occluders:
			_add_occluder(tiers[index])
```

`commit()` est appelé après chaque gradin : ce qui a été émis depuis le dernier appel devient ses
propres nœuds, avec sa propre boîte. Le pied de la tour et le couronnement ont aussi la leur. Le
prix : plus d'objets de près (70 pour la tour de brique, contre 45 à l'étape 012). Le gain : de
loin, 26.

### 4. Remplacer, enlever, alléger

| Pièce | De près | À mi-distance | De loin |
|---|---|---|---|
| Chaperons, bandeau du socle | profil extrudé | une boîte | une boîte |
| Piliers, bandeaux, fenêtres de brique | dessinés | dessinés | la façade lointaine |
| Rez-de-chaussée de brique : vitrines, bandeaux, pilastres | dessinés | dessinés | la façade lointaine |
| Enseignes, numéro, portes tambour | dessinés | rien | rien |
| Tirants de la marquise | dessinés, sans ombre | rien | rien |
| Mât du drapeau | dessiné, sans ombre | dessiné, sans ombre | rien |
| Pied du château d'eau | dessiné | dessiné | rien : la cuve reste |
| Ailettes de la tour de 1961 | dessinées, sans ombre | dessinées, sans ombre | rien : le shader dessine les meneaux |
| Mur-rideau, noyaux, toits, couronnes | dessinés | dessinés | dessinés |
| Lampadaires, feux, cheminée, métro | dessinés | dessinés | rien |

On **remplace** ce qui compte dans la silhouette (les chaperons, la façade entière). On
**enlève** ce qui ne se distingue plus (les textes, les tirants). Les tours de verre changent
peu : leur façade est déjà un seul rectangle par face depuis l'étape 007.

### 5. De loin, une façade est un rectangle

À 250 m, une brique fait moins d'un dixième de pixel, un pilier à peine un pixel : ce qu'on voit
d'une façade, c'est la teinte de son mur et la grille de ses fenêtres. Au-delà de la distance
lointaine, chaque façade de brique de chaque gradin devient **un seul rectangle**, posé au nu des
piliers, que le nouveau shader de la façade lointaine dessine :

```gdscript
	var left_edge: float = frame.origin.dot(frame.basis.x) - 0.5 * width
	_mesh.panel(Vector2(width, tier.top_y - tier.base_y), frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5 * (tier.base_y + tier.top_y), PIER_PROJECTION)),
			_materials.far_facade, Color(float(tier.first_floor), float(_first_column(tier.rect, side)), float(side), _margin(width)),
			Color(left_edge, tier.base_y, 0.0, 1.0))
```

Des centaines de boîtes et de fenêtres instanciées deviennent deux triangles. Une tour de brique
vue de loin passe de 13 334 triangles à 834.

**La bascule ne doit pas se voir.** C'est toute la difficulté : ce rectangle doit avoir, à
250 m, la même allure que tout ce qu'il remplace. Le shader reprend donc ce que les shaders de
près donnent à cette distance, en moyenne :

- **le mur** : la teinte moyenne des briques, avec les grandes plages et la suie du shader de la
  brique, calculées par les **mêmes bruits, aux mêmes endroits**. Pour cela, il lui faut les
  coordonnées du shader de la brique : la position le long du mur et la hauteur, dans le repère
  de la tour. La donnée de l'instance est déjà pleine (l'étage, la colonne, la façade, la
  marge) ; c'est la **teinte de l'instance**, `COLOR`, qui les porte. Elle ne sert pas à
  teindre : ce sont deux longueurs ;

```glsl
	v_start = COLOR.rg;
```

```glsl
	vec2 p = v_start + q + pattern_offset;
```

- **la fenêtre** : la part de vitre que laissent le dormant, les montants, les traverses et les
  petits bois, calculée avec les cotes du shader de la fenêtre. Dans cette part, ce qu'on voit
  derrière la vitre : la lumière moyenne d'une pièce, ou son store, baissé dans **les mêmes
  pièces** que de près ;

```glsl
	float r0 = pc_hash3(vec3(level, room_id, face + 17.0 + seed * 101.0));
```

- **la nuit** : chaque fenêtre est allumée ou éteinte comme de près, avec la même clé de tirage
  et la même règle. Quand la caméra passe la distance lointaine, la tour change de dessin sans
  qu'une fenêtre s'allume ou s'éteigne ;
- **le rez-de-chaussée** : le bandeau des enseignes, dans la teinte moyenne de la palette, et les
  vitrines.

Deux nombres du shader, la lumière moyenne d'une pièce de jour et celle de ses luminaires, n'ont
pas de formule simple : ils ont été **réglés en comparant des images** de près et de loin, prises
à la distance de la bascule, de jour et de nuit, jusqu'à ce que leurs teintes moyennes se
rejoignent. Résultat, sur la vue lointaine du quartier : la teinte moyenne de l'image ne diffère
pas d'un pour cent entre le quartier dessiné en entier et le quartier en façades lointaines.

Le parapet n'est pas dans le rectangle : là où le gradin du dessus ne continue pas la façade, un
pan de brique de la zone lointaine le remplace, avec `_wall_run()`, la fonction de l'étape 006.

### 6. L'occultation : une boîte par gradin

Une tour cache ce qui est derrière elle. Encore faut-il que le moteur le sache : il ne dessine
pas ses images pour savoir ce qu'elles cachent, ce serait trop cher. On lui donne donc, pour
chaque gradin, une forme simple qui cache : une **boîte d'occultation**.

```gdscript
	var box: BoxOccluder3D = BoxOccluder3D.new()
	box.size = Vector3(tier.rect.size.x - 1.0, tier.top_y - tier.base_y, tier.rect.size.y - 1.0)
	var occluder: OccluderInstance3D = OccluderInstance3D.new()
	occluder.occluder = box
```

À chaque image, le moteur dessine ces boîtes, sur le processeur, dans une petite image de
profondeur, puis ne dessine pas ce qu'elles cachent entièrement. La boîte est **un peu plus
petite que le gradin** : 50 cm de moins de chaque côté. Une boîte qui dépasserait de ses façades
cacherait ce qui est visible.

Il faut aussi l'autoriser dans les réglages du projet, sans quoi le moteur ignore les boîtes. Le
`project.godot` de cette étape a une ligne de plus, dans la section `[rendering]` :

```text
occlusion_culling/use_occlusion_culling=true
```

L'occultation n'est pas gratuite : ce petit rendu sur le processeur coûte à chaque image. Elle
convient à un décor qui ne bouge pas, comme celui-ci : une boîte se déplace rarement, ici
seulement quand la tour est reconstruite.

### 7. Qui porte une ombre

`set_zones()` a un second argument : la pièce porte-t-elle une ombre ?

```gdscript
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
```

Pour dessiner les ombres du soleil, le moteur redessine tout ce qui porte une ombre, une fois par
carte d'ombre. Une fenêtre au fond de sa baie ne projette rien : elle n'a pas à y passer. Ni les
ailettes, dont l'ombre serait un trait, ni le mur-rideau, dont le noyau porte l'ombre à sa place.
Au sol, la règle est simple : **ce qui est à plat ne porte pas d'ombre**, elle tomberait sous
lui. La chaussée, les trottoirs, les bandes des passages piétons. Ce qui tient debout (les
lampadaires, les feux) en porte une.

### 8. La finesse des shaders

Trois shaders ont un réglage de plus, `quality` :

| Finesse | Brique et pierre | Pièces derrière les vitres |
|---|---|---|
| Haute | tout, comme à l'étape 012 | tout : parois dessinées, stores, cloisons basses |
| Moyenne | une octave de moins par bruit | parois dessinées et stores, pas de cloisons |
| Basse | pas de coulures, bruits réduits | des parois d'une seule teinte, les luminaires devinés |

La façade lointaine suit le même réglage : moins d'octaves, et pas de stores en finesse basse,
comme de près.

Ce n'est pas la tour qui choisit la finesse : c'est un réglage de la machine. `set_quality()` le
change sans rien reconstruire, de la visite vers le quartier, du quartier vers chaque tour, de la
tour vers ses matériaux. La touche P fait défiler les trois qualités, qui règlent aussi les
ombres, l'anticrénelage et la résolution du rendu ; si les images mettent trop longtemps, la
visite baisse la qualité toute seule.

### 9. La visite compte ce qu'elle dessine

```gdscript
func _drawn(type: Viewport.RenderInfoType, info: Viewport.RenderInfo) -> int:
	return get_viewport().get_render_info(type, info)
```

`Viewport.get_render_info()` dit ce que le moteur a dessiné pendant la dernière image : des
objets (un nœud de maillage est un objet), des triangles, des appels de dessin, pour l'image et
pour les cartes d'ombre. La seconde ligne de la mesure les affiche. Ces nombres ne dépendent pas
de la machine : c'est sur eux qu'on juge un niveau de détail. Le moteur Compatibilité ne compte
pas les objets des ombres, seulement leurs triangles.

### 10. Le quartier, ses tours et son mobilier

Le quartier donne ses distances et son réglage d'occultation à chacune de ses tours, avant de les
ajouter à l'arbre. Son propre mobilier vit dans les zones proche et moyenne : il disparaît au-delà
de la distance lointaine. Comme pour les tours, chaque îlot est un objet, avec sa boîte : les
distances se comptent depuis son centre, pas depuis celui du quartier. La chaussée et les
trottoirs, qui couvrent tout le quartier, ont leurs propres nœuds, sans distances.

### 11. Le test

Le test de `7_tests` vérifie trois choses de plus :

- de près, tout ce qui vit dans la zone proche est bien là (87 344 triangles pour le quartier,
  comme à l'étape 012), et plus loin on dessine moins ;
- chaque boîte d'occultation reste **dans** ce que sa tour dessine : une boîte qui dépasserait
  cacherait des choses visibles ;
- sans occultation, la tour ne pose plus une seule boîte.

## Ce que ça donne

| | De près (30 m) | À mi-distance (155 m) | De loin (300 m) |
|---|---|---|---|
| Tour de brique : triangles | 13 334 | 12 442 | 834 |
| Tour de brique : objets à dessiner | 70 | 36 | 26 |
| dont textes | 31 | 0 | 0 |
| Tour de verre de 1961 : triangles | 3 104 | 2 500 | 152 |
| Tour tout en verre : triangles | 920 | 316 | 208 |
| Le quartier : triangles | 87 344 | 75 280 | 7 894 |
| Le quartier : objets à dessiner | 541 | 354 | 254 |
| Le quartier : boîtes d'occultation | 41 | 41 | 41 |

Pour le quartier, chaque colonne suppose que tout est à cette distance ; dans une vraie vue,
les tours se répartissent entre les trois.

## Ce qu'il faut retenir

1. Compter avant de toucher : objets, triangles, appels de dessin. Le temps dépend de la machine,
   les nombres non.
2. Un niveau de détail se décide pièce par pièce, au moment où on la fabrique.
3. Un objet haut se découpe en plusieurs objets : la distance se compte jusqu'au centre de
   chacun.
4. Une façade lointaine peut remplacer des centaines de pièces, à condition de reprendre leur
   allure moyenne : mêmes bruits aux mêmes endroits, mêmes tirages, mêmes fenêtres allumées.
5. L'occultation cache ce qui est derrière une tour, avec des boîtes plus petites que ce qu'elles
   représentent.

## À essayer

- Dans la scène du quartier, `near_distance` et `far_distance` à 0, puis F5 : le quartier sans
  niveaux de détail. Comparer la seconde ligne de mesure.
- `far_distance` à 120 : s'approcher d'une tour de brique, lentement, et guetter la bascule.
- `occluders` à faux, puis marcher dans une rue transversale en regardant le nombre d'objets.
- P pendant la visite, en regardant un mur de brique de près, puis le quartier entier.
- Dans le shader de la façade lointaine, `ROOM_LAMPS` à 0,6, puis N : de loin, les fenêtres
  allumées sont trop claires, et la bascule se voit.
{TWIN}
## Ce qui a été vérifié

- Le projet s'importe sans erreur dans Godot 4.7.2 et tous ses scripts passent la vérification
  du moteur, avertissements compris.
- Le test passe : construction, reconstruction à l'identique, les deux règlements, huit graines,
  niveaux de détail, occultation.
- La façade lointaine a été comparée au dessin de près, à la distance de la bascule : de jour, à
  2 à 4 % près sur la teinte moyenne des étages ; de nuit, à 5 à 10 % près ; et à 1 % près sur la
  vue lointaine du quartier entier, de jour.
- Le quartier a été rendu et mesuré avec et sans niveaux de détail, avec et sans occultation,
  en Compatibilité et en Forward+.

Ce qui n'a pas pu l'être :

- **Le temps d'affichage sur une vraie carte graphique.** Toutes les mesures de temps viennent
  d'un rendu logiciel. La ligne de mesure de la visite donne le vrai chiffre.
- La bascule pendant un déplacement : elle a été vérifiée par des images fixes, pas en mouvement.

## Limites

- La bascule est franche : pas de fondu entre deux niveaux. De loin, la façade lointaine a la
  teinte moyenne de la façade de près, pas son grain : un œil attentif voit la bascule des
  fenêtres allumées la nuit, plus douces de loin.
- La façade lointaine est plate : les ombres des piliers dans les tableaux des fenêtres
  disparaissent au-delà de 250 m.
- Découper la tour en gradins multiplie les objets de près : 541 pour le quartier, contre 317 à
  l'étape 012. C'est le prix de distances justes sur des objets hauts.
- L'occultation ne cache que des objets entiers : un gradin à moitié caché est dessiné en
  entier.

## Sources

- Distances de visibilité : référence des classes de Godot 4.7.2,
  `doc/classes/GeometryInstance3D.xml` (`visibility_range_begin`, `visibility_range_end`).
- Distance mesurée au centre de la boîte englobante : code source de Godot 4.7.2,
  `servers/rendering/renderer_scene_cull.cpp`.
- Occultation : référence des classes de Godot 4.7.2, `OccluderInstance3D`, `BoxOccluder3D`, et
  le réglage `rendering/occlusion_culling/use_occlusion_culling` de `ProjectSettings` : un rendu
  sur le processeur, qui convient aux occulteurs qu'on déplace rarement, par exemple à la
  génération procédurale.
- Ce que le moteur a dessiné : `Viewport.get_render_info()`, même référence.
