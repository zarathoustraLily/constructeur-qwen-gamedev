# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les coups se voient enfin : un chiffre de dégâts jaillit à chaque touche, chaque
personnage porte une barre de santé, et quand le héros est touché, l'écran rougit un instant, la caméra tremble,
le coup résonne et la manette vibre.

Ce qu'on obtient : on lit le combat d'un coup d'œil. La barre cyan du héros, les barres rouges des ennemis ; la
partie claire derrière chaque barre montre ce qu'on vient de perdre, puis la rattrape.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Frapper un ennemi : son chiffre (10.0, 14.0…) s'élève puis s'évanouit, sa barre baisse. Se laisser
   toucher : voile rouge, secousse, vibration de la manette.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'interface ne vit pas dans les personnages

Dans le jeu d'origine, le joueur et l'ennemi contenaient leur barre de santé, et un autoload (`VfxManager`)
faisait apparaître les chiffres de dégâts quand un personnage l'appelait. Les règles des dossiers l'interdisent
ici :

- une entité (`3_entities`) ne connaît que `1_core`, `5_data` et `6_assets` : pas l'interface (`4_ui`) ;
- un autoload (`0_autoload`) ne connaît que `1_core` : il ne peut pas précharger une scène de `4_ui`.

C'est donc la **scène** qui fait le lien, comme depuis l'étape 1 : `main.gd` (dans `2_sequence`, qui connaît
les acteurs et l'interface) pose une barre au-dessus de chaque personnage et branche le signal `damage_taken`
de sa santé sur la couche des chiffres. Les personnages ne savent même pas qu'on les montre.

### 2. Le chiffre de dégâts

`4_ui/hud/damage_number/` : un `Node2D` (un `Label` à contour noir) que la caméra place à l'écran au-dessus de
son point du monde (`unproject_position`, à chaque image). Son animation `spawn` le grossit (×1,5), le réduit,
puis le libère au bout d'une seconde (piste d'appel de méthode vers `queue_free`).

`4_ui/hud/damage_numbers/` : la couche (`CanvasLayer`) qui les accueille, au-dessus de l'image du jeu ;
`show_damage(position, dégâts)` y pose un chiffre.

### 3. La barre de santé, dessinée dans une image

`4_ui/components/health_bar/` : deux `ProgressBar` dans une `SubViewport` de 128 × 16 pixels, c'est-à-dire une
petite image rendue à part. Un `Sprite3D` en mode `billboard` l'affiche dans le monde, toujours face à la caméra.
À chaque coup, la barre de devant tombe d'un coup à la santé restante ; celle de derrière, claire, la rejoint en
0,2 s (un `Tween`). Vaincu, le personnage voit sa barre s'effacer (`transparency` de 0 à 1) et partir.

La couleur de la barre de devant est celle de son `StyleBoxFlat`, marqué `resource_local_to_scene` : chaque
barre a sa copie, et changer la couleur d'une barre ne change pas les autres.

Couleurs et places des barres (au-dessus du centre : 2,25 m pour le héros, 2 m pour les ennemis) sont réglées
sur la scène principale (`player_bar_color`, `enemy_bar_offset`…), pas écrites dans `main.gd` (règle DAT-01).

### 4. Être touché se sent

La vue du joueur écoute `damage_taken` de sa santé :

- le voile rouge (`DamageTint`, un `ColorRect` qui couvre l'écran) passe de 50 % à transparent en 0,2 s ;
- la caméra tremble (`damage_shake`, 1, dans les réglages du joueur) ;
- le son du coup reçu joue (`metal-hit.ogg`) ;
- la manette vibre (`5_data/input/hit_rumble.tres` : moteur fort à 0,9, 0,2 s), par l'adaptateur d'entrées.

La vue écoute `damage_taken` et non `health_changed` : `restore()`, quand le héros revient au départ, change
aussi la santé, mais ce n'est pas un coup.

Comme la vue de l'ennemi à l'étape 7, la vue du joueur attend que le joueur soit prêt (`await player.ready`)
avant de se brancher sur sa santé : ses composants `@onready` ne sont posés qu'après elle.

## Les tests

- `4_ui/hud/damage_number/test_damage_number.gd` : une décimale ; placé au-dessus de son point vu par la
  caméra ; libéré au bout d'une seconde ;
- `4_ui/hud/damage_numbers/test_damage_numbers.gd` : `show_damage()` pose un chiffre ;
- `4_ui/components/health_bar/test_health_bar.gd` : pleine et de la bonne couleur ; la barre de devant tombe,
  celle de derrière la rejoint ; vaincu, la barre part ; sans santé, rien ;
- `3_entities/player/test_player_view.gd` : touché, l'écran rougit puis s'éclaircit, la caméra tremble, le son
  joue ;
- `2_sequence/test_main.gd` : chaque personnage a sa barre ; un coup reçu affiche ses dégâts.

## Ce qu'il faut retenir

- L'interface ne s'invite pas chez les acteurs : la scène les relie.
- `SubViewport` + `Sprite3D` : une interface 2D affichée dans la 3D.
- `resource_local_to_scene` : une ressource copiée pour chaque instance.
- Un retour de coup se règle comme le reste : secousse et vibration dans les données.

## À essayer

- Passer `damage_shake` à 0 dans `player_settings.tres` : les coups reçus ne secouent plus l'écran.
- Dans `damage_number.tscn`, passer le `font_size` à 64 : les chiffres deviennent énormes.
- Retirer `resource_local_to_scene` du `StyleBoxFlat` de la barre : toutes les barres prennent la même couleur.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : chiffre de dégâts (animation, police), barre de
  santé (deux barres, SubViewport, couleurs), voile rouge, secousse 1, son `metal-hit.ogg`. La vibration est
  ajoutée par le cours (la manette n'existait pas dans le jeu d'origine).
- Documentation de Godot 4.7 : *Using Viewports* (`tutorials/rendering/viewports.rst`) pour afficher une
  `SubViewport` dans un matériau ou un sprite.
- Références des classes `SubViewport`, `ViewportTexture`, `Sprite3D` (`billboard`), `CanvasLayer`,
  `Resource` (`resource_local_to_scene`) : API de Godot 4.7.2.

## Étape suivante

Étape 010 : la vague. Les ennemis apparaissent un à un, de plus en plus nombreux à chaque niveau, et quand le
dernier tombe, la sortie s'ouvre.
