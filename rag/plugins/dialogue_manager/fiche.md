# Dialogue Manager (dialogues à embranchements)

Version vérifiée : v4.1.0 (2026-09-04), GDScript (et une passerelle C#), licence MIT, dépôt
`nathanhoad/godot_dialogue_manager` (3 936 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier dialogue_manager`.

## Ce qu'il résout

Écrire les dialogues comme un script de théâtre, dans des fichiers `.dialogue` importés en ressources
(`DialogueResource`) : des titres (`~ start`), des répliques (`Personnage: texte`), des choix (`- texte`, et leur
suite indentée), des sauts (`=> titre`, `=> END`), des conditions et des mutations qui appellent le code du jeu.
L'autoload `DialogueManager` lit le dialogue ligne par ligne ; une bulle d'exemple est fournie
(`show_example_dialogue_balloon`).

## Le choisir, ou un autre ?

- **Godot seul** : quelques répliques fixes tiennent dans une ressource ou un tableau de chaînes.
- **Dialogue Manager** : des dialogues longs, à choix et à conditions, écrits par quelqu'un qui ne code pas,
  traduisibles, avec un éditeur dans Godot.
- **Dialogic 2** fait davantage (portraits, voix, éditeur de chronologie) mais sa dernière version est une alpha qui
  exige Godot 4.5 et plus.

## API (lue dans le code de la v4.1.0)

- `DialogueManager` : `get_next_dialogue_line(resource, key, extra_game_states)` (à attendre avec `await`),
  `create_resource_from_text(text)`, `show_dialogue_balloon(resource, cue)`, `show_example_dialogue_balloon`,
  `set_default_balloon(scene)`, `register_state_context(alias, node)` ; signaux `dialogue_started`,
  `got_dialogue(line)`, `mutated(mutation)`, `dialogue_ended(resource)`, `passed_cue(cue)`.
- `DialogueLine` : `character`, `text`, `responses`, `next_id`, `tags`, `type`, `speeds`, `time`.
- `DialogueResponse` : `text`, `next_id`, et la condition éventuelle du choix.

## Installation

1. Copier `addons/dialogue_manager/`.
2. Activer le plugin : il ajoute l'autoload `DialogueManager` (`res://addons/dialogue_manager/dialogue_manager.gd`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : « Marchand: Bonjour, voyageur. » avec deux choix ; le premier mène à « Un marchand de
potions. ».

```gdscript
var dialogue := DialogueManager.create_resource_from_text(TEXTE) as DialogueResource
var accueil: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, "start")
var choix := accueil.responses[0] as DialogueResponse
var reponse: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, choix.next_id)
```

## Pièges (relevés par l'exemple)

- Une fois une ligne lue, la ressource de dialogue se range dans ses propres données de ligne (mesuré : 0 ligne
  contient la ressource avant lecture, 1 après ; `data.resource = resource` dans `dialogue_manager.gd`). Cette
  référence circulaire la garde en mémoire : à la sortie, Godot écrit « 3 ObjectDB instances were leaked at exit »
  et « 1 resources still in use at exit » (`dialogue_resource.gd`). Mettre la variable à `null` n'y change rien. Le
  jeu n'en souffre pas, mais un test qui lit chaque ligne de sortie doit savoir d'où viennent ces deux lignes.
- `get_next_dialogue_line` est une coroutine (elle contient des `await`) : l'appeler avec `await`, comme dans
  l'exemple.
