# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le prompt demande « un niveau de boss professionnel, au code propre et extrêmement optimisé ».
Avant d'écrire une ligne de gameplay, on construit un projet qui tient debout : une organisation des dossiers qu'on ne
remettra pas en cause, des réglages qui refusent le code approximatif, des actions nommées pour le clavier, la souris et
la manette, et un ordre d'exécution écrit. Tout ce qui suit s'appuie dessus ; le refaire plus tard coûterait cher.

Ce qu'on obtient : un projet qui se lance (F5 : un sol, une lumière, un ciel), dont les tests passent, et qui sait
déjà quelles actions existent et dans quel ordre ses nœuds tourneront.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : le sol gris sous le ciel ; rien ne bouge encore.
3. Les tests : `7_tests/lancer_tests.bat` (adapter le chemin de Godot), ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Lire le prompt et en tirer une liste d'exigences

Un prompt court cache des exigences précises. On écrit chaque mot qui compte et ce qu'il exige concrètement, avant de
toucher au projet (`SUIVIS_PROGRESSION/conception.md` du projet final) :
- « boss action RPG » : des attaques annoncées et punissables, une roulade, de l'endurance, des phases ;
- « professionnel » : des contrôles réactifs à la manette comme au clavier, une caméra qui ne traverse rien ;
- « code propre » : la nomenclature du plan (un dossier par rôle), des petits scripts, des tests ;
- « extrêmement optimisé » : un budget mesuré (60 images par seconde), pas d'allocation pendant le combat.
Cette liste devient `plan.md`, une case par étape, cochée seulement quand l'étape est testée et vue en jeu.

### 2. Empêcher Godot d'importer les sources brutes

Le dossier du projet contient aussi les archives d'origine (`source/`) et leurs fichiers extraits
(`source_extraites/`) : des gigaoctets de modèles et de textures. Godot importe tout ce qu'il trouve sous la racine du
projet, et l'import prendrait des heures. Un fichier vide nommé `.gdignore` dans un dossier le fait ignorer par Godot :
on en pose un dans `source/`, `source_extraites/` et `SUIVIS_PROGRESSION/`. On ne copie dans `6_assets/` que ce qui
sert vraiment, au moment où on s'en sert.

### 3. Des avertissements qui sont des erreurs

Dans `project.godot`, section `[debug]`, chaque avertissement de GDScript passe au niveau 2 (erreur) : une variable
sans type (`untyped_declaration`), une division entière silencieuse (`integer_division`), un paramètre inutilisé
(`unused_parameter`), un nom qui en masque un autre (`shadowed_variable`)… Un script qui en contient un ne se charge
plus. C'est voulu : ces avertissements sont presque toujours des bugs en attente, et le prompt demande du code propre.

### 4. Des actions nommées, pour chaque appareil

Le code ne parlera jamais d'une touche ou d'un bouton, seulement d'**actions**, déclarées dans `project.godot`
(section `[input]`, ou Projet > Paramètres du projet > Contrôles). Chacune a une touche (par sa **position** :
`physical_keycode`, pour que W A S D restent au même endroit sur un clavier AZERTY) ou un bouton de souris, **et** une
entrée de manette :
- se déplacer : W A S D, stick gauche (axes 0 et 1) ;
- caméra : stick droit (axes 2 et 3) ; la souris sera lue à part, en mouvement relatif ;
- viser et tirer : clic droit et gauche, gâchettes gauche et droite (axes 4 et 5) ;
- rouler : Espace, B ; verrouiller : clic de la molette, clic du stick droit ; soin : E, X ; pause : Échap, Menu ;
- `ui_accept` et `ui_cancel` reçoivent aussi A et B : par défaut, Godot ne leur donne que des touches.
`1_core/input/actions.gd` donne un nom de constante à chaque action (une faute de frappe dans une chaîne passerait
inaperçue ; une constante mal écrite ne compile pas) et sait dire si une action a une entrée de manette et une entrée
de clavier ou de souris : c'est ce que vérifie le test.

### 5. Des couches de collision nommées

Section `[layer_names]` : monde, héros, boss, projectiles, coups du boss. Chaque corps dira sur quelle couche il est et
lesquelles il regarde ; nommer les couches dès le départ évite de les confondre plus tard. La physique tourne à 60
pas par seconde (`physics_ticks_per_second`) : les durées en images que les tests mesureront en dépendent.

### 6. L'ordre d'exécution, écrit

Quand le héros lit la manette, que le boss décide, que les projectiles volent et que la caméra suit, l'ordre compte :
une caméra qui passe avant le héros a une image de retard. `1_core/process_order.gd` nomme les priorités (entrées,
composants, acteurs, projectiles, vues, caméra) ; chaque nœud prendra la sienne au lieu d'écrire un nombre sur place.

### 7. Une scène qui se lance, et les tests d'abord

`2_sequence/main.tscn` : un sol (un `StaticBody3D` avec sa forme de collision, posée sous la surface), un soleil
(`DirectionalLight3D` avec ombres), un ciel (`WorldEnvironment`), une caméra. Les tests de l'étape, écrits avant de
remplir les scripts :
- chaque action du combat a une entrée de manette et une entrée de clavier ou de souris ;
- les couches portent leur nom ; la physique tourne à 60 pas par seconde ;
- l'ordre d'exécution va strictement croissant ;
- la scène principale se charge, avec son sol, sa lumière et sa caméra active ;
- chaque script du jeu est documenté (`test_documentation.gd`).

On les lance (`lancer_tests.bat`) et on lit chaque ligne de la sortie : un code de sortie 0 ne suffit pas, une ligne
« ERROR » du jeu ne fait pas échouer GdUnit4 mais doit être corrigée.
