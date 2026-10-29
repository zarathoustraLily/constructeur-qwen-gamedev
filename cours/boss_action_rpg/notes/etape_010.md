# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent voulait « de la carboglace, ou de la brume au niveau du sol ». L'étape 7 avait posé un
`FogVolume` de 3 m de haut avec un `FogMaterial` : en jeu, c'était un voile uniforme qui noyait les jambes du golem,
sans rien qui coule au sol (« où est la fumée au sol ? »). De la carboglace, c'est une nappe dense et basse, en
volutes qui bougent lentement. On la refait avec un **shader de brouillard**.

Ce qu'on obtient : une nappe de moins d'un mètre, posée sur le plancher, qui couvre le pied des tables et du golem,
s'éclaire près de la porte et sous les lampes, et dérive lentement ; le héros (1,8 m) en sort jusqu'aux genoux.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier. **Le rendu Forward+** est nécessaire : le moteur Compatibilité ne dessine pas
   le brouillard volumétrique (« shader type fog not supported in OpenGL renderer »).
2. F5 : regarder la nappe autour du golem et près de la porte ; elle bouge lentement.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Ce que peut un shader de brouillard

La documentation (`search_docs` : « fog shader built-ins ») donne ce qu'un `shader_type fog` lit et écrit. En entrée :
`WORLD_POSITION` (la position de la cellule de brouillard, dans le monde), `OBJECT_POSITION` et `SIZE` (le centre et la
taille du `FogVolume`), `UVW` (la place dans le volume, de 0 à 1), `TIME`. En sortie : `DENSITY` (sans elle, rien
n'est écrit), `ALBEDO` (la couleur qui prend la lumière), `EMISSION` (une lueur propre).

### 2. Le shader (`6_assets/Shader/Environment/ground_mist.gdshader`)

Trois facteurs multipliés :
- **la hauteur** : depuis le bas du volume (`OBJECT_POSITION.y - SIZE.y / 2`), la densité tombe de 1 à 0 sur
  `layer_height` (0,9 m), en carré (dense au ras du sol, puis vite rien) ;
- **les volutes** : un bruit 3D sans couture (`NoiseTexture3D`), lu à la position du monde moins `drift × TIME` : le
  motif glisse à 0,35 m/s ; `smoothstep` entre deux seuils sépare les creux et les volutes, et un plancher (`hollow`)
  empêche la nappe de se trouer tout à fait ;
- **les bords** : la distance aux bords du volume (par `UVW` et `SIZE`) l'efface sur 2 m, pour ne jamais montrer un
  mur de brume.

Les réglages et le bruit sont dans `5_data/environment/dry_ice_mist.tres` (un `ShaderMaterial`), jamais dans le code
du shader. Le volume (44 × 1,8 × 38 m) est posé sur le plancher et couvre la salle.

### 3. Ce que l'image a appris

Premier rendu : **rien ne se voyait**. Le shader compilait (aucune erreur au rendu). Pour trouver la cause, on a
simplifié une copie du projet : la densité seule selon la hauteur, sans bruit ni bords. C'était presque pareil : ni
le bruit ni les bords n'étaient en cause, mais **l'épaisseur** : une nappe de 0,9 m traverse trois fois moins de
brouillard que l'ancien voile de 3 m, et un brouillard qui ne fait que renvoyer la lumière se voit à peine dans une
salle sombre. Densité portée de 1,6 à 8, et une lueur propre légère (`glow`, sortie `EMISSION`) : la nappe se lit
partout, même hors des lampes. Règle : **réduire un effet à ses facteurs, un à un, pour trouver celui qui manque**.

Une faute écrite puis corrigée avant tout rendu : `float nappe: float = …`, une syntaxe de GDScript, n'est pas du
langage de shader (`float nappe = …`). Un shader ne compile qu'au rendu : une image après chaque changement.

### 4. Les tests

La scène principale : la brume est faite par ce shader ; son volume est posé sur le plancher ; la nappe est plus basse
que le héros et tient dans le volume ; le bruit et la dérive sont là. La brume elle-même ne se juge que sur l'image
(une capture en Forward+ après chaque changement). Avec les cas des étapes précédentes : 162 cas verts.
