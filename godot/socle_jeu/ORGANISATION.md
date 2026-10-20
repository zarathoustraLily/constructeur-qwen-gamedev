# Plan d'organisation

À lire avant d'écrire. Chaque fichier a une place, et chaque dossier ne dépend que de ceux de son tableau. Le juge des règles de l'usine vérifie ce plan et les règles mécaniques (`python -m usine.regles verifier <projet>`) ; chaque écart y est nommé par l'identifiant de sa règle (ORG-01, DOSSIERS, ARC-03…).

## Principes

1. **La simulation décide, la présentation montre.** Une animation peut donner le tempo d'une attaque ; elle n'en calcule jamais le résultat.
2. **Les valeurs vivent dans les données.** Aucun chiffre d'équilibrage dans un script ou une scène.
3. **L'ordre d'exécution est écrit, pas subi.** Quand deux systèmes dépendent l'un de l'autre, leur ordre est fixé par une priorité nommée.
4. **Les dépendances se déclarent.** Un objet reçoit ce dont il a besoin ; il ne va pas le chercher dans l'arbre ni dans un global.
5. **On résout le problème du jeu actuel.** Pas de généricité pour un futur projet, pas d'abstraction sans besoin démontré.

## Les dossiers

| Dossier | Contient | Peut dépendre de | Dans ce socle |
| --- | --- | --- | --- |
| `0_autoload/` | Services globaux persistants | `1_core/` | `game_flow.gd` (déroulement), `game_state.gd` (score, vies), `audio_manager.gd` (musique et volume seulement), `trace.gd` (journal), `capture.gd` (captures de l'usine) |
| `1_core/` | Mécanismes et contrats génériques | rien | `components/` (vie, zones de coups, arme), `state_machine/`, `step/` (Step, Sequence), `data/` (ActorStats, WeaponStats, LevelBudget, GameRules), `process_order.gd` |
| `2_sequence/` | Ordre des étapes et leur réalisation | tous sauf `7_tests/` | `boot.tscn`, `sequence.tres`, `menus/`, `cinematics/`, `levels/` (`level_base/`, puis un dossier par niveau) |
| `3_entities/` | Joueur, ennemis, projectiles, effets : logique et présentation dans des scripts distincts | `1_core/`, `5_data/`, `6_assets/` | `player/`, `enemies/<type>/`, `projectiles/`, `effects/` |
| `4_ui/` | HUD, surcouches | `0_autoload/`, `1_core/`, `6_assets/` | `hud/`, `overlays/` (pause, mise au point) |
| `5_data/` | Paramètres de conception en `.tres`, aucun code | `1_core/`, `6_assets/` | `actors/`, `enemies/`, `weapons/`, `levels/`, `game/` |
| `6_assets/` | Modèles, textures, audio, shaders, matériaux, polices, aucun code | rien | `materials/` (et `audio/` pour les sons) |
| `7_tests/` | Tests GdUnit4, en miroir du chemin testé | tout | `7_tests/<chemin du code>/test_<nom>.gd` |

- Aucun nouveau dossier à la racine de `res://` ; seule exception : `addons/`.
- **Décors procéduraux** (règle du dépôt, `CLAUDE.md`, « Règles qui priment ») : les générateurs `@tool` et leurs scènes vivent dans `6_assets/Mesh/Procedural/<famille>/` et peuvent connaître `1_core/` et `5_data/` ; leurs shaders dans `6_assets/Shader/Procedural/<famille>/` ; leurs données (palettes, listes, cotes), en scripts de constantes, dans `5_data/DECORS/<famille>/` ; les outils communs (maillage, fonctions de shader partagées) dans `1_core/procedural/` et `6_assets/Shader/Procedural/`. Ailleurs, `5_data/` et `6_assets/` restent sans code.
- Une entité ne dépend d'aucune autre entité : le drone ne connaît pas le joueur, il reçoit une cible. Le niveau assemble et fournit les dépendances par `setup()`.
- L'interface ne connaît ni les acteurs ni les niveaux : elle écoute un autoload (`GameState.score_changed`) ou le niveau lui pousse l'information (`hud.show_health`).
- La pause et la mise au point restent hors du déroulé : elles interrompent l'étape sans la faire avancer.

## Conventions vérifiées par le juge

- **Typage partout** (COD-02) : variables, constantes, paramètres et retours ; `Array[T]` et `Dictionary[K, V]`. `project.godot` met `UNTYPED_DECLARATION` en erreur.
- **Syntaxe Godot 4** (COD-04) : `await`, `@export`, `@onready`, `CharacterBody3D`, `instantiate()`, `signal.connect(callable)`.
- **Nommage** (COD-01) : classes et nœuds en PascalCase ; fichiers, fonctions, variables et signaux en snake_case ; constantes en CONSTANT_CASE ; le fichier porte le nom de sa `class_name`.
- **Données** (DAT-01, DAT-02) : chaque famille de réglages est une classe `Resource` avec `class_name` dans `1_core/data/`, avec un `id` et une fonction `validate()` ; ses valeurs vivent dans un `.tres` de `5_data/`. Les scripts de `2_sequence/` et `3_entities/` n'écrivent aucun nombre autre que 0 et 1.
- **Présentation à part** (ARC-03) : sprites, maillages, sons, particules et tweens d'une entité vivent dans `<nom>_view.gd`, à côté de sa logique. La vue écoute des signaux (`damaged`, `died`) et ne décide de rien.
- **Entrées à part** (ARC-04) : seul `<nom>_input.gd` lit `Input` ; il transmet des intentions (`player.set_intent(...)`), la logique ne lit jamais le clavier.
- **Dépendances fournies** (ARC-06) : `@export` typé, `setup()` ou signal ; jamais `get_node("/root/...")` ni chemin qui remonte (`"../"`). Les groupes restent permis.
- **Temps** (SIM-01, SIM-08) : le gameplay tourne dans `_physics_process` ; `_process` ne sert qu'à l'affichage. Une durée de gameplay s'arrête en pause : décompte dans la logique, nœud `Timer`, ou `get_tree().create_timer(durée, false)`.
- **Ordre** (SIM-02) : `process_physics_priority = ProcessOrder.MOVEMENT` (et les autres valeurs de `1_core/process_order.gd`), jamais un nombre.
- **Hasard** (SIM-09) : un tirage qui compte vient d'un `RandomNumberGenerator` reçu en dépendance ; `randf()`, `pick_random()` seulement dans une vue.
- **Tests** (QA-01) : un test par comportement, dans `7_tests/` au même chemin que le code testé.

## Conventions de travail (rappelées, pas jugées)

- Un comportement = un état (`states/<acteur>_<etat>.gd`, nœud enfant de la `StateMachine`, nom en minuscules pour `transition_to`).
- Un composant par responsabilité (vie, zone de dégâts, zone de coups, arme).
- Signaux typés, nommés au passé ; appeler vers le bas, signaler vers le haut.
- Une dépendance obligatoire manquante produit une erreur explicite dès `_ready()` ou `setup()`.
- Rien d'alloué à chaque image ; les effets se détruisent eux-mêmes.
- Les acteurs d'un niveau sont posés à la main dans sa scène, sous `World/Enemies` : le code lit ce qui est posé.

## Je veux ajouter… je travaille là, en imitant ceci

| Ajout | Fichiers à créer ou modifier | Exemple à imiter |
| --- | --- | --- |
| Un état d'un acteur | `3_entities/<acteur>/states/<acteur>_<etat>.gd`, un nœud dans la `StateMachine` de sa scène, son test `7_tests/3_entities/<acteur>/test_<acteur>.gd` | `3_entities/player/states/player_dash.gd` |
| Un ennemi | `5_data/enemies/<type>.tres` → `3_entities/enemies/<type>/<type>.tscn`, `<type>.gd` et `<type>_view.gd` → `states/` → posé dans `2_sequence/levels/<niveau>/`, qui lui donne ses dépendances par `setup()` | le drone : `5_data/enemies/drone.tres`, `3_entities/enemies/drone/` |
| Une arme | `5_data/weapons/<arme>.tres` (WeaponStats) et son projectile dans `3_entities/projectiles/` ; un `WeaponComponent` dans la scène de l'acteur, son projectile fourni par le niveau | `5_data/weapons/blaster.tres`, `bullet_player.tscn` |
| Un réglage | une propriété `@export` typée dans la classe de `1_core/data/` (et sa ligne dans `validate()`), sa valeur dans le `.tres` de `5_data/` | `ActorStats.dash_duration`, `GameRules.level_end_delay` |
| Un élément d'interface | `4_ui/hud/` ou `4_ui/overlays/<nom>/` (scène + script) ; il écoute `GameState` ou reçoit l'information du niveau | `4_ui/hud/hud.gd` |
| Un niveau | `2_sequence/levels/<niveau>/<niveau>.tscn` qui hérite de `level_base.tscn`, son budget dans `5_data/levels/`, une ligne dans `2_sequence/sequence.tres` | `2_sequence/levels/level_01/` |
| Un effet visuel | `3_entities/effects/<effet>/` (scène + script qui se détruit) ; joué par le `_view` de l'acteur, la scène fournie par le niveau | `3_entities/effects/impact/`, `DroneView._on_damaged` |
| Un son | bruitage : un `AudioStreamPlayer3D` dans la scène de l'acteur, joué par son `_view` ; musique : `AudioManager.play_music` | `0_autoload/audio_manager.gd` |

## Voir et mesurer

- `F3` en jeu : état courant et vie de chaque acteur (`4_ui/overlays/debug/`).
- Le journal `Trace` note chaque changement d'état, chaque coup et chaque score. Lancer le jeu avec `-- --trace=<fichier>` l'écrit dans ce fichier, avec la position des acteurs toutes les 0,5 s.
- Chaque niveau a son budget (`5_data/levels/<niveau>_budget.tres`), vérifié par `7_tests/2_sequence/levels/<niveau>/test_<niveau>.gd`.
