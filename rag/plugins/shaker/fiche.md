# Shaker (secousses : caméra, objets, propriétés)

Version vérifiée : v1.0.7 (2024-09-15, plus mise à jour depuis), GDScript pur, licence MIT, dépôt
`Eneskp3441/Shaker` (462 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 :
`python -m usine.rag.plugins verifier shaker`.

## Ce qu'il résout

Secouer la position, la rotation ou l'échelle de nœuds 2D ou 3D (`ShakerComponent2D`, `ShakerComponent3D`), ou
n'importe quelle propriété (`ShakerComponent`), selon un préréglage (`ShakerPreset2D`, `ShakerPreset3D`) qui
empile des formes de secousse : aléatoire, brownienne, bruit, courbe, sinus, dents de scie, carré, ou le volume
d'un bus audio (`ShakerType…1D/2D/3D`). Des émetteurs (`ShakerEmitter3D`) propagent une secousse aux récepteurs
proches (`ShakerReceiver3D`) : une explosion qui secoue ce qui l'entoure.

## Le choisir, ou Godot seul ?

- **Godot seul** : un décalage aléatoire de la caméra dans `_process`, amorti par une variable « trauma », suffit
  pour une secousse simple (c'est `1_core/camera/shake_camera_3d.gd` dans le roguelike de nos cours).
- **Shaker** : plusieurs formes combinées, une montée et une descente réglées (`fade_in`, `fade_out`), des
  secousses à distance, réglables dans l'inspecteur.
- Le plugin n'a plus de version depuis 2024 ; Juicee (2026) et Phantom Camera (bruit de caméra) couvrent aussi ce
  besoin.

## API (lue dans le code de la v1.0.7)

- `ShakerComponent3D` : `custom_target`, `Targets` (les nœuds à secouer), `shakerPreset`, `duration` (0 : sans
  fin), `intensity`, `shake_speed`, `fade_in`, `fade_out`, `randomize`, `AutoPlay` ; `play_shake()`,
  `stop_shake()`, `force_stop_shake()`, `shake(preset, mode, duration, speed, intensity, fade_in, fade_out)`.
- `ShakerPreset3D` : `PositionShake`, `RotationShake`, `ScaleShake` (des `Array[ShakerTypeBase3D]`).
- Formes (`ShakerTypeBase3D`) : `amplitude`, `offset`, `BlendingMode`, `fade_in`, `fade_out`, `start_percent`,
  `end_percent`.

## Installation

Copier `addons/shaker/`. Aucun autoload.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : une secousse aléatoire d'amplitude 0,5 m pendant 0,5 s. Mesuré : écart maximal 0,584 m,
puis le nœud revient exactement à sa place (0,0000 m) après 90 images.

```gdscript
var forme := ShakerTypeRandom3D.new()
forme.amplitude = Vector3(0.5, 0.5, 0.5)
var prereglage := ShakerPreset3D.new()
prereglage.PositionShake = [forme]
_secoueur.custom_target = true
_secoueur.Targets = [_cible]
_secoueur.shakerPreset = prereglage
_secoueur.duration = 0.5
_secoueur.play_shake()
```

## Pièges

- L'amplitude vaut par axe : sur trois axes à 0,5 m, l'écart peut dépasser 0,5 m (0,584 m mesuré).
- La secousse avance dans `_process` : elle suit le temps d'affichage, pas la cadence physique.
