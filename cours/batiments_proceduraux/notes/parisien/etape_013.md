# Paris · étape 013 · Niveaux de détail : ne dessiner que ce qui se voit

**Piste : Performance.** La rue de l'étape 012 est juste, mais elle rame. Un immeuble
procédural n'est pas léger par nature : il est léger si on lui apprend à ne dessiner que ce
qui se voit. C'est l'objet de cette étape, et c'est le projet à utiliser.

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
étape est encadré par `>>> NOUVEAU À L'ÉTAPE 013` et `<<< FIN DU NOUVEAU`.

## Le diagnostic : où part le temps

Mesuré sur la rue par défaut, 1280 × 720, en rendu logiciel (sur processeur, sans carte
graphique). Les proportions seront différentes sur une vraie carte graphique ; l'ordre de
grandeur des gains, lui, est le bon signal.

| Projet | Temps par image | Par rapport au départ |
|---|---|---|
| Étape 012, telle que livrée la première fois | 1 515 ms | — |
| Étape 012, réglages du moteur allégés | 401 ms | −74 % |
| Étape 013, qualité haute | 1 111 ms | −27 % |
| Étape 013, qualité moyenne (par défaut) | 301 ms | −80 % |
| Étape 013, qualité basse | 189 ms | −88 % |

Trois causes, de la plus lourde à la plus légère dans cette mesure :

1. **Les réglages du moteur.** Le premier projet demandait un anticrénelage MSAA 4×, des
   ombres douces en qualité haute sur quatre cartes d'ombre, et un rendu à pleine résolution.
2. **Le détail au loin.** À 100 m, un immeuble envoyait encore ses 12 000 triangles, dont les
   denticules de sa corniche, plus petits qu'un pixel. Et tout portait une ombre.
3. **Le shader de pierre.** Trente bruits par pixel, sur presque tout l'écran.

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer avant de toucher

On ne corrige pas une lenteur au jugé. La visite sait mesurer :

```
godot --path . -- --bench=60 --quality=1
```

rend 60 images, écrit le temps moyen dans la console et quitte. C'est avec cette commande que
le tableau ci-dessus a été rempli, en changeant une chose à la fois.

### 2. Trois zones de distance

L'immeuble a deux variables de plus, dans le groupe « Niveaux de détail » :

| Variable | Défaut | Effet |
|---|---|---|
| `near_distance` | 30 m | Jusque-là, l'immeuble est dessiné en entier. |
| `far_distance` | 90 m | Au-delà, il ne reste que les murs, les fenêtres, les balcons et le toit. |

Elles découpent l'espace en trois zones : proche, moyenne, lointaine. Mettre les deux à 0
coupe les niveaux de détail : on retrouve l'immeuble de l'étape 012.

La rue a les mêmes variables et les donne à chacun de ses immeubles.

### 3. Dire à chaque pièce où elle vit : `set_zones()`

Toute la mécanique est dans l'outil de maillage, `1_core/procedural/mesh_builder.gd`. Avant
d'émettre une pièce, on lui dit dans quelles zones elle sera dessinée :

```gdscript
_mesh.set_zones(MeshBuilder.ZONE_NEAR)                         # ce qui suit : de près seulement
_mesh.extrude(Profiles.cornice(...), ...)                      # le profil de la corniche
_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)   # ce qui suit : au-delà
_mesh.box(...)                                                 # deux boîtes à la place
_mesh.set_zones(MeshBuilder.ZONE_ALL)                          # retour à la normale
```

Jusqu'ici l'outil rangeait les triangles par matériau. Il les range maintenant par matériau
**et par case** : une case est une combinaison de zones. À la fin, `commit()` fait un maillage
par matériau et par case, et règle sur chacun deux propriétés que tout nœud de géométrie de
Godot possède :

```gdscript
instance.visibility_range_begin = begin   # distance où la pièce apparaît
instance.visibility_range_end = end       # distance où elle disparaît
```

C'est ensuite le moteur qui affiche ou cache chaque maillage, à chaque image, d'après la
distance de la caméra. **Aucun script ne tourne pendant le jeu.**

### 4. Remplacer, pas seulement enlever

Si on se contentait de cacher les ornements, l'immeuble perdrait sa corniche au loin, et sa
silhouette changerait. Chaque ornement qui compte dans la silhouette a donc une version simple
qui prend sa place :

| Pièce | De près | Au-delà |
|---|---|---|
| Corniche | profil extrudé, denticules, modillons | deux boîtes |
| Bandeau entre deux niveaux | profil extrudé | une boîte |
| Lucarne | sa forme : cintrée, à fronton, œil-de-bœuf | une boîte et une fenêtre droite |
| Mitron de cheminée | douze pans | six pans, puis rien |
| Chambranles, appuis, clefs, consoles | dessinés | rien |
| Garde-corps, enseignes | dessinés | dessinés à mi-distance, puis rien |

Le code des versions simples existait déjà : c'est celui du niveau d'ornement « Nu » de
l'étape 008. **De loin, un immeuble riche redevient un immeuble nu.**

### 5. Une seule boîte englobante pour tout l'immeuble

Le moteur mesure la distance entre la caméra et le **centre de la boîte englobante** de chaque
maillage. Or le maillage des ornements et celui de leurs versions simples n'ont pas la même
boîte, donc pas le même centre : ils ne basculeraient pas au même moment. On verrait les deux
à la fois, ou aucun.

`commit()` donne donc à tous les maillages d'un immeuble la même boîte, celle de l'immeuble
entier, par la propriété `custom_aabb`. La bascule se fait alors d'un coup.

Pour la même raison, les distances n'ont pas de marge (`visibility_range_begin_margin` et
`visibility_range_end_margin` restent à 0). D'après le code du moteur, une pièce cachée ne
réapparaît que lorsque la caméra a dépassé la limite de toute la marge : dans cette bande, un
ornement et sa version simple peuvent être cachés tous les deux. Ce comportement n'a pas été
observé à l'écran : il est tiré de la lecture du code, et le cours s'en tient à des distances
sans marge.

### 6. Qui porte une ombre

`set_zones()` a un second argument : la pièce porte-t-elle une ombre ?

```gdscript
_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)   # de près, et sans ombre portée
```

Pour dessiner les ombres du soleil, le moteur redessine tout ce qui porte une ombre, une fois
par carte d'ombre. Un denticule de 8 cm ne projette rien de visible : il n'a pas à y passer.
Les fenêtres non plus, au fond de leur baie. De près, un immeuble dessine toujours ses
12 443 triangles, mais seuls 2 865 portent une ombre.

### 7. Ne pas créer une case pour douze triangles

Chaque case devient un maillage, donc un appel de dessin de plus. Sortir trois baguettes de
zinc dans une case à part coûterait plus cher que de les dessiner toujours. Les petites pièces
restent donc dans la case commune, celle de toutes les zones. La règle : une case se justifie
par des centaines de triangles, pas par une douzaine.

### 8. La finesse du shader de pierre

Le shader de pierre a un réglage de plus, `quality` :

| Finesse | Ce qui est calculé | Bruits par pixel, de près |
|---|---|---|
| Haute | tout, comme à l'étape 012 | 30 |
| Moyenne | sans les arêtes épaufrées, les piqûres, la dérive de teinte, le détail des coulures ; moins d'octaves | 14 |
| Basse | blocs, joints, grandes plages de teinte et de suie | 4 |

Dans le shader, ce sont de simples tests :

```glsl
bool high = quality >= 2;
if (high) {
	float tone = pc_fbm2(p * 0.8 + vec2(9.0, 61.0), 3, fw * 0.8);
	...
}
```

Le test porte sur un uniforme, pas sur le pixel : tous les pixels prennent la même branche, et
la carte graphique n'exécute que celle-là.

Ce n'est pas le script de l'immeuble qui choisit la finesse : c'est un réglage de la machine,
pas une variable de l'immeuble. `set_quality()` le change sans rien reconstruire, de la visite
vers la rue, de la rue vers chaque immeuble, de l'immeuble vers ses matériaux.

À noter : les shaders avaient déjà un niveau de détail depuis l'étape 003. Les octaves de
bruit plus fines que le pixel ne sont pas calculées. C'est ce qui allège la pierre au loin.

### 9. Les réglages du moteur, et la touche P

La visite range tout ce qui coûte dans trois qualités :

| | Basse | Moyenne | Haute |
|---|---|---|---|
| Finesse du shader de pierre | basse | moyenne | haute |
| Cartes d'ombre du soleil | 1, jusqu'à 60 m | 2, jusqu'à 100 m | 4, jusqu'à 160 m |
| Bord des ombres | très peu adouci | peu adouci | très adouci |
| Anticrénelage | lissage FXAA | lissage FXAA | MSAA 4× |
| Résolution du rendu 3D | 75 % | 100 % | 100 % |

Le lissage FXAA n'existe pas dans le moteur de rendu Compatibilité : il n'y a alors pas
d'anticrénelage en qualité basse et moyenne.

Les projets des étapes 001 à 012 ont les réglages du moteur de la qualité moyenne, sans la
touche P ; leur shader de pierre, lui, calcule tout, comme en qualité haute.

### 10. Le test

Le test de `7_tests` vérifie deux choses de plus : de près, tout ce qui vit dans la zone
proche est bien là (12 443 triangles, comme à l'étape 012) ; et plus loin, on dessine moins.

## Ce que ça donne

Triangles dessinés pour un immeuble de 5 travées, selon la distance :

| | De près | À mi-distance | De loin |
|---|---|---|---|
| Triangles dessinés | 12 443 | 2 271 | 2 057 |
| dont portant une ombre | 2 865 | 1 989 | 1 989 |
| Appels de dessin | 27 | 21 | 15 |

À l'étape 012, les 12 443 triangles étaient dessinés à toute distance, et tous portaient une
ombre.

Le temps par image est dans le tableau du diagnostic.

## Ce qu'il faut retenir

1. Mesurer d'abord, changer une chose à la fois.
2. Un niveau de détail se décide pièce par pièce, au moment où on la fabrique : c'est là qu'on
   sait si c'est un mur ou un denticule.
3. On remplace ce qui compte dans la silhouette, on enlève le reste.
4. Le moteur sait faire la bascule : `visibility_range_begin` et `visibility_range_end`.
5. Les réglages du moteur pèsent souvent plus lourd que le contenu.

## À essayer

- Dans la scène de la rue, `near_distance` et `far_distance` à 0, puis F5 : la rue sans niveaux
  de détail. Comparer le temps par image.
- `near_distance` à 12 : la bascule se voit, sur les immeubles d'en face. À 60 : elle ne se
  voit plus, et on gagne moins.
- P pendant la visite, en regardant un mur de près puis la rue entière.
- Dans `{NAME}.gd`, passer un `set_zones` de `ZONE_NEAR` à `ZONE_ALL` : la pièce reste visible
  au loin.

## Ce qui a été vérifié

- Le projet s'importe sans erreur dans Godot 4.7.2 et tous ses scripts passent la vérification
  du moteur.
- Le test passe : construction, reconstruction à l'identique, gabarit de la rue, niveaux de
  détail.
- Un immeuble seul a été rendu de près, à mi-distance et de loin : aucune pièce ne manque,
  la corniche, les bandeaux et les lucarnes sont présents aux trois distances.
- La rue a été rendue aux trois qualités.
- En qualité moyenne, la rue a été rendue avec les trois moteurs de rendu de Godot
  (Compatibilité, Forward+, Mobile), sans erreur ni avertissement. Les qualités basse et haute
  ont été rendues en Compatibilité seulement.

Ce qui n'a pas pu l'être :

- **Le temps d'affichage sur une vraie carte graphique.** Toutes les mesures viennent d'un rendu
  logiciel. La ligne de mesure de la visite donne le vrai chiffre sur la machine où elle tourne.
- La bascule entre deux niveaux pendant un déplacement : elle a été vérifiée par des images fixes
  à trois distances, pas en mouvement.

## Limites

- La bascule est franche : pas de fondu entre deux niveaux. Elle se voit si on la cherche, à
  30 m, sur les chambranles.
- De loin, un immeuble compte encore 2 000 triangles et une quinzaine d'appels de dessin. Pour
  une ville entière, l'étape suivante serait de remplacer une façade lointaine par un seul
  rectangle et un shader qui dessine les fenêtres.
- Les matériaux ne sont pas partagés entre immeubles : chacun a les siens.
- Seul le shader de pierre a un réglage de finesse. Celui de la fenêtre calcule toujours sa
  pièce entière.

## Sources

- Distances de visibilité, marges, absence de fondu hors Forward+ : référence des classes de
  Godot 4.7.2, `doc/classes/GeometryInstance3D.xml` (`visibility_range_begin`,
  `visibility_range_end`, `visibility_range_begin_margin`, `visibility_range_fade_mode`).
- Distance mesurée au centre de la boîte englobante, et comportement des marges : code source
  de Godot 4.7.2, `servers/rendering/renderer_scene_cull.cpp`, fonctions
  `_update_instance_visibility_dependencies` et `_visibility_range_check`.
{TWIN}
