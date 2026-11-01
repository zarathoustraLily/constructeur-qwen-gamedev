# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent : « il faut que le niveau puisse etre joue sur un petit pc ». Jusqu'ici, toutes les mesures venaient
d'une RTX 5090 : elles disaient le sens d'un changement, pas ce que tiendrait un petit PC. Cette étape mesure sur une vraie petite
carte, et donne le banc à lancer sur le PC de laurent. Aucun fichier du jeu ne change : seuls l'outil de mesure et le banc.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Regarder d'abord ce qu'on a sous la main

Le processeur de la machine, un Core Ultra 7 265K, a une carte intégrée : « Intel(R) Graphics » (`Win32_VideoController`). Elle n'a
pas d'écran branché, mais Vulkan la voit. `--gpu-index 1` y fait tourner Godot, fenêtre hors de l'écran :

```
Vulkan 1.4.348 - Forward+ - Using Device #1: Intel - Intel(R) Graphics
```

Sans `--qualite`, le jeu y a choisi tout seul la qualité basse : la règle de l'étape 15 (`RenderingServer.get_video_adapter_type`)
marche sur une vraie carte intégrée, plus seulement dans un test.

### 2. Mesurer le temps de chaque image

Le temps de la carte ne suffit plus. Une image peut être lente pour une autre raison : un shader compilé à son premier emploi, le
processeur, la mémoire. `mesurer_rendu.gd` donne maintenant la carte utilisée, le temps de chaque image (médiane, 99e centile, pire
image), le nombre d'images de plus de 16,7 ms, le temps de chargement et la mémoire. Sans V-Sync (`--disable-vsync`) : sinon, on
mesure l'écran. `images=900` et `echauffement=5` couvrent tout depuis le début, premiers sorts compris.

## Les résultats, sur la carte Intel

Qualité basse, Forward+, sans V-Sync :

| Scène | Taille | Médiane | 99e centile | Pire | Images > 16,7 ms |
| --- | --- | --- | --- | --- | --- |
| Au repos | 1280 × 720 | 4,67 ms | 5,5 ms | 5,9 ms | 0 sur 120 |
| En tirant | 1280 × 720 | 4,54 ms | 5,8 ms | 5,9 ms | 0 sur 120 |
| Sorts au plus fort | 1280 × 720 | 4,95 ms | 6,2 ms | 6,5 ms | 0 sur 120 |
| Sorts, 15 s depuis le début | 1280 × 720 | 4,69 ms | 6,7 ms | 7,6 ms | 0 sur 900 |
| Sorts au plus fort | 1920 × 1080 | 9,80 ms | 12,4 ms | 12,6 ms | 0 sur 120 |

Soit 200 images par seconde en 1280 × 720 et 100 en 1920 × 1080, sur une carte qui a besoin de 24 ms pour la qualité haute (41 images
par seconde : c'est pour ça que la qualité basse existe).

Ce que l'étape 21 a rapporté, enfin sur une carte qui en a besoin : 6,16 → 4,67 ms par image au repos.

- **Une image de 84 ms** est apparue une fois en 900 images. On s'est méfié d'un shader compilé en plein combat : on a relancé sur
  un dossier de données neuf, sans aucun cache de shaders. Deux fois de suite : 0 image lente, 7,6 ms et 7,0 ms au pire. Cette image
  ne s'est pas reproduite. Elle n'est pas expliquée : une mesure sur une machine qui fait autre chose en même temps.
- **Le premier lancement** : 2,6 s de chargement, autant que les suivants. 9 Mo de cache de shaders.
- **La mémoire** : 1,15 Go pour le processus au plus haut, 419 Mo de mémoire vidéo.
- **Deux petits cœurs** : le processus réduit à deux cœurs lents du processeur (`ProcessorAffinity`, vérifié pendant la mesure), carte
  Intel, sorts au plus fort : 4,81 ms en médiane, 7,2 ms au pire, 0 image lente sur 480. Ce processeur reste rapide : ses petits cœurs
  ne sont pas ceux d'un vieux PC.

## Ce que ces chiffres ne disent pas

Cette carte n'est pas le petit PC de laurent, dont on ne sait rien :
- c'est une carte récente de 2024, sur un processeur rapide, avec une mémoire rapide ;
- une vieille carte intégrée ou une petite carte dédiée peut être plusieurs fois plus lente ;
- la marge est là : 4,7 ms sur un budget de 16,7 ms, soit une carte 3,5 fois plus lente en 1280 × 720.

Le test qui fait foi reste ce PC-là. `7_tests/perf/banc_petit_pc.bat` le prépare : trois mesures de 10 secondes, avec la qualité que
le jeu choisit tout seul, et un fichier texte à renvoyer. On n'ajoute pas de réglage automatique de plus : aucun besoin n'est
démontré (principe 5 du plan).

## Les tests

Aucun fichier du jeu ne change : 270 cas verts, comme à l'étape 21.
