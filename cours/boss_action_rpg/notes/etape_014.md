# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La conception demande un jeu « extrêmement optimisé » : 60 images par seconde en 1920 × 1080 sur
la 5090, et aucune allocation en combat. Cette étape fait la partie qui se mesure sans fenêtre, sans occuper la carte
graphique. La mesure en 1080p viendra quand la carte sera libre.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer d'abord

`7_tests/perf/mesurer_combat.gd` joue le combat sans joueur et sans fenêtre :
- le héros, invulnérable, vise le golem et tire sans cesse ;
- le golem l'attaque ; sa vie est remontée pour que le combat dure ;
- la seconde phase commence en pleine fenêtre de mesure.

Après l'échauffement, sur 600 images, il relève :
- **les allocations**, par le compteur de l'ObjectDB. Un objet témoin est créé puis libéré, et les bits hauts de son
  identifiant donnent ce compteur. Le nombre d'objets vivants (`OBJECT_COUNT`) ne voit pas un objet créé puis libéré
  dans la même image ;
- **le temps** de chaque image (`Time.get_ticks_usec`), en médiane et au plus haut ;
- **ce qui se dessine**, compté dans l'arbre : instances visibles, surfaces, couches par-dessus, émetteurs de
  particules, lumières qui font des ombres. En headless, le moteur ne dessine rien.

```
godot --headless --fixed-fps 60 --path . -s res://7_tests/perf/mesurer_combat.gd -- 300 600
```

### 2. Ce que la mesure a trouvé

**600 allocations en 600 images**, exactement une par image. Pour trouver la source, on a coupé les suspects un à un :
- sans tir : 0 ;
- en visant sans tirer : 0 ;
- c'est donc le tir.

Tant que la détente est tenue, l'état de course appelle `hero.aim_point()` à chaque image, et `Aim.point` créait sa
requête de rayon par `PhysicsRayQueryParameters3D.create`, qui rend une requête neuve.

Les corrections :
- `Aim` garde une requête créée une fois (`static var`), dont il change `from`, `to` et `collision_mask` ;
- `Golem.path_clear` garde la sienne de même ;
- les deux `Tween` du combat (l'éclat de la braise, la chute du bouclier) créaient des objets au passage à la seconde
  phase. Ce sont maintenant des interpolations faites à la main, image par image.

Nouvelle mesure, seconde phase comprise : **0 allocation** ; 0,47 ms par image en médiane, environ 1 ms au plus haut,
côté processeur.

### 3. Ce qui reste à mesurer sur la carte graphique

La scène dessine 468 instances visibles, 520 surfaces, 12 couches par-dessus et 7 émetteurs de particules. Elle a
**15 lumières qui font des ombres** : c'est sans doute le premier coût sur la carte graphique, mais on ne change pas la
lumière sans l'avoir mesurée en 1080p.

### 4. Les tests

`7_tests/perf/test_sans_allocation.gd` répète chaque travail cent fois, **sans attendre d'image** : un `await` crée
lui-même un objet. Il vérifie que rien n'est alloué par :
- le rayon de visée ;
- le chemin du golem ;
- ses effets (onde, éclats, traînée) ;
- le passage à la seconde phase, bouclier qui tombe compris.

Il a été lancé sur l'étape 13, avant la correction : rouge sur trois cas sur quatre. Il est vert ici. Avec les cas des
étapes précédentes : 213 cas verts.
