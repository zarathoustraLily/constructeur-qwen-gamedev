# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent a joué : « il y a un enorme probleme de collision avec esc haises etdes que je saute dessus ca bloqe tout ». Une étape non prévue,
et la plus instructive : le défaut était là depuis l'étape 7, et plusieurs symptômes qu'on avait corrigés un par un venaient de lui.

## Les fichiers du projet

{FILES_TABLE}

## Reproduire d'abord

On ne touche à rien avant d'avoir vu le blocage sans fenêtre. Un premier scénario fait sauter le héros contre chaque meuble, de huit côtés : plus de la moitié des
essais restent coincés. La trace image par image d'un de ces essais dit tout : le héros est à y = -0,34, sous le plancher qu'on voit, l'état reste Jump, sa
vitesse verticale est de 6,9 m/s et sa vitesse réelle est nulle. Vu par la caméra du jeu : il disparaît sous le sol.

Une chaise fait 2,3 × 3,35 × 2,4 m, le héros 1,8 m, et il saute à 1 m : il ne peut pas monter dessus. Ce qui l'arrêtait n'était donc pas la chaise.

## La cause : un décor à l'envers

`saloon_collision.res` est une seule `ConcavePolygonShape3D`, faite des coques d'Unity. On a posé la question à la documentation (`backface_collision`) : par
défaut, une telle forme ne collisionne que du côté où regardent ses faces. Puis le plus petit test qui tranche : une face seule, dont `Plane(a, b, c).normal` vaut
+Y, arrête un corps qui descend d'au-dessus, et laisse passer celui qui monte d'en dessous. Le sens d'une face se lit donc avec `Plane`.

Mesure sur la forme : 376 morceaux sur 382 regardent vers leur intérieur. **Une coque à l'envers ne bloque pas celui qui arrive de dehors ; elle enferme celui qui
est dedans.** Le héros entre dans la chaise sans rien sentir, puis chaque paroi l'arrête. Il traverse le dessus du plancher et s'arrête sur son fond, 0,4 m plus bas.

Cette cause explique ce qu'on avait réparé ailleurs :
- étape 7, « le héros tombait dans une chaise géante » : on l'avait déplacé ;
- étape 7, « sa collision d'Unity est sous la plaque, 0,4 m sous la surface qu'on voit » : c'était faux. La collision était bien à la surface, mais à l'envers. On
  avait ajouté les faces rendues du plancher par-dessus (`plancher`, dans `construire_saloon.gd`). **Une réparation qui marche ne prouve pas le diagnostic.**

Une première hypothèse était fausse : un miroir dans les transformations. Seules 2 collisions sur 418 sont en miroir. Ce sont justement les 2 morceaux à l'endroit : les
maillages `_ConvexHulls` arrivent eux-mêmes à l'envers, et le miroir les remettait dans le bon sens par accident.

Les rayons non plus ne voient pas le dos des faces : `hit_back_faces` ne joue que si `backface_collision` est vrai (mesuré : sur la forme à l'envers, un rayon tiré vers une
chaise ne touche rien, quelle que soit cette option ; un rayon vertical la traverse et touche le plancher). C'est ce qu'avaient lu les mesures de l'étape 7 : leurs rayons traversaient le
dessus des coques et touchaient leur fond, 0,4 m plus bas. La mesure disait vrai ; sa lecture était fausse.

## Ce qu'on a fait, dans l'ordre

### 1. La réparation du générateur

`_vers_dehors` regroupe les triangles reliés par leurs sommets, et lit le signe du volume de chaque morceau fermé : un volume négatif veut dire que ses faces regardent
vers l'intérieur. Ce calcul vaut pour une forme non convexe, contrairement à une comparaison avec le centre. Bilan : 399 morceaux, 396 retournés, 1 ouvert (un cadre
accroché au mur, hors de portée), laissé tel quel.

`plancher` disparaît : le dessus des coques est bien à y = 0. On règle la cause au lieu de garder le contournement.

Le générateur accepte un dernier argument, un fichier : il ne refait alors que la forme, sans toucher aux maillages, aux matériaux ni à la scène.

### 2. Pourquoi une nouvelle ressource

`saloon.tscn` n'est pas un maître : il est copié depuis le jeu. Écraser `saloon_collision.res` aurait changé toutes les étapes depuis la 7, et cette étape-ci n'aurait
montré aucune différence. `saloon_solid_collision.res` s'ajoute, et `main.tscn` remplace la forme du nœud `Saloon/Collision/Shape` :

```
[node name="Shape" parent="Saloon/Collision" index="0"]
shape = ExtResource("33_solid")
```

C'est une surcharge d'un enfant de scène instanciée. `[editable path="Saloon"]`, à la fin du fichier, la garde quand on enregistre la scène dans l'éditeur.

### 3. Le saut qui ne finissait jamais

Deuxième défaut, indépendant : `HeroJumpState` attendait d'avoir quitté le sol pour pouvoir y revenir. Un saut qui perd son élan sans décoller ne le quitte jamais :
le héros reste en Jump pour toujours, sans roulade, sans soin, sans nouveau saut, avec un tiers de son contrôle. C'est ce que laurent appelle « ça bloque tout ».

Règle nouvelle : le saut finit dès que le héros ne monte plus et qu'il touche un sol (`velocity.y <= 0` et `is_on_floor()`). Plus d'état à retenir.

Le test le reproduit sans décor : `transition_to(&"Jump")`, élan mis à zéro. Il échoue sur l'ancien code.

**Une règle retirée** : on avait écrit `resting()`, pour un héros calé entre deux pentes sans sol. Le test a montré que Godot traite déjà ce cas : deux murs dont les normales
s'annulent vers le haut comptent comme un sol (`is_on_floor()` vaut vrai dans un V). Le code inutile est parti, le test reste.

La chute est bornée (`max_fall_speed`, 30 m/s, `Hero.fall`) : les traces montraient -151 m/s chez un héros retenu sans sol, de quoi traverser le plancher en se libérant.

### 4. Le golem

Solides, les meubles arrêtent aussi le golem, qui marche droit sur sa cible. `outils/scenarios/golem_chasse.gd` pose le héros, intouchable, en des points du sol libre, et compte ses
coups en 24 s. Il pousse moins qu'avant : une capsule glisse sur une coque ; à l'envers, elle restait prise dedans. Avant, plusieurs points donnaient de 3 à 16 s de poussée sans
avancer ; maintenant, 0.

Un trou est apparu derrière le comptoir : à 7,3 m, le golem n'a plus de coup. Ses coups en main s'arrêtent à 6,5 m, le coup écrasant (5 à 11 m) est refusé car le comptoir barre son
chemin (`path_clear`), et la boule de feu ne partait qu'à 9 m. Elle part maintenant à 6,5 m : la portée de la boule prend le relais des coups en main, sans trou.

## Ce qu'on a vérifié d'autre

- **L'escalier** : ses morceaux commencent hors de la salle, sa coque est à 4,8 m au plus bas. Le héros n'y accédait pas avant, il n'y accède pas maintenant.
- **Le vide** : une marche vers un endroit sans sol serait comptée comme une chute. Il n'y en a aucune.
- **La caméra** : son bras lance un rayon, et un rayon s'arrête comme un corps, sur l'avant des faces (plus bas). Il s'arrêtait au fond des coques ; il s'arrête maintenant sur la
  surface qu'on voit.
- **Les tirs et les sorts** : même chose : un tir s'arrête sur le meuble, plus au fond de sa coque.

## Les mesures

`outils/scenarios/coince_niveau.gd` cherche d'abord tout le sol atteint à pied, par pas de 50 cm, puis fait sauter le héros contre chaque obstacle. Il regarde s'il revient au sol et
en course, s'il peut ressauter, et s'il repart dans une des quatre directions.

| | Avant | Après |
| --- | --- | --- |
| Sol atteint | 809 m², dans les meubles et à travers les murs | 678 m² |
| Essais | 610 | 666 |
| Héros qui ne repart pas | 524 | 0 |
| Saut sans fin | 244 | 0 |
| Saut suivant refusé | 303 | 0 |
| Posé sans sol | 299 | 0 |

Après, 0 piège aussi au sprint et de biais à ±40° : 2 664 essais. Le golem : 19 points, au moins 3 coups à chacun, 0 s de poussée.

Le combat ne coûte pas plus cher, sans fenêtre : image médiane 0,593 → 0,531 ms, pire image 2,30 → 2,49 ms, 0 allocation de notre code. Même nombre de triangles.

## Les tests

- `test_une_chaise_arrete_ce_qui_vient_de_dehors` : un rayon tiré de dehors vers le centre de chacune des 18 chaises les touche. À l'envers, il passe.
- `test_le_heros_saute_contre_une_chaise_reste_dehors_et_repart`.
- `test_un_saut_qui_perd_son_elan_sans_quitter_le_sol_finit_en_course`, `test_un_plafond_n_empeche_pas_le_saut_de_finir`, `test_cale_entre_deux_pentes_il_peut_ressauter`,
  `test_sa_chute_est_bornee`.
- `test_sa_boule_de_feu_prend_le_relais_de_ses_coups_en_main_sans_trou`.

Les trois premiers ont été lancés contre l'ancien code : ils échouent. Un test de non-régression qu'on n'a jamais vu échouer ne prouve rien.

## Les erreurs de cette étape

- **Un script qui plante ne quitte pas** : une erreur dans `_initialize` laisse Godot tourner, sans fenêtre, pour toujours. Ajouter `--quit-after` à ces scénarios.
- **De faux pièges** : le premier scénario posait parfois le héros dans le comptoir. Le remplissage depuis son vrai départ ne compte que le sol atteignable.
- **« Ne repart pas »** : un héros dans un couloir d'une case ne repart pas en arrière. Il faut essayer toutes les directions avant de conclure.
- Un `as PackedInt32Array` sur une valeur de dictionnaire rend une copie : `append` s'y perd.

## À retenir

- Une mesure se lit avec ce qu'elle mesure : un rayon dit où il s'arrête, pas où est la surface qu'on voit. Comparer les deux aurait montré le défaut dès l'étape 7.
- Quand plusieurs bogues se ressemblent, chercher ce qu'ils ont en commun avant d'en réparer un de plus.
- Un état qui attend deux évènements dans l'ordre reste bloqué si le premier n'arrive pas : préférer une condition sur l'état présent.
- Rendre un décor solide change aussi ceux qui le traversaient : ici le golem. Il faut remesurer le combat.
