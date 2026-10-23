# Input Helper (manette, clavier : appareil utilisé et remappage)

Version vérifiée : v4.7.0 (2025-06-08), GDScript pur, licence MIT, dépôt `nathanhoad/godot_input_helper`
(1 111 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier
input_helper`.

## Ce qu'il résout

Un autoload `InputHelper` qui :
- sait quel appareil le joueur utilise (clavier et souris, manette Xbox, PlayStation, Switch, Steam Deck,
  générique) et le signale quand il change ;
- lit et change les touches et boutons de chaque action de l'`InputMap` (remappage), sépare clavier et manette, et
  les sérialise pour la sauvegarde ;
- fait vibrer la manette avec trois intensités.

## Le choisir, ou Godot seul ?

- **Godot seul** : `InputMap` et `Input` suffisent pour lire des actions et en changer les événements
  (`InputMap.action_erase_events`, `action_add_event`) ; c'est ce que fait le menu des commandes du kart de nos
  cours.
- **Input Helper** évite de réécrire la détection d'appareil (pour afficher les bonnes icônes de boutons), l'échange
  de touches déjà prises et la sauvegarde des réglages.

## API (lue dans le code de la v4.7.0)

- Signaux : `device_changed(device, device_index)`, `keyboard_input_changed(action, input)`,
  `joypad_input_changed(action, input)`, `joypad_changed(device_index, is_connected)`.
- Appareil : `device`, `device_index`, `has_joypad()`, `guess_device_name()`, `get_device_from_event(event)`,
  `get_joy_name(index)` ; constantes `DEVICE_KEYBOARD`, `DEVICE_XBOX_CONTROLLER`, `DEVICE_PLAYSTATION_CONTROLLER`,
  `DEVICE_SWITCH_CONTROLLER`, `DEVICE_STEAMDECK_CONTROLLER`, `DEVICE_GENERIC`.
- Actions : `get_keyboard_input_for_action(action)`, `set_keyboard_input_for_action(action, input, swap_if_taken)`,
  `get_joypad_input_for_action(action)`, `set_joypad_input_for_action(action, input, swap_if_taken)`,
  `get_label_for_input(input)`, `serialize_inputs_for_actions(actions)`, `deserialize_inputs_for_actions(texte)`,
  `reset_all_actions()`.
- Vibration : `rumble_small`, `rumble_medium`, `rumble_large`, `start_rumble_*`, `stop_rumble(device)`.

## Installation

1. Copier `addons/input_helper/`.
2. Activer le plugin : il ajoute l'autoload `InputHelper` (`res://addons/input_helper/input_helper.gd`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : l'action « sauter » reçoit le bouton A de la manette, relu ensuite ; l'événement de la
touche Espace vient du clavier (`keyboard`), celui du bouton A d'une manette générique (`generic` : aucune manette
branchée).

```gdscript
var bouton_a := InputEventJoypadButton.new()
bouton_a.button_index = JOY_BUTTON_A
InputHelper.set_joypad_input_for_action("sauter", bouton_a)
var manette: String = InputHelper.get_device_from_event(bouton_a)
```

## Pièges (relevés par l'exemple)

- Sans fenêtre (`--headless`), `device_changed` n'est jamais émis : le plugin attend une seconde entre deux
  changements d'appareil en comptant les images **dessinées** (`Engine.get_frames_drawn()`), qui restent à 0 sans
  rendu (mesuré : 0 image dessinée, `Engine.get_frames_per_second()` à 1,0, appareil resté `keyboard` après un
  appui simulé sur le bouton A). Un test sans fenêtre vérifie donc `get_device_from_event`, pas le signal.
- `JOY_BUTTON_A` vaut 0 : un `button_index` à 0 n'est pas un bouton absent.
