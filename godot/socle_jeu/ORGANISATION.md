# Plan d'organisation

À lire avant d'écrire. Chaque fichier a une place, et chaque dossier ne connaît que ceux qu'il a le droit de connaître. Le juge de structure de l'usine vérifie ces règles (`python -m usine.structure verifier <projet>`).

## Les dossiers, du chef d'orchestre à la matière brute

| Dossier | Rôle | Contenu |
| --- | --- | --- |
| `0_autoload/` | Le chef d'orchestre : ce qui dirige tout le jeu | `game_flow.gd` (lit la séquence, charge l'étape suivante), `game_state.gd` (score, vies), `event_bus.gd` (signaux partagés), `audio_manager.gd`, `trace.gd` (journal de comportement) |
| `1_core/` | Le cœur : les mécanismes, sans aucun contenu de jeu | `state_machine/` (StateMachine, State), `components/` (vie, zones de coups, arme), `step/` (Step, Sequence), `data/` (classes de réglages : ActorStats, WeaponStats, LevelBudget) |
| `2_sequence/` | Le déroulé : la liste ordonnée et ses étapes | `sequence.tres`, `boot.tscn`, `menus/`, `cinematics/`, `levels/` (`level_base/`, puis un dossier par niveau) |
| `3_entities/` | Les acteurs : scène, script et `states/` ensemble | `player/`, `enemies/<type>/`, `projectiles/`, `effects/` |
| `4_ui/` | L'interface | `hud/`, `overlays/` (pause, mise au point : posés par-dessus l'étape en cours) |
| `5_data/` | Les réglages, en ressources `.tres` | `actors/`, `enemies/`, `weapons/`, `levels/` (budgets) |
| `6_assets/` | La matière : modèles, textures, matériaux, audio, shaders, polices | aucun code |
| `7_tests/` | Les tests GdUnit4, en miroir des dossiers ci-dessus | `test_<sujet>.gd` |

## Qui connaît qui

- `1_core` ne référence aucun autre dossier : il se réutilise tel quel dans un autre jeu.
- `0_autoload` s'appuie sur `1_core` et lit `2_sequence/sequence.tres`. Il ne connaît aucun acteur, aucun écran ni aucun niveau en particulier.
- `2_sequence` assemble `3_entities` et `4_ui`. Cinématique, menu ou niveau : chaque étape hérite de `Step` et finit par `finish()`.
- `3_entities` et `4_ui` utilisent `1_core`, `5_data`, `6_assets` et les signaux de `0_autoload`. Un acteur ne connaît pas l'interface, l'interface ne connaît pas les acteurs : ils se parlent par `EventBus`.
- `5_data` et `6_assets` ne contiennent aucun script.
- La pause et la mise au point restent hors du déroulé : elles interrompent l'étape sans la faire avancer.

## Conventions

- GDScript typé partout ; `class_name` pour chaque type réutilisé ; noms de fichiers en `snake_case`, le fichier porte le nom de sa classe.
- `@export var` pour tout réglage ; les valeurs vivent dans un `.tres` de `5_data/`, jamais en dur dans le code.
- Un comportement = un état (`states/<acteur>_<etat>.gd`, nœud enfant de la `StateMachine`, nom en minuscules pour `transition_to`).
- Un composant par responsabilité (vie, zone de dégâts, zone de coups, arme).
- Signaux typés ; les échanges entre dossiers passent par `EventBus`.
- Rien d'alloué à chaque image ; les effets se détruisent eux-mêmes.
- Un test par comportement, dans `7_tests/` au même chemin relatif.
- Les acteurs d'un niveau sont posés à la main dans sa scène, sous `World/Enemies` : le code lit ce qui est posé.

## Je veux ajouter… je travaille là, en imitant ceci

| Ajout | Fichiers à créer ou modifier | Exemple à imiter |
| --- | --- | --- |
| Un état d'un acteur | `3_entities/<acteur>/states/<acteur>_<etat>.gd`, un nœud dans la `StateMachine` de sa scène, son test | `3_entities/player/states/player_dash.gd` |
| Un ennemi | `5_data/enemies/<type>.tres` → `3_entities/enemies/<type>/<type>.tscn` et `<type>.gd` → `states/` → posé dans `2_sequence/levels/<niveau>/` | le drone : `5_data/enemies/drone.tres`, `3_entities/enemies/drone/` |
| Une arme | `5_data/weapons/<arme>.tres` (WeaponStats) et son projectile dans `3_entities/projectiles/` ; un `WeaponComponent` dans la scène de l'acteur | `5_data/weapons/blaster.tres`, `bullet_player.tscn` |
| Un réglage | une propriété `@export` dans la classe de `1_core/data/`, sa valeur dans le `.tres` de `5_data/` | `ActorStats.dash_duration` |
| Un élément d'interface | `4_ui/hud/` ou `4_ui/overlays/<nom>/` (scène + script) ; il écoute `EventBus` | `4_ui/hud/hud.gd` |
| Un niveau | `2_sequence/levels/<niveau>/<niveau>.tscn` qui hérite de `level_base.tscn`, son budget dans `5_data/levels/`, une ligne dans `2_sequence/sequence.tres` | `2_sequence/levels/level_01/` |
| Un effet visuel | `3_entities/effects/<effet>/` (scène + script qui se détruit), un `@export var <effet>: PackedScene` sur l'acteur | `3_entities/effects/impact/`, `Drone.hit_effect` |

## Voir et mesurer

- `F3` en jeu : état courant et vie de chaque acteur (`4_ui/overlays/debug/`).
- Le journal `Trace` note chaque changement d'état, chaque coup et chaque score. Lancer le jeu avec `-- --trace=<fichier>` l'écrit dans ce fichier, avec la position des acteurs toutes les 0,5 s.
- Chaque niveau a son budget (`5_data/levels/<niveau>_budget.tres`), vérifié par `7_tests/2_sequence/test_<niveau>.gd`.
