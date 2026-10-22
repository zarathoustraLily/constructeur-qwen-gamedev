# Phantom Camera (caméras 2D et 3D)

Version vérifiée : v0.11.0.3 (2026-07-19), licence MIT, dépôt `ramokz/phantom-camera` (3 618 étoiles au
2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier phantom_camera`.

## Ce qu'il résout

Plusieurs caméras « virtuelles » (`PhantomCamera3D`, `PhantomCamera2D`) décrivent chacune un cadrage : qui suivre,
comment, avec quel décalage. Une seule vraie caméra (`Camera3D` ou `Camera2D`) porte un enfant `PhantomCameraHost`,
qui la place sur la caméra virtuelle de plus haute `priority`, avec une transition (`tween_resource`) quand la
priorité change.

## Le choisir, ou Godot seul ?

- **Godot seul** suffit pour une seule caméra qui suit le joueur : un script sur la `Camera3D`, ou un `SpringArm3D`
  pour la troisième personne.
- **Phantom Camera** sert dès qu'il y a plusieurs cadrages à enchaîner (cinématique, zone, boss), un suivi de
  groupe, une zone morte, un rail (`Path3D`), ou des secousses réglées par ressource.

## Modes

- Suivi (`follow_mode`) : `NONE`, `GLUED` (collé à la cible), `SIMPLE` (avec `follow_offset`), `GROUP` (plusieurs
  cibles, recadrage), `PATH` (contraint à un `Path3D`), `FRAMED` (zone morte : ne suit que si la cible en sort),
  `THIRD_PERSON` (un `SpringArm3D` autour de la cible, `spring_length`).
- Regard (`look_at_mode`) : `NONE`, `MIMIC` (copie la rotation de la cible), `SIMPLE` (regarde la cible), `GROUP`
  (regarde le centre des cibles).
- Secousses : un `PhantomCameraNoiseEmitter3D` et sa ressource `PhantomCameraNoise3D`.
- Signaux utiles : `became_active`, `became_inactive`, `follow_target_changed`, `tween_completed` ; sur l'hôte,
  `pcam_became_active(pcam)`.

## Installation

1. Copier `addons/phantom_camera/` dans le projet.
2. Activer le plugin (Projet → Paramètres du projet → Plugins). L'activation ajoute l'autoload
   `PhantomCameraManager` (`res://addons/phantom_camera/scripts/managers/phantom_camera_manager.gd`) : sans lui,
   Godot écrit « Failed to retrieve non-existent singleton 'PhantomCameraManager' ».
3. Ajouter un `PhantomCameraHost` comme enfant de la `Camera3D` (sinon : « Needs to be a child of a Camera3D in
   order to work »).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : une caméra virtuelle suit en mode `SIMPLE` une cible qui avance à 3 m/s, avec un décalage
`(0, 2, 6)`. Après 90 images à 60 images par seconde, la vraie caméra est à 0,050 m de la position attendue.

```gdscript
var pcam := PhantomCamera3D.new()
pcam.priority = 10
pcam.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
pcam.follow_offset = DECALAGE
add_child(pcam)
pcam.follow_target = _cible
```

## Pièges

- La caméra suit avec une image de retard : 0,050 m à 3 m/s et 60 images par seconde (mesuré par l'exemple). Un test
  qui compare positions de caméra et de cible doit en tenir compte.
- Le panneau de mise à jour du plugin interroge GitHub (`HTTPRequest`) : hors ligne, il ne trouve rien, sans autre
  effet.
- Dans `res://addons`, Godot 4.7.2 n'applique pas les avertissements du projet (réglage par défaut
  `debug/gdscript/warnings/directory_rules`) : un projet aux avertissements stricts accepte le plugin tel quel.
