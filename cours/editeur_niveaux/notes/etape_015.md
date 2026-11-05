# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une définition d'animation se juge en la voyant jouer : la course tourne-t-elle dans le sens de
la marche ? l'attaque est-elle trop lente ? le passage du repos à la course saute-t-il ? Le banc d'essai est une petite
scène 3D à part, où l'on pose le modèle d'un ennemi, le fait marcher au clavier ou à la manette, joue chacun de ses clips
avec le fondu de sa définition, et lui ajoute des effets en aperçu. Il ne touche jamais à la salle ouverte.

Ce qu'on obtient : un mode « Banc d'essai ». La vue de la salle laisse la place à une scène 3D (sol, lumière, caméra) ;
à droite, l'ennemi à poser, un bouton par état, une case par effet. W A S D ou le stick gauche font marcher le modèle
(il court en marchant, revient au repos à l'arrêt) ; Espace ou A joue l'attaque, H ou B le coup reçu.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; mode « Banc d'essai » ; choisir « Brute » ; W A S D ; Espace ; cocher « Fumée ».
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une scène à part, dans sa propre fenêtre de rendu

`4_ui/editor/bench_view.gd` est un `SubViewportContainer` : il contient une `SubViewport` avec son propre monde 3D
(`own_world_3d`), un sol (`PlaneMesh`), une lumière et une caméra. Rien de ce qu'on y pose n'existe pour l'éditeur de
salles : c'est un aperçu rendu par Godot, pas une partie. Poser une animation instancie son modèle, trouve son
`AnimationPlayer` et joue le clip de repos.

### 2. Jouer un état : le clip, la vitesse, le fondu

`play_state(état)` joue le clip que la définition donne à l'état, à sa vitesse et avec son fondu :
`AnimationPlayer.play(clip, fondu, vitesse)`. Le fondu (`blend_s`) mélange le clip précédent et le suivant pendant ce
temps : c'est lui qui évite le saut entre repos et course. Les tests lisent ce qui joue (`current_animation`) et à quelle
vitesse (`get_playing_speed`).

### 3. La marche, sans physique

`1_core/editor/bench_motion.gd` déplace le modèle en géométrie pure : une position, une orientation (`atan2` de la
direction, pour que le modèle regarde où il va) et un état, `move` ou `idle`. Le banc rejoue le clip de l'état
seulement quand l'état change : relancer la course à chaque image la ferait repartir de zéro.

### 4. Le clavier et la manette, par des actions

Les touches et les boutons sont déclarés une fois, comme **actions** du projet (`[input]` de `project.godot` :
`bench_left`, `bench_right`, `bench_up`, `bench_down`, `bench_attack`, `bench_hit`), chacune avec une touche (par sa
position, `physical_keycode`) et une entrée de manette. `4_ui/editor/bench_input.gd`, le seul script du banc qui lit
`Input`, lit ces actions : `Input.get_vector` donne la direction, bornée à une longueur de 1, avec la zone morte du stick.
L'attaque ne part qu'à l'appui, pas tant que la touche reste enfoncée : le script garde l'état de l'image précédente. Les
tests pressent les actions eux-mêmes (`Input.action_press`), sans clavier ni manette.

### 5. Les effets en aperçu

Un effet coché devient un `CPUParticles3D` réglé d'après sa définition : le nombre de particules (débit × durée de vie,
comme l'aperçu de l'étape 12), la durée de vie, la taille et la couleur. On l'attache au modèle : il le suit quand il
marche. Décocher retire tous les effets puis remet ceux qui restent cochés.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Banc d'essai » : marcher, attaquer, ajouter un effet ; revenir au mode « Choses » : la salle n'a pas changé.
