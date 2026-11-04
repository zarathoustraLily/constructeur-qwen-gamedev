# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les pièces existent : Bobine, le Terrier, l'Établi, le Gardien. Il manque ce qui en fait une boucle : une porte qui s'ouvre, une première salle, et un jeu qui passe de l'une à l'autre en gardant l'arme. La salle, ses
réglages et le retour au Terrier après une chute sont mes choix, à faire valider.

## Les fichiers du projet

{FILES_TABLE}

## Un jeu au-dessus des salles

Jusqu'ici, `main.tscn` était le jeu. Pour passer d'une salle à l'autre en gardant une arme, il fallait quelque chose qui survive au changement. Deux réponses sont possibles :

- un autoload ou une variable statique : c'est court, mais l'état traverse les tests, et il faut penser à le remettre à zéro ;
- une scène `game.tscn` qui tient une salle à la fois comme enfant : l'état vit dans un nœud, et disparaît avec lui.

La seconde a un effet heureux. `main.gd` faisait déjà `reload_current_scene` à la chute. La scène courante étant maintenant `game.tscn`, ce même appel ramène tout le jeu au Terrier, sans arme. **La boucle n'a pas demandé une ligne de plus dans le combat**, et `main.tscn` lancée seule se comporte comme avant.

`Game` ne sait presque rien d'une salle : son nœud `Hero`, et le signal `left` si c'est une `Level`. Le seuil (`Threshold`) le dit à sa salle, qui le répète : un seuil n'a pas besoin de connaître le jeu.

`Level` trouve ses seuils avec `find_children`, une seule fois, au chargement. Une salle de plus n'a rien à brancher.

## Le noir qui retombe

Le passage est fait de deux fondus autour du changement de salle. Le risque connu d'un voile d'écran est qu'il reste allumé, ou qu'il attrape les clics : d'où `mouse_filter = 2` sur le `ColorRect`, et un test qui lit l'opacité à zéro après chaque arrivée.

`changing` refuse un second seuil pendant un passage. Sans lui, deux `go_to` se croiseraient, et chacun libérerait la salle de l'autre.

## La manette après un changement de salle

Un héros neuf arrive à chaque salle, avec son `HeroInput` : il n'y a rien à réassigner. Comme un défaut de ce type se cache facilement, `test_sa_manette_repond_apres_un_changement_de_salle` envoie un vrai évènement de stick et mesure le déplacement.

## La plinthe

`PlinthDoor` se lève quand Bobine a une arme. Fermée, elle garde une `Interactable` : son bouton ne fait rien, mais l'invite dit pourquoi elle ne cède pas. Le joueur apprend la règle en cognant à la porte.

Sa collision se coupe avec `set_deferred` : `open_door` part d'un signal émis pendant la physique, et une forme ne se change pas à ce moment-là.

Le tunnel est soustrait **avant** le plancher dans le `CSGCombiner3D`. L'ordre des enfants fait partie de la scène, comme à l'étape 27.

## Sous le Comptoir

Une salle sans combat, pour marcher, sauter et regarder. Les bouteilles du géant font des colonnes. Une planche de 80 cm barre le passage, et Bobine saute à 1 m : c'est un obstacle qui enseigne le saut, et `test_la_planche_l_arrete_a_pied_et_se_passe_en_sautant` vérifie les deux moitiés de cette phrase.

Une lumière chaude au fond dit où aller, sans flèche.

## Jouer toute la boucle

Les tests vérifient chaque passage. Reste à savoir si un joueur peut tout enchaîner. `outils/scenarios/parcours_boucle.gd` joue du lit au Gardien avec de vrais évènements, à la manette puis au clavier, sans fenêtre.

| | Manette | Clavier |
| --- | --- | --- |
| Arme prise, plinthe levée | 4,9 s | 5,0 s |
| Sous le Comptoir | 8,2 s | 8,3 s |
| Gardien atteint, arme gardée | 15,0 s | 15,2 s |
| Retour au Terrier après la chute, sans arme | 18,0 s | 18,2 s |

Ce sont des temps de scénario : le trajet est le plus court possible, sans regarder autour.

## Ce que l'image a corrigé

- **La plinthe fermée ressemblait à une tache sur le mur** : deux barres de fer la font lire comme une porte. En fer-blanc, elles brillaient comme des fentes de lumière : il a fallu un fer sombre.
- **Bobine devenait une silhouette noire** vers le fond de la salle : une lampe au milieu.

## Les erreurs de cette étape

- **`follow_muzzle` sur un squelette sorti de l'arbre** : le squelette finit sa pose alors que la salle part. Le jeu n'en souffrait pas, mais le journal avait deux erreurs à chaque retour. Elles ne se voyaient qu'en lisant la sortie du scénario, et c'est pour cela qu'on lit chaque ligne.
- **`bind` ajoute ses arguments après ceux de l'appel** : `_button.bind(JOY_BUTTON_Y)` appelé avec `true` passe `true` en premier. Dans le scénario, l'arme n'était jamais prise, et ce défaut ne venait pas du jeu.
- **Une route qui survit à sa salle** : le scénario continuait de marcher vers un point de l'ancienne salle, contre un mur.
- **Compter ce qui revient** : la réserve était pleine 20 images après le tir. Il faut compter le signal `fired`.
- `position.y` est en float32 : comparer avec une tolérance, encore.

## À retenir

- L'état qui doit survivre vit dans un nœud au-dessus de ce qui change. Il disparaît alors avec lui.
- Un rechargement déjà écrit peut devenir la boucle du jeu : regarder ce que fait le code existant avant d'en ajouter.
- Une porte fermée doit dire pourquoi.
- Après les tests d'un passage, jouer le parcours entier avec de vrais évènements.
