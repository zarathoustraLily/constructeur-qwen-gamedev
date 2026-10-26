# Event Audio (sons déclenchés par étiquettes)

Version vérifiée : branche `main`, commit `2da31aa4e28dda5c462d80bc162538614c65fed3` (aucune version publiée,
dernière mise à jour 2024-11-04), GDScript (et une passerelle C#), licence MIT, dépôt `bbbscarter/event-audio-godot`
(72 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier
event_audio`.

## Ce qu'il résout

Le code du jeu ne connaît pas les fichiers son : il demande un événement par une étiquette (`"pas+herbe"`,
`"impact+metal+lourd"`). Des banques (`EAEventBank`) associent des étiquettes à des sons (`EAEvent` : plusieurs sons
tirés au hasard selon des poids, hauteur et volume variables). Si l'étiquette exacte manque, la banque retire les
étiquettes depuis la fin jusqu'à trouver un événement : `pas+herbe+mouille` → `pas+herbe` → `pas`. L'autoload
`EventAudio` crée le lecteur, le place sur la source, le suit et le libère quand le son est fini.

## Le choisir, ou Godot seul ?

- **Godot seul** : un `AudioStreamPlayer3D` par source et un `AudioStreamRandomizer` couvrent beaucoup de cas.
- **Event Audio** : quand le son dépend de combinaisons (surface, matière, force) et qu'on veut ajouter des
  variantes sans toucher au code. C'est un des seuls plugins audio de la liste ; il n'a plus bougé depuis 2024.

## API (lue dans le code)

- Autoload `EventAudio` (`EventAudioAPI`) : `play_2d(trigger, source, output_bus)`, `play_3d(trigger, source,
  output_bus)` (rendent un émetteur, ou `null` si aucun événement ne correspond), `stop(emetteur)`,
  `register_event_bank(bank)`, `unregister_event_bank(bank)`.
- `EAEventBank` : `entries` (des `EAEvent`), `find_entry_with_trigger(trigger)`. `EAEventBankMounter` : un nœud qui
  enregistre une banque tant qu'il est dans l'arbre.
- `EAEvent` : `trigger_tags`, `audio_streams`, `probability_weights`, `playback_settings`.
- `EAEventPlaybackSettings` : `playback_bus`, `volume_db`, `min_pitch`, `max_pitch`, `stationary`,
  `stop_when_source_dies`, `unit_size`, `max_db`, `attenuation`, `max_distance`.

## Installation

1. Copier `addons/event_audio/`.
2. Activer le plugin : il ajoute l'autoload `EventAudio` (`res://addons/event_audio/scenes/event_audio_autoload.tscn`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : une banque connaît `pas` et `pas+herbe`. Mesuré : `pas+herbe+mouille` joue `pas+herbe`,
`pas+pierre` joue `pas`.

```gdscript
var banque := EAEventBank.new()
banque.entries = [_evenement("pas"), _evenement("pas+herbe")]
EventAudio.register_event_bank(banque)
var emetteur: Variant = EventAudio.play_3d("pas+herbe+mouille", source)
```

## Pièges (relevés par l'exemple)

- Chaque `EAEvent` a besoin de ses `playback_settings` : le lecteur les lit avant de jouer.
- Un son encore joué à la sortie du programme fuit (« 4 ObjectDB instances were leaked at exit » : deux
  `AudioStreamWAV`, deux `AudioStreamPlaybackWAV`). Sans fenêtre et à cadence fixe, les images défilent plus vite
  que le temps réel : un son de 0,1 s joue encore après 60 images. Arrêter les émetteurs (`EventAudio.stop`), puis
  laisser quelques images de temps réel au serveur audio avant de quitter.
- Les émetteurs rendus sont de la classe interne `EventAudioAPI.AudioEmitter3D` (ou `…2D`) : `player`, `source`,
  `event`. L'exemple les garde en `Variant` pour rester court.
