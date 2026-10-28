# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La demande dit : « le héros doit tirer sur le golem ». La conception précise : des projectiles
rapides mais pas instantanés (le golem doit pouvoir se protéger derrière son bouclier), une cadence fixe, et une
**surchauffe** au lieu de munitions, pour que le joueur choisisse ses rafales. Le golem n'existe pas encore : on tire
sur la cible rouge, qui reçoit maintenant une santé.

Ce qu'on obtient : gâchette droite ou clic gauche, l'arme tire dix fois par seconde vers le centre de l'écran ; dix
tirs d'affilée la font surchauffer, et elle reste bloquée un peu plus de deux secondes ; le héros se tourne vers là où
il vise, même en reculant ; il ne tire pas pendant une roulade ; chaque tir qui touche la cible lui retire 12 points.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : viser (gâchette gauche ou clic droit), tirer (gâchette droite ou clic gauche) sur le bloc rouge. Sa vie se lit
   dans l'inspecteur distant (`Target/Health`) ; la jauge viendra avec l'interface.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Viser : le centre de l'écran est l'avant de la caméra

Un jeu de tir à la troisième personne vise ce que le joueur voit au centre de l'écran. Ce centre n'a besoin d'aucune
projection : c'est l'axe -Z de la caméra (`-global_basis.z`). On lance un rayon de la caméra dans cette direction
(`Aim.point`) ; le premier obstacle touché est le point visé. Le projectile part ensuite de l'arme (à la main droite)
**vers ce point**, pas dans la direction de la caméra : sinon, l'arme étant décalée, le tir passerait à côté de ce que
le joueur voit.

Le rayon de visée regarde les mêmes couches que les projectiles (`Projectile.hit_mask()` : le décor et les cibles) ;
le héros n'y est pas, il ne se vise donc jamais lui-même.

### 2. Un projectile rapide ne doit rien traverser

À 70 m/s, un projectile parcourt plus d'un mètre par image. Une zone qui détecte des chevauchements (une `Area3D` qui
surveille) le raterait : il serait devant le bouclier à une image, derrière à la suivante. On fait donc l'inverse :
chaque image, le projectile lance un rayon sur le trajet qu'il va faire (`intersect_ray` de la position actuelle à la
suivante). Un rayon voit tout ce qu'il croise, quelle que soit la vitesse. Le test le prouve sur une zone de 5 cm
d'épaisseur.

La requête du rayon (`PhysicsRayQueryParameters3D`) est créée une fois par projectile et réutilisée : on ne change
que ses deux bouts.

### 3. Ce qui reçoit un tir : une zone, une santé, un multiplicateur

`Hurtbox` (`1_core/combat/`) est une `Area3D` sur une nouvelle couche, **cibles** (couche 6), qui passe les dégâts à
une santé (`HealthComponent`, reprise de l'atelier) en les multipliant : plus de 1 pour un point faible, 0 pour un
bouclier (le tir s'arrête, sans dégâts). Le golem aura plusieurs zones (corps, dos, jointures, bouclier) qui
partageront sa santé ; la cible rouge n'en a qu'une. La zone ne surveille rien (`monitoring = false`) : ce sont les
rayons des projectiles qui la trouvent, ce qui ne coûte rien quand personne ne tire.

Pourquoi une couche de plus : le corps physique du golem (celui qui bloque le héros) n'est pas ce qu'on touche ; ce
sont ses zones. Une couche à part laisse les rayons ignorer les corps.

### 4. Une réserve de projectiles : rien n'est créé en combat

`ProjectilePool` crée tous ses projectiles au chargement du niveau (32 : la cadence × la durée de vol donne 6 en vol
au plus, avec de la marge). Un tir en prend un ; touché ou éteint, il revient (`finished`). Un projectile au repos est
invisible et sans traitement (`set_physics_process(false)`). Créer un nœud en plein combat coûte des allocations et
peut faire sauter une image : le test compte les nœuds du jeu (`Performance.OBJECT_NODE_COUNT`) avant et après six
tirs, et attend le même nombre.

### 5. L'arme et sa chaleur

`HeroGun` (le nœud est la bouche de l'arme) tire si la cadence est écoulée, si l'arme n'est pas surchauffée et s'il
reste un projectile. `HeatComponent` est bâti comme l'endurance : chaque tir ajoute de la chaleur et relance un délai ;
après le délai, elle redescend ; au maximum, l'arme surchauffe et reste bloquée **jusqu'au retour à zéro**.

**Le piège de la cadence.** La cadence se décompte image par image : 0,1 − 6 × (1/60). En nombres flottants, ce
calcul laisse 3e-17, pas 0. Avec `_cooldown <= 0.0`, l'arme attend donc une septième image : 8,6 tirs par seconde au
lieu de 10. La correction : `is_zero_approx(_cooldown)` compte « presque zéro » comme zéro. Le test le vérifie (8 tirs
en 48 images) ; en retirant la correction, il échoue avec 7.

### 6. Le héros tire en marchant, pas en roulant

L'état Move tire quand la gâchette est tenue (après avoir regardé si une roulade attend) ; l'état Roll ne tire pas :
une roulade engage le corps entier. En visant ou en tirant, le corps se tourne vers là où regarde la caméra
(`facing_direction`) : on peut reculer en tirant devant soi.

### 7. Les tests d'abord

- La santé (reprise de l'atelier, ses réglages construits dans le test) ; la chaleur : chauffe, surchauffe une seule
  fois, refroidissement après délai, déblocage à zéro.
- La zone : sa couche, son multiplicateur, le blocage.
- Les projectiles dans un vrai monde physique : vol droit à sa vitesse, arrêt sur un mur (à sa face, -4,9 pour un mur
  de 20 cm à -5), dégâts multipliés à travers une zone mince, blocage, durée de vol, réserve vide, aucun nœud créé.
- La visée : premier obstacle, bout du rayon, le héros ignoré, une zone des cibles vue.
- L'arme : direction, cadence exacte, surchauffe puis reprise après refroidissement.
- Le héros et la scène principale : tir à la cadence puis surchauffe, rien pendant une roulade, le corps tourné vers
  la caméra en reculant ; et, dans le vrai niveau, tirer sur la cible lui retire de la vie.

Une erreur rencontrée en écrivant les tests : une variable nommée `before` masque la fonction `before()` de
`GdUnitTestSuite`, et la compilation stricte refuse la suite entière (« shadowing an already-declared function »).
On l'a renommée `start_z`.
