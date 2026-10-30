# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, en jouant : « il n'y a pas de sound design », « il n'y a pas de musique », puis
« toujours pas de son ? ». Cette étape donne un son à chaque événement du combat, et une musique qui entre au réveil
du Gardien.

## Les fichiers du projet

{FILES_TABLE}

## Les sons et leur licence

- Bruitages : Kenney, « Impact Sounds » et « Sci-fi Sounds », CC0 (`6_assets/Audio/SFX/impact/`, `scifi/`, avec leur
  `License.txt`). 72 fichiers `.ogg` retenus, de 0,1 à 2 s.
- Musique : Juhani Junkala, « Epic Boss Battle [Seamlessly Looping] », CC0 (`6_assets/Audio/Music/`). 123 s, WAV
  44,1 kHz stéréo. Importée en Quite OK Audio, la compression par défaut des WAV de Godot : 21,8 Mo → 4,4 Mo. Sa boucle
  est réglée à l'import (`edit/loop_mode=2` dans le `.import` : « Forward »). Le test vérifie, sur le flux chargé, que
  `loop_mode` vaut `AudioStreamWAV.LOOP_FORWARD`.

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer ce que coûte un son

Le combat ne crée aucun objet (étape 14). Avant d'écrire la moindre ligne, on a compté ce que crée la lecture d'un son
(compteur d'allocations de l'ObjectDB) :
- `AudioStreamPlayer3D.play()` : 40 objets pour 20 sons ;
- `AudioStreamPlaybackPolyphonic.play_stream()` : 16 objets pour 20 appels, avec 8 voix au plus (les appels refusés
  faute de voix ne créent rien).

Le moteur crée donc la lecture de chaque son (`AudioStream.instantiate_playback`) : deux objets par son, quelle que
soit la voie. On ne peut pas l'éviter : on le compte. Notre code, lui, ne crée rien en combat.

### 2. Deux bus

`5_data/audio/bus_layout.tres`, déclaré dans `project.godot` (`[audio] buses/default_bus_layout`) :
- `Music` ;
- `SFX`, les bruitages, avec une réverbération légère (la salle du saloon : `room_size` 0,5, `wet` 0,15).

### 3. La table des sons

`SoundBoard` prépare 16 voix (`AudioStreamPlayer3D`) au démarrage, sur le bus `SFX`. `play(cue, at)` joue un son à sa
place, sur la voix suivante. Quand toutes ont servi, la plus ancienne reprend. Un `SoundCue` (données) a plusieurs
variantes, un volume, une hauteur tirée entre deux bornes et une portée. Le tirage suit une graine : une partie
rejouée sonne pareil.

### 4. Les sons du combat

`CombatSounds` (`2_sequence/`) écoute les signaux qui existaient déjà et fait jouer le son de chaque événement :
- héros : tir, roulade, saut, retour au sol, touché, fiole, abattu ; un pas par foulée de 1,6 m au sol ;
- tirs : un tir qui touche passe d'abord par la zone touchée (`Hurtbox.received`), puis le projectile dit son impact
  (`ProjectilePool.impacted`). La zone choisit donc le son (corps du Gardien, point faible, bouclier, spectre) et
  l'impact donne sa place. Sans zone touchée juste avant, le tir a fini dans le décor ;
- Gardien : réveil, marteau qui touche, sol écrasé, seconde phase, chute ; un pas lourd par foulée de 2,6 m ;
- spectres : l'annonce d'une plongée, la dissipation.

Les entités ne savent rien du son : aucun de leurs fichiers ne change.

### 5. La musique

`MusicPlayer` entre en fondu au réveil du Gardien (2,5 s) et sort en fondu à la fin du combat, la chute du Gardien ou
celle du héros (4 s), puis s'arrête. Le fondu se fait dans `update`, sans Tween.

### 6. Les tests et la mesure

- La table : voix prêtes sur `SFX` ; un son joue à sa place, avec une de ses variantes, son volume, une hauteur dans
  ses bornes et sa portée ; la plus ancienne voix reprend ; un son vide ne joue rien ; même graine, mêmes tirages ;
  chaque son du combat a ses variantes.
- La musique boucle ; elle entre et sort en fondu, puis s'arrête ; les deux bus existent, `SFX` avec sa réverbération.
- Chaque événement du héros, du Gardien et des spectres a son son ; un tir prend le son de ce qu'il touche ; la
  musique suit le Gardien ; 5 m de course font 3 pas.
- Un son ne crée que sa lecture dans le moteur : exactement 40 objets pour 20 sons.

Avec les cas des étapes précédentes : 240 cas verts. La mesure du combat sans fenêtre compte maintenant les sons :
63 sons, 126 allocations, toutes celles du moteur (2 par son), 0 pour notre code. 0,57 ms par image en médiane, contre
0,50 avant les sons ; deux mesures concordantes. L'outil libère la scène et laisse au serveur audio le temps de
relâcher les sons avant de quitter : sinon des sons encore en cours fuient à la sortie.
