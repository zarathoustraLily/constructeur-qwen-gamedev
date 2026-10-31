# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent : « il faut que le niveau puisse etre joue sur un petit pc ». Deux étapes viennent d'ajouter
des effets : on revient à ce que coûte le décor. Avant d'y toucher, on mesure ce qu'il contient, puis chaque levier seul.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a mesuré d'abord

`outils/inventaire_dessin.gd` passe chaque maillage du saloon : 415 objets, 45 maillages, 4,75 millions de triangles au plus
détaillé. Tout maillage de plus de quelques triangles a déjà ses niveaux de détail (de 4 à 11), faits à l'import. Le plus
lourd n'est pas ce qu'on croyait : les moulures (97 × 10 384, un million de triangles), puis les bouteilles (22 × 22 016).
Les petits objets de moins de 2 m pèsent 1,2 million de triangles.

## Chaque levier, seul

`outils/essai_dessin.gd` essaie un réglage sans toucher au jeu, de quatre places dans la salle. Qualité basse, 1280 × 720, vue
de l'entrée (les quatre places vont dans le même sens) :

| Levier | Appels de dessin | Primitives | Carte |
| --- | --- | --- | --- |
| Rien | 592 | 3,56 M | 0,334 ms |
| Seuil des niveaux de détail à 4 px | 595 | 1,59 M | 0,261 ms |
| Seuil à 8 px | 592 | 1,09 M | 0,248 ms |
| Occulteurs (comptoir, murs) | 592 | 3,56 M | 0,334 ms |
| Seuil à 4 + une seule passe pour la lune | 414 | 1,37 M | 0,245 ms |
| Seuil à 4 + ombres coupées sous 2 m | 519 | 1,37 M | 0,261 ms |
| Seuil à 4 + portée de 22 m sous 1,3 m | 540 | 1,47 M | 0,262 ms |
| Les quatre retenus ensemble | 330 | 1,11 M | 0,239 ms |

Ce que ça apprend :
- **Le seuil des niveaux de détail** est le meilleur levier, de loin, pour une ligne de code. `Viewport.mesh_lod_threshold` dit
  quel écart de forme on tolère à l'écran : 1 pixel par défaut. Les maillages avaient leurs niveaux de détail depuis le début.
  Personne ne les laissait servir.
- **La lune** faisait quatre passes d'ombre sur tout le décor : `SHADOW_PARALLEL_4_SPLITS` est le réglage par défaut d'une
  lumière directionnelle. Les passes d'ombre comptées à l'étape 15 (64 → 3) ne comptaient pas la lune.
- **Les occulteurs ne servent à rien ici.** Le comptoir et les murs ne cachent aucun objet entier : la salle est un seul grand
  volume ouvert. Mesuré : 0 objet de moins, aux quatre places. On a vérifié que l'occlusion marchait bien, avec un mur géant en
  travers de la salle (1 028 → 769 objets). Le plan annonçait des occulteurs : on n'en met pas. Une optimisation se mesure : elle
  coûte du temps de processeur, et elle ne rend rien.
- **Une portée sur les bouteilles se voit** : à 20 m, celles des étagères du fond disparaissaient. On garde la portée pour les
  objets de moins de 1,3 m (verres, assiettes, livres), à 22 m.
- **Un fondu de portée coûte** : la référence dit `VISIBILITY_RANGE_FADE_SELF` plus lent que sans fondu, et la mesure le
  confirme : la carte a monté de 0,252 à 0,364 ms à une place. Pas de fondu : une marge de 2 m, pour qu'un objet ne clignote pas
  à la limite.
- **8 px** gagne encore, mais les silhouettes changent un peu. On reste à 4.

## Ce qu'on a fait

`GraphicsQuality` gagne cinq réglages : `lod_threshold`, `detail_range`, `detail_size`, `shadow_min_size`, `moon_shadow_mode`.
`GraphicsQualityApplier` les applique. Il garde la taille et l'ombre d'origine de chaque objet : revenir à la qualité haute rend
tout. La qualité haute ne change pas.

## Une erreur trouvée par la mesure

Le premier essai ajoutait 244 objets dessinés à la qualité **haute**, à qui on ne demandait rien : 2 683 → 2 850 appels. Le code
posait une marge de 2 m sur tous les objets, y compris ceux sans portée. Le moteur les traite alors comme des objets à portée
limitée. La marge ne se pose plus que là où il y a une portée. Même image, mêmes nombres au repos qu'avant, à l'unité près :
2 683 appels, 14 003 896 primitives.

Un test ne l'aurait pas vu : la mesure d'une qualité qu'on ne touche pas fait partie de la vérification.

## Le résultat

Qualité basse, 1280 × 720, carte presque libre, deux mesures lancées l'une après l'autre :

| | Étape 20 | Étape 21 |
| --- | --- | --- |
| Au repos : appels de dessin | 594 | 330 |
| Au repos : primitives | 3,57 M | 1,11 M |
| Au repos : carte | 0,327 ms | 0,238 ms |
| Au repos : rendu processeur | 0,47 ms | 0,38 ms |
| En tirant : appels, carte | 620, 0,332 ms | 351, 0,242 ms |
| Sorts au plus fort : appels, carte | 634, 0,363 ms | 368, 0,269 ms |

Moitié moins d'appels, trois fois moins de primitives, un quart de temps de carte en moins. Ces temps viennent de la 5090 : ils
disent le sens et la proportion, pas ce que tiendra un petit PC. Combat sans fenêtre : 0 allocation de notre code.

L'image : 1,2 niveau sur 255 d'écart moyen au repos, surtout le motif des ombres de la lune au sol.

## Les tests

La qualité basse relève le seuil, retire l'ombre des petits objets, limite la portée des plus petits, laisse les grands intacts,
et ne fait qu'une passe pour la lune ; revenir à la haute rend tout.

Avec les cas des étapes précédentes : 270 cas verts. Images en Forward+ et en Compatibilité.
