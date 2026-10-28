# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le décor et le boss sont là ; le héros, lui, est encore une capsule grise avec un nez orange.
C'est l'étape suivante de l'ordre accepté par laurent : le soldat de son paquet, animé, branché sur la logique écrite
aux étapes 2 à 6, sans la changer. **Règle de l'étape : la vue montre, elle ne décide rien.** Tout ce que le héros
fait (courir, rouler, chanceler, boire, tomber, tirer) est déjà choisi par sa machine à états ; la vue l'écoute et
joue l'animation qui va avec.

Ce qu'on obtient : un soldat en armure (1,8 m, voyants lumineux du casque et de l'armure), fusil en main, qui attend,
court, sprinte, marche en visant dans les quatre directions, recule d'un coup de fusil à chaque tir (haut du corps
seulement : les jambes continuent de courir), roule, chancelle, se soigne et tombe. Les tirs partent du canon qu'on
voit.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le premier import des textures prend un moment).
2. F5 : courir (stick gauche), viser (gâchette gauche) et tirer (droite), rouler (B), sprinter (B tenu), boire (X).
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

Les outils cités sont dans le dossier du jeu de laurent, `SUIVIS_PROGRESSION/outils/`, hors du projet Godot : ils
fabriquent `6_assets/Characters/Hero/`, ils ne sont pas le jeu.

### 1. Savoir ce que contiennent les sources

Quatre archives de laurent : `scifitroopermanv3` (le soldat : un FBX, huit PNG, trois matériaux Unity), `sourse` (huit
roulades `RM_Roll_*`), `lyra` (576 animations) et `gaspfix` (1 759 animations, au fusil et au pistolet). On lit avant
de choisir : la liste des dossiers (`Rifle`, `HitReactions`, `death`, `Run`, `Sprint`…), puis, une fois quelques FBX
importés, ce que Godot en tire (`inspecter_scene.gd` : nœuds, os, animations). Deux trouvailles décident de tout :

- **deux squelettes différents.** Le soldat a celui du mannequin d'Unreal 4 : 68 os, `spine_01` à `03`, pas d'os
  `root`. Roulades, Lyra et gaspfix ont celui d'Unreal 5 : `root`, `spine_01` à `05`, `neck_01` et `02` (89 à 161 os).
  Les noms communs ne suffisent pas : les repos des os (leur orientation au repos) diffèrent ; une animation copiée
  telle quelle tord les membres ;
- **aucun modèle d'arme.** Les paquets n'ont que des animations au fusil. Le fusil est donc fait de primitives (boîtes,
  un cylindre, un voyant), à remplacer quand un vrai modèle sera trouvé.

### 2. Recibler à l'import, avec l'outil de Godot

On cherche d'abord dans la documentation (`search_docs` : « retarget animation BoneMap SkeletonProfileHumanoid
import ») : le tutoriel « Retargeting 3D Skeletons » décrit le reciblage de Godot 4. Il se fait **à l'import** : on
donne au squelette une carte d'os (`BoneMap`) vers un profil (`SkeletonProfileHumanoid` : Hips, Spine, Chest,
LeftUpperArm…) ; Godot renomme alors les os d'après le profil, fait du squelette un nœud unique (`%GeneralSkeleton`) et
réécrit leurs repos sur la pose de référence du profil (« Overwrite Axis »). Deux modèles ainsi importés partagent
leurs animations : les pistes s'appellent `%GeneralSkeleton:Hips` des deux côtés.

Dans l'éditeur, cela se règle dans la fenêtre d'import avancée. Sans fenêtre, on l'écrit : `recibler_heros.gd`
construit les deux cartes (UE4 et UE5 vers le profil, doigts compris), les enregistre en `.tres`, puis écrit dans le
`.import` de chaque FBX, sous `_subresources`, le réglage du nœud du squelette :

```
"nodes": { "PATH:Skeleton3D": {
    "retarget/bone_map": Resource("res://6_assets/Characters/Hero/Retarget/bone_map_ue5.tres"),
    "retarget/bone_renamer/unique_node/skeleton_name": "GeneralSkeleton", … } }
```

Le chemin est celui du squelette **dans la scène brute** (`root/Skeleton3D` pour le soldat,
`SKM_Manny_Simple/Skeleton3D` pour une roulade), pas le nom qu'il aura après. On efface les `.md5` de ces imports
pour que le `--import` suivant les refasse. On vérifie aussitôt (`inspecter_scene.gd`) : os `Hips`, `Spine`, `Chest`…,
squelette `GeneralSkeleton` dans les deux fichiers.

Ce que la carte ne couvre pas reste sous son nom (`spine_02`, `neck_02`, les muscles d'avant-bras) ; le soldat n'a
pas d'os `Root` : la carte UE4 le laisse vide.

### 3. Mesurer les clips au lieu de deviner

`mesurer_clips.gd` lit chaque clip : durée, pistes, déplacement de l'os `Root` du début à la fin. Résultats qui
décident :

- la roulade avant porte **3,44 m en 1,17 s** ; l'état Roll du héros fait 3,5 m (7 m/s pendant 0,5 s) : même
  distance, autre durée. On ne touche pas à la logique (testée depuis l'étape 4) : on étire le clip sur 0,5 s ;
- les boucles de course et de sprint de gaspfix sont **sur place** (`Root` immobile) : leur vitesse ne se lit pas
  dans `Root`. On la mesure aux pieds (`mesurer_foulee.gd`) : un pied posé (à moins de 3 cm de sa hauteur la plus
  basse) recule à la vitesse que le corps doit avoir pour qu'il ne glisse pas. Course 4,23 m/s, sprint 6,02 m/s,
  marches visées 1,94 à 2,19 m/s.

Piège trouvé en mesurant : la première mesure donnait 0,00 m/s partout. `Skeleton3D.get_bone_global_pose` ne voit
pas une pose qu'on vient de poser par `set_bone_pose_rotation` : les poses globales ne se recalculent qu'au passage
suivant du squelette. Le remède : composer la pose de parent en parent à partir des poses locales
(`get_bone_pose`). Le même piège avait faussé la place du fusil, calculée sur la pose de repos ; corrigé de la même
façon.

### 4. Le modèle, construit par un script

`construire_heros.gd` fait `hero_model.tscn`, comme `construire_golem.gd` pour le golem :

- **matériaux** : le soldat utilise le shader Standard d'Unity. Sa carte « RGBA » est sa `_MetallicGlossMap` : métal
  en R, occlusion en G (Unity lit l'occlusion dans le canal G), lissé en A (`_SmoothnessTextureChannel: 0`).
  `heros_textures.py` en fait une ORM pour Godot (R occlusion, G rugosité = 1 − lissé, B métal), en 2 048 px. Quel
  matériau va sur quel maillage : les noms du FBX (« 02 - Default », « 03 - Default ») ne le disent pas ; le `.meta`
  du FBX, dans le paquet Unity, si (`externalObjects` : « 02 - Default » → `M_Bottom`, « 03 - Default » → `M_Top`) ;
- **le fusil**, sur l'os `RightHand` (`BoneAttachment3D`). Sa place se calcule dans la pose de visée : poignée à la
  main droite, canon vers la main gauche, dessus vers le haut ; puis on l'exprime dans le repère de l'os, qui la garde
  dans toutes les animations. Sa bouche est un `Marker3D` nommé `Muzzle`, nœud unique ;
- **la bibliothèque** : 13 clips renommés (`idle`, `aim_idle`, `aim_walk_f/b/l/r`, `run`, `sprint`, `fire`, `roll`,
  `hit`, `heal`, `death`), **sans la piste de l'os Root** : c'est le code qui déplace le corps ; le mouvement porté
  par l'animation ferait sortir le modèle de sa capsule.

Choix des clips : Lyra pour l'attente, la visée, la marche visée, le tir, le coup et la chute ; gaspfix pour la course
et le sprint (boucles au fusil) ; `sourse` pour la roulade. Le corps se tourne vers la roulade (état Roll, étape 4) :
la roulade avant suffit. Aucun clip ne boit une fiole : le soin joue le rechargement (`MM_Rifle_Reload`), geste des
mains sur l'arme ; un vrai geste de soin reste à trouver (Mixamo, avec l'accord de laurent).

On juge sur l'image (`planche_poses.gd` : le modèle posé dans plusieurs clips, côte à côte, de face et de côté) :
membres droits, fusil dans les mains, roulade en boule.

### 5. La vue : `hero_view.gd`

Le plan sépare logique, vue et entrée : la logique du héros (`hero.gd`, ses états) ne connaît pas le modèle. La vue
est un nœud `View` du héros, avec le modèle (tourné d'un demi-tour : le profil regarde +Z, le héros avance vers -Z) et
un `AnimationTree` qu'elle construit au démarrage :

- un `AnimationNodeTransition` « state », une entrée par état : `move`, `roll`, `hit`, `heal`, `dead`. La vue écoute
  `StateMachine.state_changed` et demande l'entrée (`parameters/state/transition_request`) ;
- dans `move` : un `AnimationNodeBlendSpace1D` « locomotion » sur la vitesse au sol (attente à 0, course à 5,5,
  sprint à 8), fondu par un `AnimationNodeBlend2` « aim » vers un `AnimationNodeBlendSpace2D` « strafe » (marche visée,
  quatre directions, vitesse dans le repère du corps) quand le héros vise ;
- par-dessus, un `AnimationNodeOneShot` « fire », relancé par chaque `HeroGun.fired`, **filtré sur le haut du corps**
  (l'os `Spine` et tout ce qui en descend, calculé dans le squelette) : les jambes gardent la course.

**Durées et vitesses, sans changer la logique** : un `AnimationNodeAnimation` a sa propre ligne de temps
(`use_custom_timeline`, `timeline_length`, `stretch_time_scale` : « la longueur donnée est un cycle »). La roulade
s'étire sur `roll_duration`, le soin sur `heal_duration` ; chaque boucle de marche sur
`longueur × vitesse de foulée ÷ vitesse du corps` : à 5,5 m/s, la course (foulée 4,23) joue 1,3 fois plus vite et
les pieds ne glissent pas. Les foulées mesurées et les fondus vivent dans `5_data/hero/hero_view.tres`
(`HeroViewSettings`), jamais dans le script.

**La bouche de l'arme** : l'arme du héros (`Gun`, étape 5) tire depuis sa position. La vue la porte à la bouche du
fusil. Premier essai, dans `_physics_process` : le test la trouve à 0,26 m du canon pendant une roulade, parce que le
squelette ne finit sa pose qu'après la physique. Le remède : le signal `Skeleton3D.skeleton_updated` (« la pose finale
est calculée ») ; la vue y recalcule la bouche depuis l'os de la main (pose de l'os × place du fusil), sans dépendre de
l'ordre des abonnés.

Les dépendances sont déclarées : la vue reçoit le héros, sa machine et son arme par des `@export` (chemins dans la
scène), au lieu de lire les `@onready` du héros, qui ne sont pas encore posés quand la vue, son enfant, démarre.

### 6. Le plan du projet suit l'ordre réel

`plan.md` listait encore l'ordre de départ (golem en maquette grise à l'étape 7). Depuis la réorientation visuelle,
il dit ce qui a été fait (7 : le saloon et son gardien ; 8 : le héros animé) et ce qui vient (interface du genre,
combat du golem, effets et sons, optimisation).

### 7. Les tests

`test_hero_view.gd` (10 cas) : squelette reciblé et fusil dans la main droite ; chaque clip présent, aucun avec l'os
Root ; au départ, la course ; chaque état (Roll, Hit, Heal, Dead) montre son entrée, le retour à Move remontre la
course ; roulade et soin durent ce que durent leurs états ; course, sprint et marche visée à la vitesse du corps ; la
vitesse au sol règle le mélange ; la visée se fond en `aim_blend_time` et revient ; un tir joue le recul du haut du
corps seulement ; la bouche de l'arme suit celle du fusil pendant une roulade. Avec les cas des étapes précédentes :
139 cas verts. Premier passage : deux corrections, toutes deux lues dans la sortie de Godot (le retard de 0,26 m de la
bouche ; un avertissement de Godot, « No name provided, using safe index as reference », sur les points de mélange
sans nom : on les nomme).

Captures : le soldat dans le saloon, vu par la caméra du jeu (attente, course, visée et tir, roulade), et la planche
des poses.
