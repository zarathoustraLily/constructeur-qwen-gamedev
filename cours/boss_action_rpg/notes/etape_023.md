# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, après avoir vu les effets des étapes 19 et 20 : « cherche sur internet et ameliore tes vfx ce n'est pas du tout au
strandard des jeu video de 2026 ». Il a raison : regardés image par image, la boule de feu était une tache laiteuse, l'explosion une étoile
plate et des bâtons, les marques au sol ressemblaient à une interface. Des réglages n'y changeraient rien : c'est la matière qui manque.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a cherché, et ce qu'on en retient

- **Les jeux partent d'une simulation de fluide cuite en flipbook.** EmberGen ou Houdini simulent ; on range les images en atlas, avec les
  vecteurs de mouvement ([EmberGen](https://jangafx.com/software/embergen), [atlas de fumée et de vecteurs](https://www.artstation.com/artwork/6N6EG5)).
- **La fumée reçoit la lumière du niveau** : « six-way lighting » : six images de ce que le volume renvoie d'une lumière venue de chaque
  direction, deux textures pour tout ranger, et le jeu les mêle selon la direction de chaque lumière ([Unity](https://unity.com/blog/engine-platform/realistic-smoke-with-6-way-lighting-in-vfx-graph)).
  Une publication d'avril 2026 dit encore qu'elle est « widely used in video games » ([arXiv 2604.03748](https://arxiv.org/abs/2604.03748)).
- **Un éclat de bouche se compose** : un cœur rond, des flammes longues, des étincelles, de la fumée ; une ou deux images à l'écran, tirées au
  sort, jamais la même ([realtimevfx](https://realtimevfx.com/t/wondering-how-good-muzzle-flashes-are-made/13540)).
- **Un plan vu par la tranche ne doit pas se voir** : on l'efface selon l'angle de vue (même fil).
- **Couleur** : on ne sature pas la couleur d'une lumière ; on pousse le fond clair de la rampe et on laisse la lueur faire le reste
  ([realtimevfx](https://realtimevfx.com/t/looking-for-feedback-on-explosion-vfx/29528)).

Le dernier mot vient de la consigne : on ne télécharge rien sans accord de laurent. Or tout ceci se fabrique : la RTX 5090 et OpenGL 4.3 sont là.

## Ce qu'on a fait, dans l'ordre

### 1. Un simulateur de fluide sur la carte

`SUIVIS_PROGRESSION/outils/fluide_gpu.py` est un fluide 3D en shaders de calcul (moderngl) : forces, combustion, projection, advection
MacCormack. PyTorch n'a pas pu servir : sa version n'accepte pas la RTX 5090 (`sm_120`). Les shaders de calcul, si : une grille de 400³ et
108 pas se cuisent en 40 secondes.

La **cuisson** est simple parce que la caméra regarde le long d'un axe de la grille : la profondeur optique vers une lumière se cumule le long
d'un axe, en une passe. Six lumières, six passes ; puis on intègre le long du regard la lumière reçue, l'alpha, l'émission et la vitesse.
Deux octaves de plus (la même extinction, plus faible) imitent la lumière diffusée plusieurs fois : sans elles, la fumée paraît en plâtre.

`outils/cuire_flipbooks.py` range tout en atlas. Une recette par matière ; ici : `fumee`, et `bouche`, `bouche_face`.

Une erreur à retenir : **le souffle d'un tir n'est pas un fluide lent**. Simulé, il donnait des boules rondes : un gaz qui jaillit en une
milliseconde a des pointes nettes. `_souffle` le dessine donc en coordonnées polaires : une longueur par direction, déchirée par un bruit très
fin autour du centre et très long le long du rayon. La forme vient de ce qu'on veut voir, pas de l'outil qu'on vient d'écrire.

### 2. Le shader de flipbook

`flipbook.gdshaderinc` : deux images voisines, chacune poussée le long de ses vecteurs, se fondent : 36 images suffisent. `flipbook_lit.gdshader`
mêle les six lumières dans `light()`, que le moteur répète pour chaque lumière du niveau. Trois pièges, tous vus à l'image :

- **Les fonctions de shader ne voient pas les variables intégrées** (`INV_VIEW_MATRIX` hors de `vertex()`), et une `varying` ne s'écrit pas
  dans une fonction. On passe les matrices en arguments, et on écrit les `varying` dans `vertex()`.
- **Le brouillard s'ajoute au mélange prémultiplié** même là où l'alpha est nul : le plan se voyait au ras du sol, rectangle clair dans la brume.
  `fog_disabled`. La fumée sombre découpait alors la brume en noir : on lui a donné une ambiance à elle (`ambient_color`).
- **`shadows_disabled` n'a pas été mis** : le plan ne projette pas d'ombre (`cast_shadow = 0`), mais il doit recevoir celle du toit, sinon la
  fumée s'éclaire à la lune à l'intérieur de la salle.

### 3. La couleur du niveau

Sous AgX, le feu vif virait au blanc-rose. ACES garde l'orangé : `tonemap_mode = 3`. Il assombrit les ombres : `tonemap_exposure = 1.5`,
`ambient_light_energy = 0.42`. Le plan émissif blanc derrière la porte (noté à l'étape 8, jamais repris) devient une nuit bleue : il écrasait
la moitié de chaque image. Le niveau est plus sombre et plus contrasté : ces choix se discutent, laurent ne les a pas vus.

### 4. Le tir

- `MuzzleFlash` : le jet (tourné autour du canon), l'étoile (face à la caméra, ce qu'on voit de derrière le héros), des étincelles, une lumière,
  et un **flux** de fumée.
- Un flux n'est pas une salve : `restart` effacerait la fumée du tir d'avant. `VfxBurst` connaît un enfant `Stream` : il émet tant que l'effet est
  rejoué, et ses particules vivent leur vie.
- `ShotImpact` : une étoile, 40 étincelles fines (`spark.gdshader` : un trait le long de la vitesse, jamais moins d'un pixel de large), des éclats de
  matière et de la poussière. Étincelles et éclats rebondissent sur `SparkFloor`, une boîte de collision sous le plancher : une seule, peu chère.

## Le coût

Les flipbooks sont compressés (BC7, BC5 pour deux canaux) : 5,3 Mo par atlas de 2040 × 2040. Les mesures sur la carte Intel de l'étape 22 sont dans
`suivi.md`. Le test qui fait foi reste le petit PC de laurent.

## Les tests

`VfxBurst` : le flux coule tant que l'effet est rejoué, s'arrête sans être relancé, et l'effet attend que sa fumée ait fini ; `detail` règle la part de
particules. Les anciens tests de lueur restent aux étapes 19 à 22 : les nouveaux éclats n'ont plus de lueur, c'est leur HDR qui nourrit le glow.
