# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La main de l'étape précédente reçoit son vrai travail : prendre une arme. Quatre armes faites des restes du géant, sur des bouchons, une boîte de conserve pour les essayer. Les noms,
les chiffres et les formes sont mes choix, à faire valider.

## Les fichiers du projet

{FILES_TABLE}

## Une arme est une donnée

`HeroGun` savait déjà tirer avec des réglages. Une arme n'a donc pas besoin d'une classe : `WeaponKit` est une ressource qui porte un nom, une description, une forme, ses `GunSettings` et ses `HeatSettings`. Le nœud de
l'arme reste le même, et `Hero.equip` lui donne d'autres réglages. Ajouter une arme, c'est écrire un `.tres`.

| Arme | Cadence | Dégâts | Portée | Ce qu'elle demande |
| --- | --- | --- | --- | --- |
| La Cloueuse | 10 tirs/s | 12 | 42 m | rien : c'est l'ancienne arme, chiffres inchangés |
| Le Bouchon | 1,8 tir/s | 52 | 42 m | viser : le projectile est lent, 42 m/s |
| L'Aiguille | 20 tirs/s | 5,5 | 54 m | doser : 18 tirs de suite font surchauffer |
| La Capsuleuse | 2,4 tirs/s | 7 × 9 | 16 m | s'approcher, donc s'exposer |

`equip` remet aussi la chaleur à zéro (`HeatComponent.reset`) : sans cela, changer d'arme aurait gardé une surchauffe d'une arme à l'autre.

## La gerbe

Un seul champ de plus dans `GunSettings` : `pellets`, et `spread_degrees`. Tout reste dans la réserve de 32 projectiles, sans en créer un seul en combat.

**Le motif est fixe**, pas tiré au hasard : le premier part droit, les autres sur un cercle autour de lui (`scattered`). Une gerbe fixe se lit, s'apprend et se teste.

`can_fire` demande maintenant autant de projectiles prêts que le tir en lance. Sans ce changement, une réserve presque vide aurait lancé une demi-gerbe et compté un tir complet.

`test_ce_qui_vole_tient_dans_la_reserve` multiplie, pour chaque arme, la durée de vol par la cadence et par le nombre de projectiles. C'est le calcul qui était écrit en commentaire de `ProjectilePool` à l'étape 5 : il devient une règle.

## Les mains vides

Sans arme, la porte doit rester fermée. Il fallait donc une Bobine désarmée, et ses clips la tiennent en position de tir, les mains fermées sur une arme. Montrer des mains vides dans cette pose aurait l'air d'une erreur.

Elle tient donc une **baguette de bois** : la forme `STICK`, qui ne tire pas. `Hero.unarmed` se pose dans la scène du Terrier, et l'état `Move` le lit. Le combat de `main.tscn` n'en sait rien : le champ y reste faux.

## La bouche suit l'arme

Les quatre armes n'ont pas la même longueur. `HeroView` retenait la bouche une fois pour toutes dans son `_ready`, et le tir serait parti de l'air, ou du milieu du canon. `BobineModel.show_weapon` porte le marqueur au bout du maillage (`get_aabb`), et la vue recalcule `_hand_to_muzzle`.
La longueur n'est écrite nulle part : elle se lit sur la forme.

## Le socle et l'Établi

Chacun tient une seule règle.

- `WeaponStand` montre une arme et dit qu'on l'a prise. Il ne sait pas ce que deviennent les autres.
- `Armory` tient la règle « un seul socle vide » : l'arme qu'on avait retourne sur son socle.
- `Burrow` branche `Armory.chosen` sur `Hero.equip`.

L'arme présentée utilise le maillage de la main, avec le matériau de Bobine. Il n'y a qu'une forme à entretenir pour chaque arme.

## La boîte de conserve

Essayer une arme veut dire la comparer. La boîte réutilise `Hurtbox`, sans santé : un tir y fait 0 dégât. Elle encaisse donc sans fin, penche à proportion du tir, et affiche sa valeur (`Label3D`).

Sa zone est 10 cm plus large que son corps : un tir doit toucher la zone avant le décor. C'est la même leçon que les points faibles du golem.

## Ce que l'image a corrigé

- **L'Établi était noir et rouge** : deux lumières de plus, à partir de cette étape seulement, pour que l'étape 27 reste ce qu'elle était.
- **Les armes étaient trop petites sur leurs socles**, et le bouchon trop sombre : l'arme présentée est plus grande, et sa petite lampe plus forte.

## Les erreurs de cette étape

- **Deux écarts de rangement** : `structure_ecarts.py` a refusé qu'un socle dépende du héros (les formes d'armes étaient rangées avec Bobine) et que l'Établi dépende d'une autre entité. Les formes passent dans `1_core/procedural`, avec leurs propres couleurs, et le socle rejoint le dossier de l'Établi.
- `var before` masque une fonction de `GdUnitTestSuite` : c'est le premier piège noté à la reprise, et je l'ai refait. Une seule suite cassée et GdUnit4 s'arrête, code 105.

## À retenir

- Une arme de plus doit coûter un fichier de données, pas une classe.
- Une règle qui dépend de plusieurs objets a sa place chez celui qui les voit tous : le socle ne sait pas qu'il y en a d'autres.
- Quand une animation suppose un objet en main, il faut un objet en main, même inoffensif.
- Un calcul écrit en commentaire finit faux : on en fait un test.
