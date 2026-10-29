# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le golem se bat. laurent : « n'oublie pas que les spectres n'apparaissent qu'à la seconde phase
d'attaque du golem quand il a perdu 30 pour cent de ses vies et modifie les attaques ». Les effets visuels des coups
viennent à l'étape suivante.

Ce qu'on obtient :
- le golem dort devant le comptoir ; le héros qui approche (8 m) ou qui tire le réveille, et la jauge du boss apparaît ;
- il marche vers le héros, d'un pas lourd, et choisit son coup selon la distance : un **balayage**, un **revers**, un
  **coup écrasant en avançant** (l'onde frappe au sol) ;
- pendant la frappe, son buste se penche : le marteau passe au ras du sol, à la hauteur du héros ;
- après chaque coup, il **récupère** : c'est le moment de le punir. Son dos prend double ; son bouclier bloque les
  tirs ;
- quand il a perdu 30 % de sa vie, la **seconde phase** commence. Il rugit, jette son bouclier, ses spectres sortent,
  ses coups sont plus vifs ; il enchaîne deux coups et **bondit** sur le héros de loin ;
- à zéro, il tombe.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier, en rendu Forward+.
2. F5 : avancer vers le golem ; esquiver par une roulade quand il se penche ; tirer dans son dos pendant qu'il
   récupère.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer ses gestes avant de les régler

Les 25 clips du golem ont été mesurés avant d'écrire une ligne du combat :
- leur durée ;
- le chemin de la tête du marteau, image par image, dans le repère du golem ;
- le déplacement de son os racine.

La pose se compose d'os en os (`get_bone_pose` de parent en parent), sans attendre la mise à jour du squelette. Le
marteau a aussi été tracé vu de dessus et de profil, une boule par 1/30 s, à côté d'une colonne de 1,8 m (le héros).

Ce que les mesures ont montré :
- le balayage fait le tour du golem **à 4 m du sol**. Ces clips ont été animés pour frapper un adversaire de la taille
  du golem ; ici, il est quatre fois plus grand que le héros, et ses coups passent au-dessus de lui ;
- trois clips portent un déplacement sur l'os racine : un bond de 15,5 m, un pas de 4,1 m en frappant, un recul de
  10,9 m (une fois à l'échelle du modèle, 4).

Règle : **mesurer le geste avant de régler le coup**.

### 2. Modifier les attaques : pencher le buste par-dessus l'animation

Godot 4.7.2 range les retouches de pose dans des `SkeletonModifier3D`, appliqués après l'animation. Un modificateur
écrit en GDScript redéfinit `_process_modification_with_delta`.

`GolemStrikeModifier` tourne l'os `spine_01` d'un angle `bend`, et tout le haut du corps suit. Dans le repère du
squelette, le golem regarde vers +Z : pencher vers l'avant, c'est tourner autour de +X. La nouvelle pose locale est
`inverse(pose du parent) × rotation × pose globale de l'os`.

Le penché de chaque coup a été **mesuré**. Un scénario rejoue chaque clip pour cinq angles, et relève la hauteur du
marteau devant le golem :

| Coup | Clip | Penché | Le marteau devant lui |
| --- | --- | --- | --- |
| balayage (sweep) | attack1 | 0,9 rad | 0,9 à 1,2 m, de 0,90 à 1,08 s |
| revers (backhand) | attack2 | 0,8 rad | 0,8 à 1,0 m, de 1,20 à 1,36 s |
| coup écrasant (crush) | attack4 | 0,9 rad | 0,96 m à 2,50 s, 3,3 m devant son corps |
| bond (leap) | attack5 | 0,3 rad | 0,78 m à 2,28 s, 2 m devant et 2,2 m à droite |

attack3 a été écartée : même penché de 1,1 rad, son marteau ne descend pas sous 1,7 m.

Le penché monte en douceur jusqu'au début de la frappe, tient pendant la frappe, puis retombe (`GolemAttack.bend_at`).

### 3. Le déplacement que portent les clips

D'après la référence de `AnimationMixer.root_motion_track`, avec une piste de position, « the transformation will be
canceled visually, and the animation will appear to stay in place ». La vue pose donc cette propriété sur la piste
`Skeleton3D:root` : le modèle reste sur son corps.

C'est la logique du golem qui fait avancer le corps. Elle lit la même piste dans la ressource `Animation`
(`position_track_interpolate`), multipliée par 4 et tournée d'un demi-tour, et la suit d'image en image par
`move_and_slide`. C'est déterministe, cela se teste sans fenêtre, et le corps s'arrête contre un mur au lieu de le
traverser.

### 4. Les données : une ressource par coup

`GolemAttack` (`1_core/data/golem_attack.gd`) décrit un coup :
- le clip ;
- la portée (`min_range`, `max_range`) et la phase à partir de laquelle il s'en sert ;
- jusqu'à quand il suit le héros des yeux (après, le coup part droit et s'esquive) ;
- la fenêtre du marteau et ses dégâts ;
- le penché ;
- l'impact au sol : instant, point, rayon, dégâts ;
- si le coup est visé ;
- le temps de récupération.

Les quatre coups sont dans `5_data/boss/attacks/`. `GolemSettings` (`5_data/boss/golem.tres`) règle le reste :
- réveil et marche ;
- seuil de la seconde phase : 0,7 ;
- coups enchaînés en seconde phase ;
- vitesse des clips en seconde phase : 1,15.

### 5. La machine à états

Un fichier par état dans `3_entities/boss/states/` :
- **Dormant** : il attend que le héros approche ;
- **Wake** : il se dresse et fait face ;
- **Approach** : il se tourne ; une fois face au héros, il choisit un coup ; sinon, il marche ;
- **Attack** : il joue le coup ; son corps suit le clip ; le marteau frappe dans sa fenêtre ; l'onde est placée avant
  l'impact et frappe à l'impact ;
- **Recover** : il ne se tourne pas ; c'est la fenêtre de punition ;
- **PhaseShift** : la seconde phase commence ;
- **Dead** : il tombe.

Il essaie ses coups dans l'ordre, à partir de celui qui suit le dernier choisi : il ne répète pas un coup s'il en a un
autre.

Les signaux (`woke`, `attack_started`, `slammed`) sont émis par des méthodes du golem (`wake_up`, `begin_attack`,
`strike_ground`) que les états appellent. Un signal émis seulement depuis une autre classe est un avertissement
`unused_signal`, donc une erreur dans ce projet.

### 6. Bouclier, point faible, seconde phase

Les zones qui reçoivent les tirs ont un multiplicateur :
- le **bouclier** (`ShieldGuard`, sur l'os de la main gauche) multiplie par 0 : il bloque ;
- le **dos** (`BackWeakPoint`, une boîte qui dépasse de la capsule du corps, à l'arrière) multiplie par 2.

Le tir prend la première zone que son rayon rencontre : de face, le corps ou le bouclier ; de dos, le point faible.

Quand sa vie passe sous 70 % (il en a perdu 30 %), la seconde phase est due. Elle passe dès qu'il n'est plus en
pleine attaque :
- son bouclier ne bloque plus, et la vue le fait tomber de sa main ;
- `phase_changed(2)` part : `SpectreCall` l'écoute et fait sortir les spectres. C'est une seule source pour le seuil :
  les spectres ne lisent plus la santé ;
- ses clips jouent 1,15 fois plus vite ;
- il enchaîne deux coups avant de récupérer ;
- le bond devient permis.

La jauge du boss n'apparaît plus au démarrage : la scène principale la branche quand il se réveille.

### 7. Ce que le jeu a appris

On a joué le combat sans joueur (`SUIVIS_PROGRESSION/outils/jouer_combat.gd`). Le golem s'éveille, balaie et touche
le héros à 0,93 s du clip (30 points), récupère, revers (30 points). Il passe à la seconde phase après son coup en
cours.

Ensuite :
- **le bond s'arrêtait net**. Une carte du sol vue de dessus (`outils/carte_arene.gd`, un rayon vertical par mètre) et
  des rayons horizontaux ont montré la cause : sa capsule (1,6 m de rayon) butait contre l'encadrement de la porte
  d'entrée, que le héros, plus mince, franchissait. D'où `Golem.path_clear` : avant un coup qui porte son corps, il
  fait glisser la forme de son corps le long du déplacement (`PhysicsDirectSpaceState3D.cast_motion`), soulevée de
  0,3 m pour que le plancher ne compte pas. Il ne garde le coup que si le chemin est libre ;
- **le bond faisait toujours 15 m** : il passait par-dessus un héros à 10 m. Le bond est maintenant **visé**. Son
  déplacement s'allonge ou se raccourcit, entre 0,5 et 1,1 fois celui du clip, pour que l'impact tombe sur la cible.
  Le calcul se fait sur le déplacement **jusqu'à l'impact**, pas jusqu'à la fin du clip ;
- **l'onde tombait 1 m trop court**. Elle est placée 0,2 s avant l'impact, pour que les corps déjà dedans soient vus
  quand elle frappe ; mais le corps avance encore pendant ce temps. Sa place est maintenant prévue à l'instant de
  l'impact.

### 8. Les tests

Le golem :
- il dort tant que le héros est loin ; il s'éveille quand il approche, ou au premier tir ;
- il marche vers lui ;
- il choisit son coup selon la distance et la phase, sans le répéter ; il ne bondit pas si un mur barre le chemin ;
- son marteau ne frappe que dans sa fenêtre ;
- son corps suit le déplacement du clip, et son bond visé retombe sur sa cible à 10, 13 et 16 m ;
- un écrasement frappe dans son rayon, pas au-delà ;
- après son coup, il récupère sans se tourner ;
- son dos prend double, son bouclier bloque ;
- à 70 %, la seconde phase commence une fois ; en seconde phase, il enchaîne deux coups ;
- à zéro, il tombe.

Sa vue :
- pendant la frappe, le buste est penché et la zone de coup du marteau passe sous 1,8 m ;
- à la seconde phase, le bouclier quitte sa main et tombe au sol.

Les spectres sortent à la seconde phase, une seule fois. Avec les cas des étapes précédentes : 199 cas verts.
