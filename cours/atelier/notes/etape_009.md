# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le son du jeu, au-delà du volume : des effets qui se superposent sans se couper et ne se
répètent pas à l'identique, et une musique qui passe d'un morceau à l'autre sans trou.

Ce qu'on obtient : une réserve de huit voix pour les effets, chaque effet un peu plus aigu ou plus grave que le
précédent ; deux lecteurs de musique qui se relaient en fondu enchaîné à puissance constante.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les réglages du son sont dans `5_data/audio/audio.tres` ; la scène principale les donne au service audio.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une réserve de voix

Un seul `AudioStreamPlayer` coupe son effet quand on lui en donne un autre. `1_core/audio/sfx_pool.gd` crée
plusieurs lecteurs sur le bus des effets et donne à chaque effet la première voix libre (`playing` faux) ; quand
toutes jouent, il reprend la plus ancienne, à tour de rôle. Le nombre de voix borne le coût : on n'entend pas plus
de huit effets à la fois de toute façon.

### 2. Des variations, avec une graine

Le même bruit de pas répété à l'identique sonne comme une mitraillette. Chaque effet reçoit une hauteur
(`pitch_scale`) et un volume (`volume_db`) légèrement tirés au hasard, dans des bornes réglées, avec un
`RandomNumberGenerator` à graine fixe : les tests retrouvent les mêmes tirages.

### 3. Un fondu enchaîné à puissance constante

`1_core/audio/music_fader.gd` a deux lecteurs : le nouveau morceau part sur l'autre, et pendant le fondu, l'ancien
suit le cosinus et le nouveau le sinus de l'avancée × PI/2. La somme de leurs carrés vaut toujours 1 : la puissance
entendue ne creuse pas au milieu, ce qu'un fondu linéaire ferait. Les gains passent en décibels par
`Volume.to_db` (étape 1). À la fin, l'ancien lecteur s'arrête ; relancer le même morceau ne refait rien.

### 4. Le service audio les tient

`0_autoload/audio_manager.gd` gagne `setup(réglages)` : il crée la réserve et les lecteurs de musique, une seule
fois. La scène principale lui donne ses réglages (un `.tres` de `5_data`) : un service global ne va pas chercher
ses données lui-même. `play_sfx` et `play_music` ne font rien avant `setup`.
