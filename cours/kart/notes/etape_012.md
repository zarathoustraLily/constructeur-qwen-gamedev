# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Seize poissons nagent en quatre bancs dans l'eau peu profonde, près de l'île. Chacun est
un maillage reconstruit à chaque image autour d'une colonne vertébrale qui ondule. Ils s'écartent les uns
des autres, évitent les hauts-fonds et fuient le kart.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+).
2. F5 : rouler tout droit jusqu'à la mer, et entrer dans l'eau claire de la plage. Les poissons nagent sous
   la surface, et s'enfuient quand le kart approche.
3. Les bancs : nœud `FishSchool` de `2_sequence/main.tscn` (nombre de poissons, rayon, profondeurs).

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un poisson procédural

`3_entities/decor/fish/procedural_fish_view.gd` (`ProceduralFishView`) adapte en 3D « animal-proc-anim »
d'argonautcode :

- **la colonne** : douze articulations à distance fixe. La tête avance ; chaque articulation suit la
  précédente, avec un angle limité à π/8 par rapport à elle. Le battement de la tête se propage ainsi en
  ondulation jusqu'à la queue ;
- **le corps** : un tube de douze anneaux (deux pour le museau, dix vertèbres), dont la largeur suit les
  vertèbres de l'original ;
- **les nageoires** : pectorales et ventrales en ellipses qui battent, caudale et dorsale qui se plient selon
  la courbure du corps.

Le maillage est un `ArrayMesh` reconstruit à chaque image, en coordonnées du monde. Les indices et les
coordonnées de texture ne changent jamais : ils sont calculés une fois pour tous les poissons (`static var`).
Au-delà de 18 m de la caméra, le maillage n'est reconstruit qu'une image sur deux ; au-delà de 70 m, le poisson
est caché.

### 2. Les bancs

`3_entities/decor/fish/fish_school_view.gd` (`FishSchoolView`) installe, par des rayons vers le fond, quatre
bancs là où l'eau a entre 1 et 4,5 m de profondeur. Chaque banc change de destination toutes les 5 à 10 s, à
moins de 12 m de son point d'attache. À chaque image, chaque poisson reçoit une destination et une vitesse :

- sa place dans le banc ;
- un retour vers l'eau profonde, si un haut-fond est devant lui ;
- la fuite, trois fois et demie plus vite, si le kart est à moins de 5 m ;
- un écart avec les poissons à moins de 1,4 m ;
- une hauteur entre le fond et la surface, que la houle fait varier.

Le fond et la surface sont mesurés quelques fois par seconde, pas à chaque image.

### 3. Un décor vivant est une présentation

Les poissons ne changent rien au jeu : ce sont des présentations, d'où leurs noms en `_view`. Le banc d'origine
cherchait le joueur et l'océan par leurs groupes ; ici, la scène principale lui donne ce qu'il fuit
(`threat`, le kart), et il lit l'eau par le contrat WaterSurface. Le hasard (bancs, tailles, places, phases du
battement) vient d'une graine : les mêmes bancs, aux mêmes endroits, à chaque partie. Les dictionnaires
d'origine deviennent des classes internes typées (`School`, `FishState`).

### 4. Les shaders

`fish_body.gdshader` peint le corps : dos plus sombre, ventre clair, trois rayures blanches, un liseré
sombre, des yeux. `fish_fin.gdshader` peint les nageoires, avec un liseré blanc au bord. Les coordonnées de
texture du tube le permettent : UV.x va du museau à la queue, UV.y fait le tour du corps.

## Les tests

- `3_entities/decor/fish/test_procedural_fish_view.gd` : un angle contraint reste près de son ancre ; la
  colonne garde sa longueur en nageant ; le poisson tourne vers sa destination ; son maillage a deux surfaces.
- `3_entities/decor/fish/test_fish_school_view.gd`, au-dessus d'un fond plat à 3 m :
  - tous les poissons s'installent, et nagent entre le fond et la surface ;
  - ils fuient la menace, plus vite ;
  - sans eau assez profonde, pas de banc ;
  - une même graine donne les mêmes bancs.
- `1_core/test_documentation.gd` : chaque membre public a son commentaire, même trois variables voisines.

## Ce qu'il faut retenir

- Une chaîne d'articulations à distance et angle limités donne une ondulation naturelle sans animation.
- Un maillage reconstruit à chaque image coûte : moins souvent au loin, plus du tout hors de vue.
- Les données qui ne bougent pas (topologie, UV) se calculent une fois, pour tous.
- Des comportements simples additionnés (cohésion, séparation, fuite, profondeur) font un banc.

## À essayer

- Dans `main.tscn`, nœud `FishSchool`, passer `flee_distance` à 15 : les poissons fuient de loin.
- Passer `fish_count` à 40 : des bancs serrés.

## Source

- Les poissons viennent du kart d'origine (GDWaterKart, JorisAR, licence MIT), adaptés de « animal-proc-anim »
  d'argonautcode (https://github.com/argonautcode/animal-proc-anim, licence MIT).
- Références des classes (API de Godot 4.7.2) : `ArrayMesh`, `Mesh.ARRAY_*`, `PhysicsRayQueryParameters3D`.

## Étape suivante

Étape 013 : les objets. Boîtes à objets, bombe qui explose et soulève des vagues, plaque de turbo.
