# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, en jouant : « il n'y a aucun effets dans les tirs... c'est super laids,: trouve des VFX
impressionnant pour les tirs », puis « pas de FX ? ». Un tir était une capsule orange de 60 cm, sans lumière. Il a
maintenant un éclair de bouche, une traçante, un impact, et le Gardien réagit quand il est touché.

## Les fichiers du projet

{FILES_TABLE}

## Les sources et leur licence

- Binbun, « Muzzle Flash VFX » et « Hit FX », CC0 (`inventaire_sources.md`). 24 éclairs, 6 impacts, en scènes Godot.
- Leurs scripts ne passent pas nos réglages stricts (rien de typé, `@tool`, un `AnimationPlayer` par effet) : on en garde
  l'art (trois textures d'éclair, les formes de leurs shaders, leurs courbes), pas le code.
- Leurs textures font 1024 × 1024 en RGBA, et le shader ne lit que le rouge. `outils/textures_tirs.py` garde le rouge, en
  256 × 256 : 4 à 11 Ko le fichier, pour un éclair qui ne dépasse pas quelques centaines de pixels à l'écran.
- Leur `AudioStreamPlayer3D` est retiré : le son passe déjà par `CombatSounds`.

## Ce qu'on a fait, dans l'ordre

### 1. Un seul contrôleur, typé, sans animation

`VfxBurst` (`1_core/vfx/`) remplace leurs cinq scripts. À chaque `play` :
- ses enfants `GPUParticles3D` repartent par `restart()`, déjà mesuré sans allocation ;
- sa lueur (`Glow`) et sa lumière (`Light`), s'il en a, s'allument puis s'éteignent sur `duration`, dans `update` ;
- il se cache quand ses particules ont fini de vivre : au repos, il ne coûte rien au rendu.

Le mot `AnimationPlayer` a disparu : le temps suit `update`, comme tout le reste du jeu, et les tests sans fenêtre peuvent
vérifier la lueur et la lumière à l'instant voulu. Les particules, elles, ne sont pas simulées sans fenêtre : les tests
vérifient leurs réglages et leurs relances, et l'image vérifie leur rendu.

### 2. L'éclair de bouche

`3_entities/hero/muzzle_flash.tscn`, enfant de l'arme : trois émetteurs (`Long`, `Side`, `Front`) qui tirent chacun
quelques plans le long du canon, tournés au hasard autour de lui, une lueur et une lumière. La vue du héros le tourne
dans la direction du tir et le rejoue (`HeroView._on_fired`).

Leur shader lit un âge dans l'alpha de la particule : c'est ce que dit la référence (`alpha_curve` « multiplies the
particle mesh's vertex colors ») ; sans `ALPHA *= COLOR.a`, la courbe n'a aucun effet visible, mais rien n'oblige à
l'utiliser comme une transparence. `muzzle_flash.gdshader` s'en sert pour ronger l'éclair depuis sa base.

La vie des particules (0,1 s) est celle de l'intervalle entre deux tirs : à 10 tirs par seconde, chaque éclair finit juste
quand le suivant part. Avec les 0,2 s de la source, l'éclair était coupé à mi-vie et brillait en continu.

### 3. La traçante

La capsule faisait 60 cm à 70 m/s : plus d'un mètre entre deux images, donc des pointillés. Une vraie traçante est plus
longue que ce que le tir parcourt en une image. `tracer.gdshader` étire un seul plan derrière le projectile, sur 5 m :
- `Projectile` règle l'échelle Z du plan à la distance parcourue, sans dépasser `tracer_length` : elle part de la bouche
  de l'arme, jamais de derrière elle ;
- le plan pivote autour de son axe pour faire face à la caméra, **sommet par sommet**. Un seul calcul pour tout le plan
  tordrait la traçante : de près, le regard change beaucoup entre la tête et la queue. D'où `skip_vertex_transform` : la
  référence dit qu'on peut alors faire la transformation soi-même ;
- un fil blanc-jaune dans un halo orangé, en pointe à la tête, effacé à la queue, un peu plus large au loin pour ne pas
  clignoter, éteint tout près de la caméra (`-VERTEX.z`, comme les spectres).

Deux triangles par tir, trente-deux au plus en réserve. La traçante vit dans `3_entities/hero/hero_shot.tscn`, qui reprend
le projectile de `1_core/` et lui ajoute son plan : `1_core/` ne connaît pas les données de `5_data/`.

### 4. L'impact

`shot_impact.tscn`, six salves relancées à tour de rôle par `ImpactSparks`, tournées selon la surface touchée
(`Basis(Quaternion(Vector3.UP, normal))`) : une étoile tracée par le calcul (`impact_star.gdshader`), des flammèches
alignées sur leur vitesse (`impact_flash.gdshader`), dix-huit étincelles qui retombent, une lueur.

Une seule lumière (`ImpactSparks/Flare`) sert tous les impacts : elle saute au dernier, 80 cm devant la surface. Six
lumières coûteraient au rendu sans se voir de plus.

### 5. Le Gardien réagit

Un tir qui porte fait briller un instant les jointures de son armure (`GolemEffects._on_shot`), même en première phase :
on réutilise la couche de braise de l'étape 13, sans rien ajouter au rendu. Un tir bloqué par le bouclier ne fait rien :
le joueur voit la différence.

## Ce que l'image a appris

- **Une boule de lait** : la lueur, trop grande et trop forte, cachait l'éclair. Le tonemap AgX blanchit les orangés
  très vifs. Lueur plus petite, teinte plus saturée, chute très rapide du centre vers le bord.
- **Une étoile en autocollant** : sans dégradé, elle faisait une plage blanche découpée. Bord plus doux, éclat réduit de
  moitié, plus de pointes.
- **Une tête coupée net** : la traçante finissait par un bord droit, plein éclat. Elle s'affine en pointe sur ses premiers
  6 %.
- **La mauvaise caméra** : verrouillé sur le Gardien, dont le point de verrou est haut, la caméra descend au ras du
  plancher, et le héros cache l'éclair. Les images se font de la vue du joueur qui tire de la hanche, de près et de côté.

## Les erreurs

- `varying flat int instance;` : « Expected an identifier or '['. ». `instance` est un mot du langage de shaders (`instance
  uniform`). Les 251 cas étaient verts, code de sortie 0 : l'erreur n'apparaissait qu'en lisant la sortie. Le résumé des
  tests cherche maintenant `SHADER ERROR`.
- Le juge de structure refusait les premières scènes : `6_assets/` et `1_core/` ne doivent connaître aucun autre dossier
  (tableau du plan). Une scène qui a un script et des matériaux va dans `3_entities/` : éclair de bouche, impact et traçante
  sont rangés avec le héros. `outils/structure_ecarts.py` compare chaque étape à la précédente, avant le commit.
- `python -I` ne voit pas les paquets installés pour l'utilisateur (Pillow) : on le garde pour les archives téléchargées,
  pas pour nos propres outils.
- Un outil qui quitte pendant qu'un son joue fait fuir des ressources à la sortie (déjà vu à l'étape 18) : `voir_tirs.gd`
  libère la scène et attend le serveur audio.

## La qualité basse et les mesures

La qualité basse coupe la lumière des effets (`GraphicsQuality.effect_lights`, appliqué par le groupe `vfx_burst`) ; tout
le reste joue. `mesurer_rendu.gd` gagne `--tir` : le héros tire sans arrêt, l'arme toujours froide.

En 1280 × 720, carte presque libre, en tirant sans arrêt :

| | Étape 18 | Étape 19 |
| --- | --- | --- |
| Haute, temps de la carte | 1,734 ms | 1,763 ms |
| Haute, rendu processeur | 1,88 ms | 1,95 ms |
| Basse, temps de la carte | 0,333 ms | 0,336 ms |
| Basse, rendu processeur | 0,55 ms | 0,56 ms |

Ces temps viennent de la 5090 : ils disent que l'écart est faible, pas ce que tiendra un petit PC. Combat sans fenêtre :
63 sons, 126 allocations, 0 pour notre code ; 0,58 ms par image en médiane (0,57 avant).

## Les tests

- Un effet : caché au repos, montré et relancé par `play`, lueur et lumière qui baissent, éteintes au bout de `duration`,
  visible tant que ses particules vivent, remis à neuf s'il est rejoué, sans lumière s'il n'y a pas droit ; aucun effet ne
  garde d'`AnimationPlayer` ni de lecteur de son.
- La traçante s'étire sans dépasser la bouche, jusqu'à sa longueur.
- Un tir allume l'éclair à la bouche de l'arme, dans sa direction.
- Un impact tourne sa salve selon la surface, et la lumière le suit, devant elle.
- Un tir qui porte fait briller les jointures, un tir bloqué non.
- La qualité basse coupe la lumière des effets, la haute la rend.
- Rejouer les effets d'un tir ne crée aucun objet.

Avec les cas des étapes précédentes : 252 cas verts. Images en Forward+ et en Compatibilité (les quatre nouveaux shaders
s'y dessinent ; la seule erreur est le brouillard, connu).
