# Tokyo · étape 013 · Niveaux de détail : ne dessiner que ce qui se voit

**Piste : Performance.** La rue de l'étape 012 est juste, mais elle dessine tout, partout :
les fils d'un poteau à 150 m, plus fins qu'un pixel ; le texte d'une enseigne qu'on ne peut
plus lire ; les barreaux d'un balcon qu'on ne distingue plus. Un décor procédural n'est pas
léger par nature : il l'est si on lui apprend à ne dessiner que ce qui se voit. C'est l'objet
de cette étape, et c'est le projet à utiliser.

Rien ne change dans l'image de près. Ce qui change : ce qu'on dessine au loin, ce qui porte
une ombre, la finesse des shaders, et les réglages du moteur.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer avec F5 : on est dans la rue.
3. Clic droit maintenu et souris : regarder. ZQSD : se déplacer. A et E : descendre, monter.
   Maj : aller vite. **N** : jour ou nuit. **F** : recadrer. Échap : quitter.
4. **P** : qualité basse, moyenne, haute. **R** : résolution du rendu 3D. **V** : synchro
   verticale.

La ligne de mesure, en haut de l'écran, donne le temps par image, la qualité en cours, la
résolution du rendu et le nom de la carte graphique. La visite démarre en qualité moyenne. Si
une image met plus de 40 ms pendant une seconde et demie, elle baisse la qualité d'un cran,
toute seule, et l'écrit sur cette ligne. Appuyer sur P ou R reprend la main.

Une seconde ligne dit ce que le moteur a dessiné pendant la dernière image : combien d'objets,
de triangles et d'appels de dessin, pour l'image puis pour les ombres. Ces nombres ne dépendent
pas de la machine : ce sont eux que les niveaux de détail font baisser. (Le moteur Compatibilité
ne compte pas les objets des ombres, seulement leurs triangles.)

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Dans chaque fichier modifié, le code de cette
étape est encadré par `>>> NOUVEAU À L'ÉTAPE 013` et `<<< FIN DU NOUVEAU`. Commencer par
`1_core/procedural/mesh_builder.gd` : toute la mécanique y est.

## Le diagnostic : mesurer avant de toucher

On ne corrige pas une lenteur au jugé. La visite sait mesurer :

```text
godot --path . -- --bench=60 --quality=1
```

rend 60 images, écrit le temps moyen dans la console et quitte.

Mesuré sur la rue par défaut, 1280 × 720, moteur Compatibilité, en rendu logiciel (sur
processeur, sans carte graphique). Les proportions seront différentes sur une vraie carte
graphique. Les trois premières lignes sont la moyenne de deux passages de 90 images ; la
deuxième a été mesurée avec `--set-near_distance=0.0 --set-far_distance=0.0`, qui coupe les
niveaux de détail de la rue.

| Projet | Temps par image | Par rapport à l'étape 012 |
|---|---|---|
| Étape 012 | 272 ms | — |
| Étape 013, qualité moyenne, niveaux de détail coupés | 255 ms | −7 % |
| Étape 013, qualité moyenne (par défaut) | 253 ms | −7 % |
| Étape 013, qualité basse | 151 ms | −44 % |
| Étape 013, qualité haute | 1 258 ms | +362 % |

Il faut lire ce tableau honnêtement. L'étape 012 a déjà les réglages du moteur de la
qualité moyenne. D'elle à l'étape 013 en qualité moyenne, trois choses changent : les
niveaux de détail, les petites pièces qui ne portent plus d'ombre, et des shaders de mur un
peu allégés. La deuxième ligne isole la première : sans niveaux de détail, 255 ms ; avec,
253 ms. L'écart est plus petit que la dispersion de la mesure, puisque deux passages du même
réglage diffèrent ici jusqu'à 7 %. Dans cette mesure, les niveaux de détail ne changent donc
pas le temps par image : le gain sur l'étape 012 vient des deux autres changements.

La rue de Tokyo est déjà légère : 45 000 triangles, contre 176 000 pour la rue de Paris. Ce
qui coûte, ici, ce sont les pixels : les shaders de mur sur tout l'écran, et les ombres.
C'est la qualité basse qui s'y attaque, et la qualité haute qui les multiplie.

Ce que les niveaux de détail réduisent vraiment se compte autrement : en objets à dessiner.
La rue passe de 736 objets à 372 quand elle est vue de loin, et de 117 textes à aucun. Sur une
vraie carte graphique, où chaque objet demande un appel de dessin, c'est ce nombre qui pèse.

## Ce qu'on a fait, dans l'ordre

### 1. Trois zones de distance

L'immeuble a deux variables de plus, dans le groupe « Niveaux de détail » :

| Variable | Défaut | Effet |
|---|---|---|
| `near_distance` | 30 m | Jusque-là, l'immeuble est dessiné en entier. |
| `far_distance` | 90 m | Au-delà, il ne reste que les murs, les fenêtres, les balcons et les caissons d'enseigne. |

Elles découpent l'espace en trois zones : proche, moyenne, lointaine. Mettre les deux à 0
coupe les niveaux de détail : on retrouve l'immeuble de l'étape 012.

La rue a les mêmes variables. Elle les donne à chacun de ses immeubles, et à chacun de ses
poteaux.

### 2. Dire à chaque pièce où elle vit : `set_zones()`

Toute la mécanique est dans l'outil de maillage, `1_core/procedural/mesh_builder.gd`. Avant
d'émettre une pièce, on lui dit dans quelles zones elle sera dessinée :

```gdscript
	_mesh.set_zones(MeshBuilder.ZONE_NEAR)
	_mesh.extrude(Profiles.canopy(canopy_depth, 0.08), MeshBuilder.along_x(Vector3(0.0, y, 0.0)), width, _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
	_mesh.box(Vector3(width, 0.1, canopy_depth), Vector3(0.0, y + 0.05, 0.5 * canopy_depth), _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
```

C'est l'auvent : de près, le profil de tôle pliée ; au-delà, une boîte de la même taille ;
puis retour à la normale, pour que la suite n'hérite pas d'une zone.

Jusqu'ici l'outil rangeait les triangles par matériau. Il les range maintenant par matériau
**et par case** : une case est une combinaison de zones. À la fin, `commit()` fait un
maillage par matériau et par case, et règle sur chacun deux propriétés que tout nœud de
géométrie de Godot possède :

```gdscript
	instance.visibility_range_begin = begin
	instance.visibility_range_end = end
```

La première est la distance où la pièce apparaît, la seconde celle où elle disparaît. C'est
ensuite le moteur qui affiche ou cache chaque maillage, à chaque image, d'après la distance
de la caméra. **Aucun script ne tourne pendant le jeu.**

### 3. Remplacer, enlever, ou alléger

Trois traitements, selon la pièce :

| Pièce | De près | À mi-distance | De loin |
|---|---|---|---|
| Auvent, couvertine | profil extrudé | une boîte | une boîte |
| Réservoir d'eau | seize pans | huit pans | huit pans |
| Descente d'eau | huit pans, colliers, coude | cinq pans | rien |
| Garde-corps à barreaux | dessiné, avec son ombre | dessiné, sans ombre | rien |
| Climatiseur | boîte et grille | boîte | rien |
| Appui de fenêtre, antenne | dessinés | rien | rien |
| Face d'une enseigne | fond uni, et vrai texte | fausse écriture | fausse écriture |
| Lanterne, noren, affichettes | dessinés | dessinés | rien |
| Fils électriques | leur vraie grosseur | deux fois plus gros | rien |

On **remplace** ce qui compte dans la silhouette (l'auvent, la couvertine, le réservoir). On
**enlève** ce qui ne se distingue plus (les appuis, l'antenne). On **allège** ce qui reste
visible mais n'a plus besoin de ses détails (les tuyaux).

### 4. Les enseignes : du vrai texte de près, du faux au-delà

C'est le niveau de détail le plus payant de la rue. Un `Label3D` est un nœud, donc un objet
à dessiner de plus pour chaque enseigne ; la rue en compte 117. Au-delà de 30 m, on ne lit
plus ce texte : on voit seulement qu'il y en a.

```gdscript
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
	mesh.panel(size, frame, materials.signage, Color(0.0, 0.0, seed_value, KIND_LIGHT_BOX), color)
	mesh.node(_label(text, ink_for(color), frame, size, vertical))
	mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR, false)
	mesh.panel(size, frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, FAR_OFFSET)), materials.signage,
			Color(float(text.length()), 1.0 if vertical else 0.0, seed_value, KIND_LIGHT_BOX), color)
```

De près : la face, sans rien d'écrit, et le vrai texte par-dessus. Au-delà : la même face,
à qui la donnée de l'instance dit combien de caractères écrire, et dans quel sens. Le shader
les invente, avec la fonction `glyph()` de l'étape 010 : trois traits horizontaux et trois
verticaux par caractère. Cela ne veut rien dire, mais cela a la densité d'un idéogramme.

Pour que la bascule se voie le moins possible, le shader place ses faux caractères comme le
`Label3D` place les vrais : à la même taille, serrés, au milieu du panneau.

```glsl
		float side = min(0.62 * breadth, 0.9 * run / (glyph_count * (vertical ? 1.08 : 1.0)));
		float start = 0.5 * (run - pitch * glyph_count);
```

Ce sont les nombres de `_label()`, dans `…_enseignes.gd` : un caractère mesure au plus les
62 centièmes du panneau en travers de la ligne (sa hauteur, pour une écriture horizontale),
et les caractères se partagent les 9 dixièmes de sa longueur. Aux étapes 010 à 012, les faux
caractères s'étalaient sur toute la longueur : ils ne remplaçaient encore aucun vrai texte.

Toutes ces faces sont des rectangles instanciés du même matériau : un seul objet à dessiner
pour toutes les enseignes d'un immeuble, au lieu d'un par texte. Et le shader applique
encore le même filtrage : de plus loin, un faux caractère devient un pavé gris de la même
densité.

`mesh.node()` range le `Label3D` dans la case courante, comme une pièce ordinaire, et
`commit()` lui donne ses distances.

### 5. De loin, jamais deux faces trop proches

La face lointaine d'une enseigne est posée 3 cm devant son caisson (`FAR_OFFSET`), alors
que la face proche est à 4 mm. Ce n'est pas un détail.

La carte graphique range la profondeur de chaque pixel avec une précision qui diminue quand
on s'éloigne. À 100 m, dans le moteur Compatibilité, elle ne distingue plus deux faces
séparées de quelques millimètres : elles se disputent les mêmes pixels, et l'enseigne se
couvre de rayures. De près, 4 mm suffisent.

Règle pour tout ce qui vit dans les zones moyenne et lointaine : au moins 3 cm entre deux
faces parallèles. C'est aussi pour cela que la ligne blanche de la rue est posée à côté de la
chaussée, pas dessus.

### 6. Une seule boîte englobante pour tout l'immeuble

Le moteur mesure la distance entre la caméra et le **centre de la boîte englobante** de
chaque maillage. Or le maillage des pièces fines et celui de leurs versions simples n'ont pas
la même boîte, donc pas le même centre : ils ne basculeraient pas au même moment. On verrait
les deux à la fois, ou aucun.

`commit()` donne donc à tous les maillages d'un immeuble la même boîte, celle de l'immeuble
entier, par la propriété `custom_aabb`. La bascule se fait alors d'un coup.

Pour la même raison, les distances n'ont pas de marge. D'après le code du moteur, une pièce
cachée ne réapparaît que lorsque la caméra a dépassé la limite de toute la marge : dans cette
bande, une pièce et sa version simple pourraient être cachées toutes les deux. Ce
comportement n'a pas été observé à l'écran : il est tiré de la lecture du code, et le cours
s'en tient à des distances sans marge.

### 7. Les poteaux et leurs fils

Chaque poteau a son propre outil de maillage depuis l'étape 012 : il est donc un objet, avec
sa boîte englobante et sa distance. Il reçoit les distances de la rue :

```gdscript
		mesh.near_distance = near_distance
		mesh.far_distance = far_distance
```

Avec le champ de vision de la visite, un fil de 2 cm est plus fin qu'un pixel dès une
quinzaine de mètres en 1280 × 720, une vingtaine en 1920 × 1080. Dessiné tel quel, il se lit
en pointillés. Il est donc émis deux fois :

```gdscript
		for zone: int in [MeshBuilder.ZONE_NEAR, MeshBuilder.ZONE_MID]:
			mesh.set_zones(zone, false)
			var swell: float = 1.0 if zone == MeshBuilder.ZONE_NEAR else 2.0
```

De près, sa vraie grosseur. À mi-distance, le double : c'est faux, et c'est ce qui le garde
lisible. De loin, plus rien. Un niveau de détail peut grossir une pièce au lieu de la
simplifier.

### 8. Qui porte une ombre

`set_zones()` a un second argument : la pièce porte-t-elle une ombre ?

```gdscript
		_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
```

Pour dessiner les ombres du soleil, le moteur redessine tout ce qui porte une ombre, une
fois par carte d'ombre. Une fenêtre au fond de sa baie ne projette rien : elle n'a pas à y
passer. Ni les fils, ni les faces des enseignes, ni les appuis. Dans la rue vue de près,
253 objets sur 736 portent une ombre.

### 9. La finesse des shaders de mur

Le carrelage et le béton ont un réglage de plus, `quality` :

| Finesse | Carrelage : ce qui est calculé | Octaves de bruit par pixel |
|---|---|---|
| Haute | tout, comme à l'étape 012 | 15 |
| Moyenne | tout, avec une octave de moins par bruit | 11 |
| Basse | carreaux, joints, grandes plages de teinte et de crasse ; pas de coulures | 3 |

Ces nombres sont ceux du pied d'un mur vu de près, le pire cas : plus haut, la salissure
du pied de mur ne coûte plus rien, et de loin les octaves plus fines que le pixel ne sont
pas calculées.

Dans le shader, ce sont de simples tests :

```glsl
	bool medium = quality >= 1;
	if (streaks > 0.0 && medium) {
```

Le test porte sur un uniforme, pas sur le pixel : tous les pixels prennent la même branche.

Ce n'est pas le script de l'immeuble qui choisit la finesse : c'est un réglage de la
machine, pas une variable de l'immeuble. `set_quality()` le change sans rien reconstruire, de
la visite vers la rue, de la rue vers chaque immeuble, de l'immeuble vers ses matériaux.

À noter : les shaders avaient déjà un niveau de détail depuis l'étape 003. Les octaves de
bruit plus fines que le pixel ne sont pas calculées, et un carreau plus petit que le pixel
prend la teinte moyenne.

### 10. Les réglages du moteur, et la touche P

La visite range tout ce qui coûte dans trois qualités :

| | Basse | Moyenne | Haute |
|---|---|---|---|
| Finesse des shaders de mur | basse | moyenne | haute |
| Cartes d'ombre du soleil | 1, jusqu'à 60 m | 2, jusqu'à 100 m | 4, jusqu'à 160 m |
| Bord des ombres | très peu adouci | peu adouci | très adouci |
| Anticrénelage | lissage FXAA | lissage FXAA | MSAA 4× |
| Résolution du rendu 3D | 75 % | 100 % | 100 % |

Le lissage FXAA n'existe pas dans le moteur de rendu Compatibilité : il n'y a alors pas
d'anticrénelage en qualité basse et moyenne.

Les projets des étapes 001 à 012 ont les réglages du moteur de la qualité moyenne, sans la
touche P ; leurs shaders de mur, eux, calculent tout, comme en qualité haute.

### 11. Le test

Le test de `7_tests` vérifie deux choses de plus : de près, tout ce qui vit dans la zone
proche est bien là (45 318 triangles pour la rue, comme à l'étape 012) ; et plus loin, on
dessine moins.

## Ce que ça donne

| | De près | À mi-distance | De loin |
|---|---|---|---|
| Un immeuble : triangles dessinés | 2 244 | 1 448 | 1 276 |
| Un immeuble : objets à dessiner | 35 | 20 | 13 |
| dont textes | 13 | 0 | 0 |
| La rue entière : triangles | 45 318 | 29 838 | 20 238 |
| La rue entière : objets à dessiner | 736 | 551 | 372 |

Pour la rue, chaque colonne suppose que tous les immeubles sont à cette distance ; dans une
vraie vue, ils se répartissent entre les trois.

## Ce qu'il faut retenir

1. Mesurer d'abord, et lire la mesure honnêtement : ici, les triangles n'étaient pas le
   problème.
2. Un niveau de détail se décide pièce par pièce, au moment où on la fabrique.
3. Remplacer ce qui compte dans la silhouette, enlever le reste, parfois grossir.
4. Du vrai texte coûte un objet par enseigne ; un shader peut en donner l'illusion pour rien.
5. Le moteur sait faire la bascule : `visibility_range_begin` et `visibility_range_end`.
6. De loin, jamais deux faces à moins de 3 cm l'une de l'autre.

## À essayer

- Dans la scène de la rue, `near_distance` et `far_distance` à 0, puis F5 : la rue sans
  niveaux de détail.
- `near_distance` à 12 : la bascule se voit, sur les enseignes d'en face. Le vrai texte
  devient de la fausse écriture.
- P pendant la visite, en regardant un mur de près puis la rue entière.
- Dans `…_enseignes.gd`, mettre `FAR_OFFSET` à 0,002, lancer en Compatibilité et regarder une
  enseigne lointaine.
- Dans `…_rue.gd`, mettre `swell` à 1 dans les deux zones : les fils du fond de la rue se
  lisent en pointillés.

## Ce qui a été vérifié

- Le projet s'importe sans erreur dans Godot 4.7.2 et tous ses scripts passent la
  vérification du moteur, avertissements compris.
- Le test passe : construction, reconstruction à l'identique, gabarit oblique, niveaux de
  détail.
- Un immeuble seul a été rendu de près, à mi-distance et de loin : aucune pièce ne manque, et
  l'enseigne garde son fond et son écriture aux trois distances. De part et d'autre de la
  bascule, les faux caractères tombent à la place des vrais.
- La rue a été rendue aux trois qualités en Compatibilité, de jour et de nuit, et en qualité
  moyenne avec les deux autres moteurs de rendu (Forward+, Mobile), sans erreur.

Ce qui n'a pas pu l'être :

- **Le temps d'affichage sur une vraie carte graphique.** Toutes les mesures viennent d'un
  rendu logiciel. La ligne de mesure de la visite donne le vrai chiffre sur la machine où elle
  tourne.
- La bascule entre deux niveaux pendant un déplacement : elle a été vérifiée par des images
  fixes à trois distances, pas en mouvement.
- L'affichage des caractères japonais sous Windows : les rendus ont été faits sous Linux,
  avec une police Noto. La liste des polices vient de la documentation de Microsoft.

## Limites

- La bascule est franche : pas de fondu entre deux niveaux. Les faux caractères prennent la
  place et la taille des vrais, pas leur dessin : la bascule se voit si on la cherche, à
  30 m, sur une enseigne d'en face.
- La distance est comptée jusqu'au centre de l'immeuble, qui est à mi-hauteur et à
  mi-profondeur : au pied d'un immeuble de 20 m, son enseigne du rez-de-chaussée bascule un
  peu plus tôt qu'on ne s'y attend.
- Les matériaux ne sont pas partagés entre immeubles : chacun a les siens.
- Seuls les shaders de mur ont un réglage de finesse. Celui de la fenêtre calcule toujours sa
  pièce entière.

## Sources

- Distances de visibilité, marges, absence de fondu hors Forward+ : référence des classes de
  Godot 4.7.2, `doc/classes/GeometryInstance3D.xml` (`visibility_range_begin`,
  `visibility_range_end`, `visibility_range_begin_margin`, `visibility_range_fade_mode`).
- Distance mesurée au centre de la boîte englobante, et comportement des marges : code source
  de Godot 4.7.2, `servers/rendering/renderer_scene_cull.cpp`, fonctions
  `_update_instance_visibility_dependencies` et `_visibility_range_check`.
{TWIN}
