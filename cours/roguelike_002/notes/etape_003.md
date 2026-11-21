# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Après le studio, un avertissement : le jeu est une fiction, et il peut déclencher une crise chez
les personnes sensibles aux lumières clignotantes. On doit avoir le temps de le lire : on ne peut le passer qu'après
un temps de lecture minimal ; ensuite une consigne apparaît, et A ou Entrée le fait partir. Si le joueur ne fait
rien, il passe seul.

Ce qu'on obtient : F5 montre le studio, puis l'avertissement ; au bout d'1,5 s, « Appuyez sur A ou Entrée pour
continuer » apparaît et respire ; A, B, Entrée ou Échap le font partir ; sinon il part seul au bout de 12 s.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : le studio, puis l'avertissement.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Trois fichiers pour un écran

- `DisclaimerInput` (`4_ui/jeu/disclaimer_input.gd`) : le seul qui lit les entrées (règle ARC-04). Dans
  `_unhandled_input`, `event.is_action_pressed(&"ui_accept")` ou `&"ui_cancel"` émet `skip_requested`, puis
  `set_input_as_handled()`. Il ne sait pas si c'est permis.
- `DisclaimerScreen` (`2_sequence/jeu/`) décide : une demande avant `skip_after_s` est ignorée ; après, l'écran part.
  Le temps passé à l'écran (`_shown_for`) compte depuis l'apparition, et ne repart pas de zéro à chaque moment.
- `DisclaimerView` (`4_ui/jeu/`) montre : l'opacité de tout l'écran, et la consigne, qui n'apparaît que quand on peut
  passer et respire alors avec un `Tween` en boucle (`create_tween().set_loops()`). Les tweens n'existent que dans
  les vues (règle ARC-03).

### 2. Le texte est une donnée

Le titre, le texte, la consigne et les durées sont dans `5_data/jeu/avertissement.tres` (`DisclaimerDef`,
`@export_multiline` pour le texte). Le validateur refuse un écran qui passerait seul avant qu'on puisse le passer.

### 3. Le studio charge l'avertissement

L'écran du studio nomme maintenant l'avertissement comme suite, et le met dans sa liste de chargement en fond : quand
la coquille l'ouvre, `load()` le trouve déjà dans le cache de Godot.

## Les tests

- `test_disclaimer_input.gd` : Entrée, A et B demandent ; J ne demande rien. Les événements passent par
  `get_viewport().push_input(...)`, comme un vrai appui.
- `test_disclaimer_screen.gd` : demande trop tôt ignorée, consigne cachée ; après la lecture, consigne montrée et
  départ ; sans rien faire, départ seul ; dans la scène du jeu, le texte vient de la donnée et A fait partir l'écran.
- `test_disclaimer_def.gd` : la donnée du jeu est juste ; quatre fautes refusées.
- `test_studio_def.gd` : le studio mène à l'avertissement et le charge en fond.
