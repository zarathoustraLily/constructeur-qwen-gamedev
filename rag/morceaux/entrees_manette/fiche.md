# Déplacement à la manette : stick, croix et zone morte (Input.get_vector)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier entrees_manette`.

## Ce que fait le morceau

Les actions de déplacement reçoivent le stick gauche et la croix de la manette dans `project.godot`, avec une zone morte. `Input.get_vector` les lit en un vecteur : rien sous la zone morte, course remise à l'échelle au-delà, longueur jamais au-dessus de 1 en diagonale.

## Quand l'employer

Tout jeu jouable à la manette : déplacement, visée au stick droit, menus.

Dans un projet qui suit le plan : les actions dans `project.godot` ; seul `<acteur>_input.gd` lit `Input` et transmet des intentions (règle ARC-04 du plan) ; les actions du socle n'ont que le clavier : on y ajoute ces événements.

## Le code (`project.godot`, extrait vérifié)

```ini
[input]

move_left={
"deadzone": 0.2,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":-1.0,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":13,"pressure":0.0,"pressed":true,"script":null)
]
}
move_right={
"deadzone": 0.2,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":1.0,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":14,"pressure":0.0,"pressed":true,"script":null)
]
}
move_up={
"deadzone": 0.2,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":1,"axis_value":-1.0,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":11,"pressure":0.0,"pressed":true,"script":null)
]
}
move_down={
"deadzone": 0.2,
"events": [Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":1,"axis_value":1.0,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":12,"pressure":0.0,"pressed":true,"script":null)
]
}
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : stick à 0,15 → (0.0, 0.0) ; à 0,6 → (0.5, 0.0) ; en diagonale (0,9 ; -0,9) → (0.707107, -0.707107), longueur 1.000 ; croix gauche → (-1.0, 0.0).

## Pièges

- Sous la zone morte, `get_vector` rend zéro ; au-delà, la course est remise à l'échelle : 0,6 avec une zone de 0,2 donne 0,5 (mesuré).
- `device: -1` dans l'action : toutes les manettes ; un `InputEvent*.new()` vaut l'appareil 0, la première manette (mesuré par l'exemple : l'appareil 0 déclenche l'action).
- Dans un test, un stick passe par `Input.parse_input_event` puis `Input.flush_buffered_events()` ; `Viewport.push_input` ne suffit pas pour la navigation au stick (mesuré dans le cours roguelike, 2026-10-21).
- `ui_accept` et `ui_cancel` n'ont par défaut aucun bouton de manette : les ajouter (A, B) pour les menus (mesuré dans le cours roguelike, 2026-10-21).
