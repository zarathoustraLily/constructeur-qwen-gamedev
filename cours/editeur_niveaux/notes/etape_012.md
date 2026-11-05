# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une salle vit par ses effets : la fumée d'un réacteur, les étincelles d'un câble, la vapeur d'une
fuite. Le jeu en fait des émetteurs de particules ; l'éditeur doit les placer, et donner une idée de ce qu'ils feront,
sans faire tourner la simulation du jeu.

Ce qu'on obtient : un mode « Effets ». À droite, la liste des effets du jeu, chacun avec sa couleur ; Ctrl+clic place
l'effet choisi ; on tire un effet placé pour le déplacer ; Suppr le retire. Dans la vue, chaque effet placé s'anime :
ses particules naissent au centre, s'éloignent, grandissent et s'effacent, à son débit, sa durée de vie, sa taille et sa
couleur. Une salle qui place un effet inconnu ne s'enregistre pas.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; choisir le mode « Effets » ; choisir « Vapeur » dans la liste ; Ctrl+clic dans la salle.
3. `5_data/effets/` : les trois définitions, modifiables dans l'Inspecteur.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les effets, des données du jeu

`1_core/data/fx_def.gd` décrit un effet par ce qui se règle : particules par seconde, durée de vie d'une particule,
taille, couleur, et s'il est additif (il s'ajoute à ce qui est dessous et l'éclaire, comme des étincelles) ou non (il le
recouvre, comme une fumée). `FxDef.placement_errors` dit quel effet placé le jeu ne connaît pas ; la coquille l'ajoute
aux contrôles d'enregistrement. Les définitions se chargent par `DefinitionFolder`, comme les ennemis.

### 2. Un aperçu sans hasard

L'aperçu n'est pas la simulation du jeu : il doit seulement montrer le débit, la durée, la taille et la couleur, et
toujours la même image au même instant, pour qu'un test le vérifie et qu'une capture se compare.
`1_core/editor/effect_preview.gd` le calcule à partir du temps seul :
- le nombre de particules vivantes à la fois vaut débit × durée de vie (borné à 64) ;
- la particule n° i a l'âge `fposmod(t / durée + i / n, 1)` : les âges sont répartis, et chaque particule renaît quand
  la précédente meurt ;
- sa direction tourne de l'angle d'or (environ 137,5°) d'une particule à la suivante : les directions se répartissent
  sans former de motif ;
- elle s'éloigne du centre, grandit et s'efface avec son âge.

### 3. Le calque des effets, animé seulement visible

`4_ui/editor/effect_view.gd` dessine les particules de chaque effet placé, un repère et son nom. Il avance son temps
dans `_process` et redessine, mais seulement quand il est visible : dans les autres modes, il ne coûte rien.

### 4. Placer, tirer, retirer

`4_ui/editor/effect_input.gd` suit le même schéma que les apparitions. Ctrl+clic place l'effet choisi dans le panneau
(`current_fx`) ; sans effet choisi, il le dit plutôt que de placer un effet vide. Placer ou retirer change deux
colonnes à la fois (identifiants et positions), en un seul pas.

### 5. Le panneau des effets

`4_ui/editor/effect_panel.gd` : une liste (`ItemList`) dont chaque ligne porte une pastille de la couleur de l'effet
(une petite image remplie par `Image.fill`, puis `ImageTexture.create_from_image`), et, sous la liste, les réglages de
l'effet choisi. Les modifier, c'est l'étape suivante : les paramètres du jeu.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Effets » : placer une vapeur, la tirer, Suppr.
