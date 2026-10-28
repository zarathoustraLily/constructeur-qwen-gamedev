# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Après six étapes de logique en maquette grise, laurent a jugé le résultat : une capsule qui tire
sur un cube rouge n'est pas un boss de Dark Souls. Il a donné la référence (Dark Souls 1, tous les boss) : décor sombre
et texturé, brouillard, lumière de torches, boss immenses. **Leçon de méthode : montrer tôt le rendu visé.** Une
logique juste dans un décor gris ne se juge pas comme un jeu ; le décor et le boss passent donc maintenant, avant le
combat.

Ce qu'on obtient : le héros entre dans le saloon d'un géant (le décor Quixel, agrandi quatre fois : 40 × 34 m, balcon
à 12 m, des chaises plus hautes que lui), la nuit : fenêtres bleues de lune, lampes chaudes, brouillard léger, brume au
ras du sol. Devant le comptoir l'attend le Gardien, un golem de pierre en armure de 7,3 m, marteau et bouclier, qui
respire (animation d'attente). On peut le verrouiller et lui tirer dessus ; il ne se défend pas encore.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le premier import des textures prend un moment).
2. F5 : le héros apparaît à l'entrée, face au golem. Tirer, verrouiller (clic du stick droit), rouler dans la brume.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

Les outils cités sont dans le dossier du jeu de laurent, `SUIVIS_PROGRESSION/outils/`, hors du projet Godot : ils
fabriquent `6_assets/`, ils ne sont pas le jeu. Tous se relancent d'un coup par `refaire_arene.py`.

### 1. Savoir ce que contiennent vraiment les sources

Le zip du saloon n'avait que des pièces détachées (un dossier par identifiant Quixel, sans nom lisible ni position).
L'inventaire du paquet Unity, lui, listait une scène (`.unity`) et 98 préfabriqués : **la disposition complète du
saloon existait là**. Un `.unitypackage` est une archive tar.gz : un dossier par GUID (`asset`, `asset.meta`,
`pathname`). On le lit en flux et on n'extrait que ce qui sert (le disque n'avait plus que 28 Go), sans jamais rien
exécuter.

### 2. Lire une scène Unity

C'est du YAML, un document par objet : `PrefabInstance` (le préfabriqué posé, son parent, ses modifications de
position, rotation, échelle), `Transform`, lumières ; dans un préfabriqué : `MeshFilter` (quel maillage du FBX),
`MeshRenderer` (quels matériaux), `MeshCollider`, `LODGroup` (on ne garde que le niveau le plus détaillé). Le nom d'un
maillage se lit dans le `.meta` du FBX. On compose les transformations de parent en enfant.

**Le repère change.** Unity est en main gauche (avant = +Z) et retourne X en important un FBX ; Godot est en main
droite (avant = -Z). Un maillage se pose donc par Mz · T · Mx (deux miroirs : une vraie rotation), une lumière par
Mz · T · Mz. Vérifié sur l'image du premier coup : balcon, rambardes, tables cohérents.

**Piège** : des `MeshCollider` écrits par Quixel sont du YAML mal indenté, que Unity tolère et qu'un lecteur YAML
strict refuse ; une lecture de secours ligne par ligne les lit.

### 3. Comprendre les matériaux par le code qui les utilise

46 matériaux sur 50 n'avaient aucune texture sous les noms habituels : ils passaient par les graphes de shader de
Quixel. On a lu le graphe (`S_MS_Default_Material`) : couleur = Albedo × teinte × luminosité, puis saturation et
contraste ; rugosité = mélange de deux bornes selon le canal rouge de la texture `DR` ; métal ; normale. **Quand une
donnée ne se comprend pas par son nom, on lit le code qui s'en sert.** Godot attend un matériau ORM (rouge occlusion,
vert rugosité, bleu métal) : les textures sont recomposées, réduites (2048 pixels pour l'architecture, 1024 pour les
petits objets), et chaque matériau devient un `ORMMaterial3D`.

### 4. Construire la scène dans Godot, par un script

Un script lancé par Godot sans fenêtre (`--headless -s`) range chaque maillage en ressource, pose les maillages,
fusionne **toutes les collisions en une seule forme statique** (`ConcavePolygonShape3D` : un seul corps, une seule
hiérarchie de volumes pour la physique) et crée les lumières. Résultat : `6_assets/Environment/Saloon/saloon.tscn`,
qui ne contient aucun code (la règle des dossiers : `6_assets/` n'a que des ressources).

### 5. Juger sur l'image

Un script de capture rend la scène vue d'une caméra (fenêtre hors de l'écran), et des plans vus de dessus. Ce que
les images ont appris, et que les nombres ne disaient pas :
- la scène Unity contenait **deux saloons** : on garde celui à balcon et escalier (la hauteur rend le combat
  dramatique) ;
- **un mur manquait** (la démo Unity était filmée de ce côté) : on le ferme en recopiant en miroir le mur opposé.
  Deux essais ratés : des moulures du balcon, puis des plaques de mur posées à plat (Quixel en fait le plafond sous
  le balcon), flottaient devant le mur. Règle finale : ne recopier que les modules debout ;
- les cartes d'émission du golem sont des **masques** : allumées, elles blanchissaient toute l'armure. Éteintes au
  départ, couleur de braise prête pour la seconde phase.

### 6. L'échelle qui rend le combat dramatique

Le golem mesure 1,82 m dans son fichier. Tout est agrandi quatre fois, saloon et golem : le golem est à l'échelle du
mobilier, **le héros (1,8 m) est l'intrus minuscule** ; le comptoir devient un mur, les tables des abris. Un seul
paramètre du constructeur, gardé dans `refaire_arene.py`.

### 7. Le golem

Son squelette (91 os, de type Unreal) a des os prévus pour les armes : le marteau va sur `weapon_r`, le bouclier sur
`weapon_l` (`BoneAttachment3D`). Ses 25 animations (une par FBX, toutes nommées « Take 001 ») deviennent une
bibliothèque où chacune porte le nom de son fichier (`attack1`, `idle1`, `walkF`…), sans les pistes du gréement
HumanIK, en boucle pour l'attente, la marche et la course. La marche se fait sur place : c'est le code qui le
déplacera.

Dans le jeu, `3_entities/boss/golem.tscn` assemble : un `CharacterBody3D` sur la couche du boss (capsule de 7 m), le
modèle (×4, tourné pour que son avant soit le -Z de Godot), sa santé (1 500 points), la zone qui reçoit les tirs, et
un **point de verrouillage à hauteur de poitrine** (verrouiller ses pieds ferait regarder le sol).

### 8. L'ambiance

Réglée sur les images d'un aperçu, puis écrite en ressources par Godot lui-même (aucune énumération écrite à la
main) : `5_data/environment/arena_environment.tres` (fond froid, lumière ambiante bleutée et faible, illumination
globale SDFGI, occlusion ambiante, halo, brouillard volumétrique léger, tonalité AgX, saturation baissée) ;
une lune froide qui fait des ombres et éclaire le brouillard ; les lampes du saloon en couleur de flamme ; et la
**brume au sol** (`5_data/environment/ground_mist.tres`) : un `FogVolume` de 3 m de haut sur toute la salle, dont la
densité retombe avec la hauteur (`height_falloff`) et qu'une texture de bruit 3D effiloche.

### 9. Ce qui change dans la scène principale

Le sol plat, le soleil, le ciel et le cube rouge disparaissent ; le saloon, l'environnement, la lune, la brume et le
golem arrivent. Le héros apparaît à l'entrée, tourné vers le golem ; la caméra part derrière lui, dans la direction
où il regarde (elle prend son lacet au départ).

### 10. Les tests

- La scène : la collision du saloon est une forme concave ; le héros, lâché à l'entrée, se pose sur le plancher ; la
  lune fait des ombres, le brouillard est allumé, la brume touche le sol ; le golem se verrouille, reçoit les tirs,
  et tirer sur lui lui retire de la vie.
- Le golem : sa couche, sa taille (entre 6,5 et 8 m), ses tirs reçus qui vont à sa santé, son point de verrouillage
  à hauteur de poitrine, son modèle qui joue l'attente.
- La caméra : au départ, elle regarde où regarde le héros.
