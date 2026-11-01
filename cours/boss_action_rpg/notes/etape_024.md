# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La suite de l'étape 23, et de la demande de laurent : « le boss n'a aucun VFX non plus.. pas de boules de feux, pas d'aura magiques
par d'eclaires lances... », puis « ce n'est pas du tout au strandard des jeu video de 2026 ». Les sorts de l'étape 20 restent les mêmes coups, avec les
mêmes temps et les mêmes zones : seule leur image change.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a cherché

Le temps d'un effet : une annonce, un sommet, une retombée ; un effet qui s'arrête net paraît faible ([VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)).
Une explosion est un empilement court : une onde qui part d'abord, un éclat de deux ou trois images, un cœur, de la fumée, deux sortes
d'étincelles ; les départs ne diffèrent que de deux ou trois images ([realtimevfx](https://realtimevfx.com/t/stylized-frag-launcher-explosion-overwatch-inspiration-breakdown-posted/1894?page=2)).
Une critique détaillée donne le reste : la poussière reste basse et s'attarde, les débris partent en cône, jamais en sphère, la brûlure garde
une lueur qui s'éteint lentement, l'éclat est une forme à pointes plutôt qu'une boule floue ([realtimevfx](https://realtimevfx.com/t/looking-for-feedback-on-explosion-vfx/29528)).

## Ce qu'on a fait, dans l'ordre

### 1. La boule de feu

- **L'annonce** : la boule grandit au bout du marteau, et des braises convergent vers elle (`Gather` : `radial_velocity` négative).
- **Le vol** : `Core` est le flipbook `boule`, une sphère qui brûle en surface, en boucle. Flammes, fumée et braises vivent dans le monde
  (`local_coords = false`) : elles restent derrière elle et font la traîne, sans ruban étiré. `Haze` déforme l'air autour d'elle.
- `heat_haze.gdshader` relit l'écran (`hint_screen_texture`), à une priorité négative : l'image relue ne contient pas les objets transparents, il ne
  doit pas les effacer.

### 2. L'explosion

Dans l'ordre : `Flash` (l'étoile, deux images), `Shock` (un anneau qui déforme l'image), `Ball` (trois plans de l'atlas `explosion`, qui passent du feu à la
fumée sombre), `Lobes` (des plans plus petits, jetés loin puis freinés), étincelles, braises portées par la turbulence, éclats, un anneau de
poussière basse, des flammes qui restent au sol (`Stream`, comme la fumée du tir) et une brûlure (`Mark`, un Decal).

- L'explosion se pose au sol : sa boule est à un mètre au-dessus du nœud, `GolemSpells` descend le nœud jusqu'au plancher.
- **La brûlure se projetait en stries verticales sur les meubles** : un Decal projette le long de son axe. `normal_fade` l'efface sur ce qui ne regarde pas
  en haut, et sa boîte est plus courte.
- **Les éclats orange ressemblaient à des confettis** : plus petits, sombres, sans émission.
- **Un lobe volait à six mètres** : `damping` est une décélération en m/s², pas un coefficient : 16 m/s freinés à 20 m/s² parcourent 6,4 m.

### 3. L'éclair

L'ancien ruban avait 24 points au hasard : un zigzag. Un éclair est une ligne brisée à toutes les échelles : `_zigzag` part des deux bouts et coupe
chaque morceau en deux, six fois, en écartant le milieu d'un peu moins à chaque passe (`ROUGHNESS`). Six branches repartent du tronc.

Un éclair frappe en plusieurs coups : chaque forme est un coup, fort, qui retombe vite (`level`, un paramètre du matériau : les rubans ne sont refaits qu'à
chaque forme, pas à chaque image). Le fil est très fin : c'est lui qui nourrit la lueur de l'écran ; l'ancien ruban épais paraissait dessiné au feutre.

**Trois lumières à 30 d'énergie saturaient la brume en blanc** : le volume de brouillard additionne chaque lumière. 11 d'énergie et
`light_volumetric_fog_energy` à 1,2 : la pièce s'illumine sans disparaître.

La marque n'est plus un anneau parfait : un bord irrégulier, des filaments qui gagnent le cercle, qui vacillent de plus en plus vite ; des étincelles
montent du sol. Elle doit rester un cercle : le joueur y lit où ne pas rester. Après le coup, la brûlure garde ses fissures bleues.

### 4. L'aura

En seconde phase, du feu monte des épaules, du torse, de la main et du marteau. Un GPUParticles3D suit chaque os, et ses flammes vivent dans le monde : quand
le Gardien bouge, elles traînent. Le nom du nœud est le nom de l'os : pas de table à tenir. Les premières flammes noyaient le golem : plus petites, moins
chaudes (`aura_flame_material`).

### 5. Qualité basse

`effect_detail` 0,6 ; `distortion` faux : `set_group` cache tout ce qui relit l'écran (groupe `vfx_distortion`). Les chiffres de la carte Intel sont dans `suivi.md`.

## Les tests

Un tronc qui part du bon point et arrive au bon point, des branches qui partent du tronc ; plusieurs coups qui faiblissent ; le feu de l'aura ne vient qu'en
seconde phase, suit son os et s'éteint ; la boule rassemble ses braises puis les laisse ; la marque reste après les particules, sa braise s'éteint d'abord.
