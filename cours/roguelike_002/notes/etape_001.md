# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le jeu commence par ses menus : l'écran du studio, l'avertissement, le menu principal, les options,
les sauvegardes. Avant d'en écrire un seul, il faut la coquille qui les enchaîne, et les règles qui tiendront tout le
projet : où va chaque fichier, dans quel ordre les nœuds travaillent, d'où vient le hasard, quelles touches et quels
boutons existent.

Ce qu'on obtient : F5 ouvre une fenêtre noire (la coquille, sans écran encore) ; les tests passent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : la coquille s'ouvre, vide.
3. Les tests : `7_tests/lancer_tests.bat` (adapter le chemin de Godot), ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Huit dossiers, chacun avec ce dont il peut dépendre

| Dossier | Contenu | Peut dépendre de |
| --- | --- | --- |
| `0_autoload` | services globaux | `1_core` |
| `1_core` | mécanismes génériques, classes de données | rien |
| `2_sequence` | le déroulé : coquille, écrans | tout sauf `7_tests` |
| `3_entities` | joueur, ennemis, effets | `1_core`, `5_data`, `6_assets` |
| `4_ui` | l'interface | `0_autoload`, `1_core`, `6_assets` |
| `5_data` | des `.tres` seulement, aucun code | `1_core`, `6_assets` |
| `6_assets` | images, sons, polices, aucun code | rien |
| `7_tests` | GdUnit4, en miroir du code | tout |

Un écran de menu se coupera donc en trois : son déroulé dans `2_sequence` (il décide), sa vue dans `4_ui` (elle
montre), ses entrées dans un `_input.gd` (seul à lire le clavier et la manette). La vue ne peut pas lire `5_data` :
c'est le déroulé qui lui donne ses réglages.

### 2. Les avertissements de GDScript sont des erreurs

Dans `project.godot`, bloc `[debug]`, chaque avertissement vaut 2 : une variable non typée (`untyped_declaration`),
une division entière, une variable qui en masque une autre, un paramètre inutilisé… arrêtent l'analyse. Un nom
d'itération inutilisé s'écrit avec un `_` devant (`for _i: int in TIRAGES`).

### 3. L'ordre d'exécution est nommé

`1_core/process_order.gd` : les entrées (`INPUT`), puis le déroulé (`FLOW`), puis les vues (`VIEWS`). Un nœud écrit
`process_priority = ProcessOrder.FLOW`, jamais un nombre.

### 4. Le hasard vient d'une seule source

`RngSource` crée un `RandomNumberGenerator` à partir de la graine de `5_data/jeu/sequence.tres` et le rend à qui le
demande (`Main.rng()`). Rien n'appelle `randi()` : la même graine redonne la même partie.

### 5. Les entrées : clavier et manette, menus compris

Chaque action de `[input]` a une touche (par sa position, `physical_keycode`, donc la même en AZERTY et en QWERTY) et
une commande de manette. Godot ne donne aux actions des menus que des touches : `ui_accept` (Entrée, Espace) et
`ui_cancel` (Échap). On leur ajoute A et B (`JOY_BUTTON_A`, `JOY_BUTTON_B`) ; sinon, à la manette, aucun bouton ne
valide. Les directions des menus (`ui_up`…) ont déjà la croix et le stick gauche.

### 6. La coquille enchaîne les écrans

`5_data/jeu/sequence.tres` (`SequenceDef`) nomme les écrans et leur scène, et le premier. `Main` ouvre le premier ;
quand la racine d'un écran émet `finished(next)`, elle ouvre `next` et libère l'ancien. Un écran ne connaît pas la
coquille ; ajouter un écran, c'est ajouter une ligne à la donnée. Le validateur refuse un premier écran inconnu et une
scène introuvable, avant tout lancement.

## Les tests

- `test_entrees.gd` : chaque action existe, a une touche et une commande de manette ; valider = A, revenir = B.
- `test_rng_source.gd` : même graine, même suite ; autre graine, autre suite.
- `test_sequence_def.gd` : la donnée du jeu est juste ; les trois fautes sont refusées.
- `test_main.gd` : avec un écran témoin, le premier s'ouvre, un écran fini ouvre celui qu'il nomme et l'ancien part,
  un écran inconnu laisse l'écran ouvert ; la scène du jeu s'ouvre.
- `test_documentation.gd` : chaque script et chaque membre public a son commentaire `##` (l'aide F1 de Godot).
