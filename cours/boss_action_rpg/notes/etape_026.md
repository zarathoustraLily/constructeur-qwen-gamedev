# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le 2026-11-01, j'ai proposé à laurent de construire un hub, une salle d'armes, une porte et une première salle avec une
héroïne et des données originales ; laurent a répondu « Oui, fais-le ». Les quatre étapes qui viennent font ce travail. Celle-ci pose l'héroïne : tout le
reste a besoin d'elle à l'écran. Son nom, son histoire et son allure sont mes choix, à faire valider.

## Les fichiers du projet

{FILES_TABLE}

## Pourquoi une poupée de bois

Il faut un personnage original, sans modèle téléchargé : chaque téléchargement demande l'accord de laurent, et aucune archive de `source/` n'a d'héroïne libre. Il
reste à la fabriquer par le code. Un corps humain procédural a un défaut connu : ses articulations se plient mal, et il se voit tout de suite.

Le monde donne la réponse. Le héros est minuscule dans le saloon d'un géant : une poupée de bois y a sa place, et **ses articulations sont des rotules**. Des pièces rigides
qui tournent les unes contre les autres ne sont plus un manque, c'est le personnage. D'où Bobine : une bobine de fil pour buste, un dé à coudre pour casque, une tresse de laine,
des bas rayés, des sabots, une cape rapiécée.

Quand une contrainte technique pèse, on cherche le personnage ou le décor qui en fait une qualité, avant d'y mettre des heures de technique.

## Garder le squelette, changer le corps

`HeroView` lit quatre noms : `%GeneralSkeleton`, `AnimationPlayer`, `%Muzzle` et `%LeftHandIK`. Il ne sait rien du soldat. Une nouvelle scène avec ces quatre nœuds, et le même
squelette, reçoit donc les 13 clips, l'arbre d'animation, la visée et l'IK de la main gauche sans une ligne de plus. `construire_bobine.py` écrit cette scène à partir de celle du
soldat, sans ses maillages. Le prix d'une vue qui ne décide rien s'est payé à l'étape 8 ; il rapporte ici.

## Le maillage

`PuppetBuilder` hérite de `MeshBuilder`, sans le changer. Ce sont les deux méthodes qu'il remplace qui font son travail :

- `add_vertex` note l'os posé (`bone`) : `ellipsoid` et `tube` passent par là, ils savent donc suivre un os sans modification ;
- `to_mesh` ajoute `ARRAY_BONES` et `ARRAY_WEIGHTS`, quatre valeurs par sommet.

`Skeleton3D.create_skin_from_rest_transforms` donne la peau : un bind par os, à la pose de repos. Chaque pièce se place avec `get_bone_global_rest`, et aucune mesure du squelette
n'est répétée dans le code.

**Les coordonnées de texture viennent du modèle.** Le triplanaire de `StandardMaterial3D` lit la position après le squelette : la texture aurait glissé sur le bois à chaque geste. `add_vertex` projette
donc chaque sommet dans le repère de sa pièce (`grain`), et le fil du bois suit le membre.

**Un seul lot de dessin.** La couleur du sommet donne le ton, son alpha la matière (1 le bois, 0,5 le tissu, 0 le métal). `bobine.gdshader` en tire veinage, rugosité et métal.
Le shader dessine les faces arrière : la jupe et la cape n'ont qu'une épaisseur.

Mesures : 3 666 sommets, une surface, bâtie en 4,7 ms au chargement. Le combat reste à 0 allocation de notre code.

Les formes d'armes vivent dans `1_core/procedural/weapon_shapes.gd`, à part de Bobine : l'Établi s'en servira sans dépendre du héros.

## Ce que l'image a corrigé

La première planche passait les tests, et quatre défauts se voyaient :

- **Le dé à coudre ressemblait à un bol** : deux fois trop large pour sa hauteur. Il est plus haut, et ses anneaux alternent les tons.
- **Le métal était noir** : un métal entier reflète la pièce, et elle est sombre. `METALLIC` s'arrête à 0,55.
- **Une cuisse perçait la jupe** : `share` partage l'ourlet entre les hanches et les cuisses (75 % au bas de la jupe). Un sommet porte alors trois os, et ses poids font toujours 1.
- **Le bois tirait au gris** : le veinage ne donne plus que la luminosité, et le ton est plus chaud.

## Les erreurs de cette étape

- **Un test trop large** : j'exigeais un os pour chaque piste des clips. Le fichier d'animation garde des os d'IK (`ik_foot_l`) que le squelette du soldat n'a pas non plus. Le test vérifie maintenant les grands os du clip `run`.
- `if @warning_ignore(...) (i / 7) % 2` n'est pas du GDScript. Une boucle sur les anneaux impairs dit la même chose sans division.
- `test_documentation` exige un commentaire `##` sur chaque constante publique, jusqu'aux couleurs.

## À retenir

- Une vue qui lit des noms de nœuds, et rien d'autre, accepte un autre modèle sans changer.
- Un sommet procédural peut porter ses coordonnées de texture : c'est ce qui les empêche de glisser.
- Les tests disent que le corps tient ; seule l'image dit qu'un dé ressemble à un bol.
