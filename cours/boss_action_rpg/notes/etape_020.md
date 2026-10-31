# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, en jouant : « le boss n'a aucun VFX non plus.. pas de boules de feux, pas d'aura magiques
par d'eclaires lances... ». Le Gardien ne frappait qu'au corps à corps. Il lance maintenant des boules de feu et des
éclairs, et une aura l'entoure dès qu'il s'éveille. Ce sont de nouvelles attaques, pas seulement des effets : chacune a
son annonce, sa zone de coup, sa réserve, ses tests et ses sons.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a mesuré d'abord

### Quel geste pour un sort ?

Le golem n'a pas de clip de sort. `outils/planche_golem.gd` montre ses gestes image par image :
- `attack3` avait été écarté à l'étape 12 : son marteau ne descend pas sous 1,7 m. Pour lancer une boule, c'est le bon
  geste : il lève le marteau, puis le jette en avant, au plus vite à 0,97 s (mesuré par `outils/mesurer_golem.gd`) ;
- `gethit3`, le rugissement du passage à la seconde phase, le fait se cabrer : c'est le geste des éclairs.

Un geste de 1,7 s, c'est court pour s'annoncer. `GolemAttack.clip_rate` l'étire : à 0,7, la boule part 1,3 s après le
début de la préparation.

### Les spectres

Les spectres ne plongent pas pendant une attaque du Gardien (`SpectreCall.claim_dive`) : une attaque de plus pouvait les
retenir. `outils/trace_combat.gd` compte tout sur 90 s, héros immobile en seconde phase :

| Distance | Étape 19 | Étape 20 |
| --- | --- | --- |
| 8 m | 6 écrasements, 27 plongées | 6 écrasements, 8 éclairs, 23 plongées |
| 14 m | 17 bonds, 18 plongées | 11 salves, 7 éclairs, 2 bonds, 25 plongées |

Les spectres plongent autant. Et à 14 m, le Gardien cesse de bondir sans arrêt : il varie ses coups.

## Ce qu'on a fait, dans l'ordre

### 1. Un coup qui porte un sort

`GolemAttack` gagne le sort, ses instants (`charge_start`, `cast_time`), son nombre, ses dégâts, et `cooldown` : sans repos,
un golem qui a toujours un sort permis à distance ne marcherait plus jamais vers le héros. `Golem.choose_attack` regarde
ce repos (`rested`).

`GolemAttackState` dit deux choses au bon instant : le sort se prépare (`begin_charge`), le sort part (`cast_spell`). Si
l'attaque est interrompue, `end_charge` efface ce qui n'est pas parti. Le golem ne sait rien de la boule ni de l'éclair :
`GolemSpells` écoute ses signaux et fait le reste.

### 2. La boule de feu

`Fireball` est tenue au bout du marteau pendant la préparation, et y grandit : c'est l'annonce. Lancée, elle file à 15 m/s
vers sa cible en la suivant un peu (0,5 rad/s) : une roulade de côté l'évite. Comme les tirs du héros, elle lance un rayon
à chaque image sur son trajet : elle n'entre jamais dans le décor.

L'explosion frappe par la distance, sans zone physique, et par `take_hit` : la roulade reste une protection, sans une ligne
de plus. Une boule qui part à 4 m de haut et frappe à ras de sol se voit de loin.

Son image :
- un disque tourné vers la caméra (`fireball.gdshader`), où deux bruits filent du centre vers le bord, en coordonnées
  polaires : les langues de feu sortent du cœur ;
- sa traîne reprend `tracer.gdshader` de l'étape 19 avec un autre matériau ;
- des flammèches restent derrière elle (particules dans le monde, `local_coords` faux) ;
- `fire_blast.tscn`, quatre salves à tour de rôle, joue l'explosion.

En seconde phase, trois boules en éventail.

### 3. Les éclairs

Trois marques au sol : sous le héros, et de chaque côté, en travers de la ligne qui va du Gardien à lui. Un cercle fixe
borde la zone, un second se referme vers le centre jusqu'au coup (`ground_ring.gdshader`) : on voit où et quand. La zone
de coup est un `Hitbox` posé d'avance : il voit ainsi les corps déjà dedans à l'instant où il s'allume, 0,12 s.

L'éclair part du marteau : c'est le ruban en zigzag du cours du kart, simplifié. Pas de déplacement de points médians, qui
crée des tableaux à chaque génération : chaque point s'écarte de la droite, dans un tableau préparé d'avance, de moins en
moins vers ses deux bouts. Le ruban est refait dans un `ImmediateMesh`, comme la traînée du marteau.

### 4. L'aura

Trois choses, à faible coût :
- **un liseré de feu sur sa silhouette**. La couche de braise de l'étape 13 est déjà dessinée sur son armure : on y ajoute un
  Fresnel (`pow(1.0 - dot(NORMAL, VIEW), …)`). Aucun objet de plus à dessiner ;
- **des braises qui montent autour de lui** : un émetteur en boîte autour de son corps, `amount_ratio` à 0,5 en première
  phase, 1 en seconde ;
- **une lumière** qui palpite sur son torse.

Elle s'allume à son réveil, monte en seconde phase, s'éteint à sa chute.

### 5. La qualité basse

Les lumières des sorts et de l'aura sont coupées, comme celles des tirs. `GraphicsQualityApplier` passe par
`SceneTree.set_group` : `Fireball`, `GolemEffects` et `VfxBurst` ont chacun un `light_allowed`, sans parent commun.

### 6. Les sons

Cinq nouveaux `SoundCue` : préparation, lancer, explosion, marque, coup. Trois fichiers de plus (`laserLarge`, Kenney,
CC0) ; le reste réutilise des sons déjà là, à une autre hauteur. Choisis sur leur nom et leur durée, sans les entendre.

## Ce que l'image a appris

- **Un héros qui tombe sans fin** : à 16 m du Gardien, dans l'axe de la porte, il est sorti de la salle. L'image était vide,
  sans erreur. À 10 m, il reste au sol.
- **Une caméra dans une table** : la vue de côté tombe dans un meuble géant. Les images se font de la vue du joueur.
- **Une explosion qui couvre tout l'écran** : étoile et lueur réduites, teinte plus sombre.
- **Une boule de lait** : même défaut qu'à l'étape 19 : AgX blanchit l'orange vif. Éclat ramené à 1,5, cœur plus petit.
- **Des bâtons de lumière** : les étincelles d'un éclair, de près, faisaient des barres. Plus fines, plus courtes.
- **Une aura invisible en première phase** : relevée de 0,45 à 1, liseré plus large, et plus de braises.

## Les erreurs

- `amount_ratio` est gardé en 32 bits : on le compare avec une tolérance.
- Un test posait « à 15 m, aucun coup » : c'est faux dès qu'il a un sort. Le test dit maintenant ce qu'on veut : une boule,
  puis rien pendant son repos.
- Une retouche de commentaire dans `vfx_burst.gd` changeait l'étape 19 : `outils/verifier_etapes.py` l'aurait refusée. Tout
  ce qui change un fichier ancien passe sous une balise.

## Les mesures

Rendu en 1280 × 720, carte presque libre, Gardien qui enchaîne ses sorts sans récupérer, spectres sortis :

| | Sans sort (étape 19, au repos) | Sorts |
| --- | --- | --- |
| Haute, temps de la carte | 1,733 ms | 1,915 ms |
| Haute, appels de dessin | 2 683 | 2 718 |
| Basse, temps de la carte | 0,334 ms | 0,369 ms |
| Basse, appels de dessin | 594 | 634 |
| Basse, mémoire vidéo | 378 Mo | 382 Mo |

Ces temps viennent de la 5090 : ils disent que les sorts coûtent environ 10 % de plus au plus fort, pas ce que tiendra un
petit PC. Le repos ne change pas : 1,732 ms en haute à l'étape 20, 1,733 ms à l'étape 19.

Combat sans fenêtre, héros à 7 m : 70 sons, 140 allocations, 0 pour notre code, 0,59 ms par image. Héros à 14 m (`--loin`) :
3 sorts, 122 sons, 244 allocations, 0 pour notre code, 0,59 ms par image, 4,3 ms au plus haut.

## Les tests

- Il lance ses boules de loin, pas de près, et attend entre deux ; ses éclairs n'existent qu'en seconde phase.
- Un sort s'annonce plus d'une seconde avant de partir.
- La boule grandit dans sa main, part vers sa cible, la suit un peu, explose près d'elle ou contre le décor ; l'explosion
  frappe à portée, pas au-delà, ni un héros qui roule.
- En seconde phase, une salve en éventail.
- Les éclairs marquent le sol sous la cible et de chaque côté, frappent depuis le marteau, et leur zone ne reste allumée
  qu'un instant.
- Un sort interrompu s'efface ; tout est préparé d'avance et rien n'est créé en combat.
- L'aura : éteinte endormi, plus forte en seconde phase, éteinte à sa chute.
- Chaque sort a son son.

Avec les cas des étapes précédentes : 269 cas verts. Images en Forward+ et en Compatibilité (les trois nouveaux shaders et le
liseré s'y dessinent ; la seule erreur est le brouillard, connu).
