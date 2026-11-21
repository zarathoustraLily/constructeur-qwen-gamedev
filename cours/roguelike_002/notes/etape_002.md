# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le premier écran du jeu montre la marque et le nom du studio. Il n'est pas là pour faire joli :
pendant qu'il s'affiche, le jeu charge en fond ce dont le menu aura besoin (son grand fond étoilé, sa planète). Quand
le menu s'ouvrira, ses images seront déjà là.

Ce qu'on obtient : F5 montre la marque et « NOM DU STUDIO » qui apparaissent sur fond noir, la barre qui se remplit,
puis la marque qui disparaît. Le nom se change dans `5_data/jeu/studio.tres`, sans toucher au code.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : l'écran du studio.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Charger en fond : `BackgroundLoader`

`ResourceLoader.load_threaded_request(chemin)` lance la lecture sur les fils de Godot et rend la main tout de suite.
À chaque image, `load_threaded_get_status(chemin, avancee)` dit où elle en est (`THREAD_LOAD_IN_PROGRESS`, avec
l'avancée dans `avancee[0]`, puis `THREAD_LOAD_LOADED`) ; `load_threaded_get(chemin)` rend la ressource.

`BackgroundLoader` (`1_core/jeu/`) fait cela pour une liste :
- `start(chemins)` : un chemin qui n'existe pas n'est pas demandé, il compte tout de suite comme un échec (pas
  d'erreur de Godot dans la sortie) ;
- `poll()` à chaque image ; `progress()` de 0 à 1, chaque chemin pour sa part ; `is_done()` ;
- `release()` : quand on abandonne un chargement en cours, on le reprend quand même. Une demande jamais reprise reste
  dans le chargeur de Godot, et ses ressources fuient : à la sortie, Godot écrit « ObjectDB instances were leaked at
  exit ». C'est ce qu'a montré le test de la scène du jeu, qui libérait l'écran en plein chargement.

### 2. L'écran décide, la vue montre

`StudioScreen` (`2_sequence/jeu/`) a quatre moments : apparition, tenue, disparition, fini. Il ne quitte la tenue que
quand la tenue minimale est passée ET que le chargement est fini : un chargement lent allonge l'écran, un chargement
rapide ne le raccourcit pas. Fini, il émet `finished(next)` une seule fois ; la coquille ouvre la suite.

`StudioView` (`4_ui/jeu/`) ne décide rien : l'écran lui donne le nom, puis à chaque image l'opacité et l'avancée. La
vue ne lit pas `5_data` (le tableau des dossiers le lui interdit) : c'est l'écran qui lui passe ce qu'il faut.

Les durées et le nom sont dans `StudioDef` (`5_data/jeu/studio.tres`) ; le script n'écrit aucun nombre que 0 et 1.

### 3. Un écran qui ne nomme rien arrête l'enchaînement

Tant que l'avertissement n'existe pas, l'écran du studio ne nomme pas de suite (`next_screen` vide) : la coquille
s'arrête là au lieu de chercher un écran inexistant.

## Les tests

- `test_background_loader.gd` : les deux textures du menu arrivent ; un absent est un échec immédiat et compte pour sa
  part ; un chargement abandonné est repris ; rien à charger, c'est fini. L'attente se compte en vraie horloge : sans
  fenêtre, à cadence fixe, 600 images passent en un dixième de seconde, avant que le grand fond soit lu (c'est ce
  qu'a montré le premier essai : progression bloquée à 0,5).
- `test_studio_screen.gd` : avec un faux chargement dont le test décide la fin, la marque apparaît de 0 à 1, l'écran
  attend la fin du chargement, finit une seule fois avec la suite ; la vue suit. Puis l'écran du jeu, avec ses vraies
  données, charge le menu et finit.
- `test_studio_def.gd` : la donnée du jeu est juste ; nom vide, durée négative et ressource introuvable refusés.
