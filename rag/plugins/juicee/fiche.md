# Juicee (ressenti de jeu : hit stop, secousses, flashs, effets d'écran)

Version vérifiée : v2.0.0 (2026-10-13), GDScript pur, licence MIT, dépôt `Kelpekk/Juicee` (158 étoiles au
2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier juicee`.

## Ce qu'il résout

Le « jus » d'un jeu : les petits effets qui font sentir un coup, un saut, une récompense. Un `JuiceePlayer` (nœud)
joue une `JuiceeSequence` (ressource) : une liste d'effets (`JuiceeEffect`), à la suite ou en parallèle
(`parallel`). Plus de cent effets sont fournis (`effects/`), entre autres :
- temps : `hit_stop`, `freeze_frame`, `time_scale_ramp`, `stutter` ;
- caméra et écran : `shake`, `shake_3d`, `directional_shake`, `zoom`, `zoom_pulse`, `fov_3d`, `camera_bob`,
  `vignette`, `chromatic`, `screen_tint`, `screen_wipe`, `cinematic_bars`, `radial_blur` ;
- objets : `squash_land`, `stretch`, `jelly_wobble`, `bounce`, `pop_in`, `knockback`, `recoil`, `flash`, `flicker`,
  `afterimage`, `trail`, `outline` ;
- texte et interface : `damage_number`, `floating_text`, `typewriter`, `text_wobble`, `button_punch` ;
- son et vibration : `sound`, `pitch_shift`, `low_pass`, `music_duck`, `rumble`.

Il tient compte de l'accessibilité (`JuiceeAccessibility`, qui étiquette par exemple les secousses d'écran, `TAG_SCREENSHAKE`, d'après le code).

## Le choisir, ou Godot seul ?

- **Godot seul** : un `Tween` et `Engine.time_scale` suffisent pour un ou deux effets.
- **Juicee** : des séquences d'effets réglées dans l'inspecteur, réutilisées partout (un coup, un tir, un ramassage),
  avec des temps de recharge et un réglage d'accessibilité commun.

## API (lue dans le code de la v2.0.0)

- `JuiceePlayer` : `sequence`, `sequences`, `auto_play`, `target_path`, `trigger_source`, `trigger_signal`,
  `queue_during_cooldown` ; `play(nom_ou_parametres, parametres)`, `stop()`, `is_on_cooldown()`,
  `cooldown_remaining()` ; signaux `started`, `finished`, `sequence_started`, `sequence_finished`.
- `JuiceeSequence` : `effects`, `parallel` ; `play(context, params)`, `stop()`, `pause()`, `resume()`,
  `is_playing()`.
- `JuiceeHitStopEffect` : `freeze_duration` (secondes réelles), `time_scale_during`, `recover_time`, `pre_delay`.

## Installation

1. Copier `addons/juicee/`.
2. Activer le plugin : il ajoute l'autoload `Juicee` (`res://addons/juicee/core/juicee.gd`).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : un hit stop de 0,1 s. Mesuré : `Engine.time_scale` tombe à 0,0, puis revient à 1,0.

```gdscript
var arret := JuiceeHitStopEffect.new()
arret.freeze_duration = 0.1
var sequence := JuiceeSequence.new()
sequence.effects = [arret]
_joueur.sequence = sequence
_joueur.play()
```

## Pièges

- À `Engine.time_scale = 0`, Godot appelle toujours `_process` et `_physics_process`, mais avec un `delta` nul
  (mesuré : 30 images de physique en 30 images d'affichage, somme des `delta` 0,0). Un compteur d'images continue
  donc d'avancer pendant un hit stop ; un minuteur fondé sur `delta` s'arrête.
- Le hit stop compte en secondes réelles (minuteur qui ignore `time_scale`) : il ne se bloque pas lui-même.
- Plusieurs hit stops qui se chevauchent sont empilés (`JuiceeStateStack`), d'après le code : le temps revient à
  la valeur d'avant le premier.
