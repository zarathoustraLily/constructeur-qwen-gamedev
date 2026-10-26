# Menu navigable à la manette : navigation au focus, croix et bouton A (ui_accept)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier menu_manette`.

## Ce que fait le morceau

Un menu de fin de partie : à l'ouverture, le premier bouton prend le focus (`grab_focus`) ; la croix déplace le focus (`ui_down`, `ui_up`) ; A ou Entrée valide (`ui_accept`). Chaque bouton émet un signal ; le déroulé y répond.

## Quand l'employer

Menu pause, titre, fin de partie, options, boîte de dialogue à choix : tout menu d'un jeu joué à la manette.

Dans un projet qui suit le plan : `4_ui/overlays/<menu>/` (scène et script) ; le menu émet un signal par choix, `2_sequence/` décide (principe 1) ; les boutons de manette de `ui_accept` et `ui_cancel` se déclarent dans `project.godot`.

## Le code (`project.godot`, extrait vérifié)

```ini
[input]

ui_accept={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194309,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null),
Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194310,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null),
Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":0,"pressure":0.0,"pressed":true,"script":null)
]
}
ui_cancel={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194305,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null),
Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":1,"pressure":0.0,"pressed":true,"script":null)
]
}
```

## Le code (`4_ui/overlays/game_over/game_over_menu.gd`, vérifié)

```gdscript
class_name GameOverMenu
extends CanvasLayer
## Menu de fin de partie, jouable à la manette : à l'ouverture, le premier bouton prend le focus ; la croix et le
## stick le déplacent (ui_up, ui_down), A ou Entrée valide (ui_accept). Il ne décide de rien : il émet un signal par
## choix, le déroulé (2_sequence/) y répond. Entrées : open().

signal retry_requested
signal menu_requested
signal quit_requested

@onready var retry_button: Button = $Center/Box/Retry
@onready var menu_button: Button = $Center/Box/Menu
@onready var quit_button: Button = $Center/Box/Quit


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(retry_requested.emit)
	menu_button.pressed.connect(menu_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)


func open() -> void:
	visible = true
	retry_button.grab_focus()  # sans focus, la manette ne peut rien choisir
```

## Le code (`4_ui/overlays/game_over/game_over_menu.tscn`, vérifié)

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://4_ui/overlays/game_over/game_over_menu.gd" id="1_menu"]

[node name="GameOverMenu" type="CanvasLayer"]
script = ExtResource("1_menu")

[node name="Center" type="CenterContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Box" type="VBoxContainer" parent="Center"]
layout_mode = 2

[node name="Retry" type="Button" parent="Center/Box"]
layout_mode = 2
text = "Rejouer"

[node name="Menu" type="Button" parent="Center/Box"]
layout_mode = 2
text = "Menu principal"

[node name="Quit" type="Button" parent="Center/Box"]
layout_mode = 2
text = "Quitter"
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : avant open(), focus aucun ; après, Retry ; croix bas ×2 : Quit ; ×3 : Quit ; A : quit_requested ; Entrée : encore.

## Pièges

- Sans focus, la manette ne peut rien choisir : la croix ne fait rien tant qu'aucun bouton n'a le focus (mesuré : focus vide avant `open()`) ; `grab_focus()` à l'ouverture.
- `ui_accept` et `ui_cancel` n'ont par défaut aucun bouton de manette (mesuré dans le cours roguelike, 2026-10-21) : déclarer A et B dans `project.godot`, en gardant Entrée, Entrée du pavé, Espace et Échap (mesuré : A et Entrée valident).
- Au bout de la liste, le focus reste sur le dernier bouton (mesuré) ; pour boucler, poser `focus_neighbor_bottom` du dernier sur le premier (référence des classes, `Control.focus_neighbor_bottom` ; non mesuré ici).
- Un `Button` émet `pressed` au relâchement de `ui_accept` (mesuré dans le cours roguelike, 2026-10-21) : un test envoie l'appui puis le relâchement.
