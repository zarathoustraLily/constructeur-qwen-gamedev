# GdUnit4 (tests unitaires et tests de scène)

Version vérifiée : v6.2.2 (2026-10-07), GDScript (et C#), licence MIT, dépôt `MikeSchulze/gdUnit4` (1 274 étoiles
au 2026-10-22). Plugin activé sans erreur dans l'éditeur 4.7.2 : `python -m usine.rag.plugins verifier gdunit4`.
Son usage est vérifié tous les jours par nos cours : la version 6.2.1 fait passer les suites des 14 étapes du kart,
des 14 du roguelike et des 39 projets des bâtiments.

## Ce qu'il résout

Écrire des tests pour un jeu Godot : des suites (`extends GdUnitTestSuite`) dont chaque fonction `test_…` vérifie
une règle par des assertions (`assert_that`, `assert_int`, `assert_vector`…), des tests de scène qui simulent des
images et des entrées (`scene_runner`), des assertions sur les erreurs poussées par le jeu (`assert_error`), des
doublures (`mock`, `spy`). On les lance depuis l'éditeur ou en ligne de commande.

## Le choisir, ou un autre ?

- **GdUnit4** est l'outil de tests de nos cours et du socle : c'est celui que Qwen doit savoir écrire.
- **GUT** fait le même travail avec une autre syntaxe ; ne pas mélanger les deux dans un projet.

## Commande (celle des cours, vérifiée)

```bat
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd ^
  --ignoreHeadlessMode -c -rc 1 -a res://7_tests/chemin/test_x.gd
```

## Exemple (une vraie suite du roguelike, étape 14, `7_tests/0_autoload/test_game_state.gd`)

```gdscript
extends GdUnitTestSuite
## Règles de l'état qui dure : le rang part de 1 ; un niveau fini le monte ; une défaite le ramène à 1.

var _saved: int


func before_test() -> void:
	_saved = GameState.level


func after_test() -> void:
	GameState.level = _saved


func test_un_niveau_fini_monte_le_rang_une_defaite_le_ramene_a_un() -> void:
	GameState.reset()
	assert_int(GameState.level).is_equal(1)
	GameState.finish_level()
	GameState.finish_level()
	assert_int(GameState.level).is_equal(3)
	GameState.reset()
	assert_int(GameState.level).is_equal(1)
```

Un avertissement attendu se vérifie par `assert_error` (le kart, `test_fish_school_view.gd`) :
`await assert_error(func() -> void: …).is_push_warning("Poissons : aucune eau …")`, précédé de
`@warning_ignore("redundant_await")` quand les avertissements sont des erreurs.

## Pièges (relevés sur nos cours)

- **Une suite peut réussir avec des erreurs du jeu** : GdUnit4 n'échoue que sur ses assertions. Des lignes
  « ERROR: … » ou « WARNING: … » écrites par le jeu passent avec « 0 errors | 0 failures » et le code 0. Il faut lire
  chaque ligne de sortie (règle 5.5). Une erreur attendue par un cas se reconnaît à sa pile, qui passe par
  `GdUnitGodotErrorAssertImpl`.
- **Noms interdits** avec les avertissements en erreurs : une variable locale `before` masque une fonction de
  `GdUnitTestSuite`, `name` masque la propriété de `Node` ; la suite ne compile plus (`shadowed_*`).
- **Sous Windows**, l'historique des rapports finit par échouer (« Delete … failed ») : garder `-rc 1`.
- `-d --remote-debug` n'est pas nécessaire : les suites passent sans débogueur.
- **Un son encore joué à la sortie fuit** (« ObjectDB instances were leaked at exit ») : un crochet de session
  (`GdUnitTestSessionHook`, déclaré dans `[gdunit4] hooks/session_hooks` de `project.godot`) qui laisse trois fois
  30 ms de temps réel au serveur audio règle le cas (`7_tests/1_core/silence_audio.gd` dans nos cours).
- Un test de manette sans fenêtre injecte les événements par `Input.parse_input_event` puis
  `Input.flush_buffered_events`.
