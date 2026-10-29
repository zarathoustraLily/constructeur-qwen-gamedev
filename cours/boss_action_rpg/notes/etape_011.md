# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent voulait « des ennemis fantômes volants avec un effet spécial de bleue luminosité
transparente qui apparaissent à une étape pour aider le boss et se jeter sur le héros ». Une première version habillait
le soldat du héros de l'effet ; laurent : « c'est excellent mais je voudrais plus des mesh de fantômes genre squelette
ou monstres volants ». Il a choisi un **squelette fait par le code** plutôt qu'un modèle téléchargé : rien à
télécharger, aucune licence à vérifier, et le squelette s'anime par le code.

Ce qu'on obtient : quand la vie du Gardien passe sous les deux tiers, trois squelettes spectraux sortent un par un. Ils
sont bleus, lumineux et transparents, drapés d'un linceul en lambeaux. Ils planent en cercle au-dessus du héros. Chacun,
à son tour, se cabre bras et mâchoire grands ouverts en s'illuminant, puis plonge sur lui, couché, griffes en avant, le
linceul étiré derrière. Trois tirs en dissipent un pour de bon.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier, en rendu Forward+ (la brume de l'étape 10 l'exige).
2. F5 : tirer sur le Gardien jusqu'à ce que sa jauge passe sous les deux tiers ; les spectres sortent.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Le comportement : une machine à états, un appel

Un spectre (`3_entities/enemies/spectre/spectre.gd`) vole et traverse le décor : pas de corps physique, il se déplace
par sa position. Ses états, un fichier chacun dans `states/` :

- **Idle** : il dort, invisible et intouchable ;
- **Hover** : il plane sur un cercle de 6 m autour de sa cible, 2,6 m au-dessus d'elle, pendant 2,5 s ;
- **Windup** : il annonce sa plongée pendant 0,7 s ;
- **Dive** : il plonge vers le torse de sa cible, à 18 m/s, la zone de coup allumée ;
- **Recover** : il remonte ;
- **Fade** : abattu, il se dissipe.

Sa plongée touche une fois (18 points). Tous les chiffres sont dans `5_data/enemies/spectre.tres`.

L'appel (`3_entities/boss/spectre_call.gd`) écoute la santé du Gardien. Sous le seuil, il fait sortir les spectres
préparés avec le niveau (jamais créés en combat), à 1,2 s d'écart, chacun à sa place sur le cercle. C'est une seule
fois par combat.

### 2. L'effet : le Fresnel du RAG

La requête `search_docs("shader Fresnel silhouette transparente additive bord brillant")` rend l'exemple vérifié
`bouclier_fresnel`. Plus une surface est vue de biais, plus elle brille :
`pow(1 - dot(NORMAL, VIEW), puissance)`. Le rendu est `unshaded, blend_add, depth_draw_never` : le spectre ajoute de
la lumière et ne cache rien.

On y ajoute un scintillement (un bruit qui défile) et trois **poids par sommet**, rangés dans la couleur des sommets
par le générateur :
- r, l'ondulation : 0 pour les os, de plus en plus fort vers le bas du linceul ;
- g, la dissolution : le bas du linceul s'efface en volutes ;
- b, l'éclat : 0,5 pour l'ordinaire, 0 au fond des orbites, 1 pour les feux des yeux.

Le shader déplace les sommets dans `vertex()` (ondulation, et `trail` : le linceul s'étire quand le spectre plonge).

### 3. Le squelette, fait par le code

**L'outil de maillage** (`1_core/procedural/mesh_builder.gd`, commun à tout modèle procédural) empile des formes dans
un seul jeu de tableaux :
- des boules déformables (`ellipsoid`) ;
- des tubes le long d'un chemin (`tube`, avec un repère transporté d'un point à l'autre pour que les anneaux ne
  vrillent pas) ;
- des nappes à deux faces (`sheet`).

Il rend un `ArrayMesh` d'**une seule surface**, donc un seul lot de dessin par pièce. Les normales lisses se calculent
pièce par pièce, à la fin (`begin_part`, `end_part`), pour qu'on puisse déformer une forme sommet par sommet avant.

Les triangles tournent dans le sens des aiguilles d'une montre, vus de l'extérieur : c'est la face avant pour Godot. Un
test le vérifie, puisque nos normales sont celles que `SurfaceTool.generate_normals` calcule sur les mêmes triangles.

**Les pièces** (`6_assets/Mesh/Procedural/spectre/spectre_bones.gd`) :
- un crâne, tiré d'une boule : face aplatie, orbites et nez creusés et éteints, arcades, pommettes, joues creuses,
  deux feux dans les orbites, des dents ;
- une mâchoire en fer à cheval ;
- une colonne qui finit en queue sous les côtes, sept paires de côtes, sternum, clavicules, omoplates ;
- des bras, et des mains à quatre longues griffes ;
- un linceul drapé sur les épaules, ouvert devant, au bas déchiré. Les longueurs des lambeaux viennent d'un hasard à
  **graine fixe** : deux constructions donnent le même maillage.

Chaque pièce est construite à la première demande, puis **partagée** par les trois spectres. Le modèle monté
(`spectre_model.gd`) pose les pièces sur des articulations : la tête, la mâchoire, les épaules, les coudes, les
poignets.

### 4. Les poses : sans clip d'animation

La vue (`spectre_view.gd`) donne à chaque état une pose : penché, épaules, coudes, poignets, mâchoire, tête, hauteur
du corps, étirement du linceul. Les os glissent vers la pose de l'état en douceur (`1 - exp(-8 × delta)` par image),
et une houle s'y ajoute : le corps flotte, les bras se balancent, la mâchoire claque pendant l'annonce. Le corps se
penche autour de la poitrine, pas autour du bas du linceul.

Deux pièges de rotation, trouvés en calculant avant de poser :
- un bras qui pend, tourné autour de x d'un angle positif, part **en avant**. Levé au-dessus de l'horizontale par
  l'épaule, le même signe le fait partir **en arrière** : l'annonce prend le signe inverse ;
- couché pour plonger, « devant soi » dans le monde est « au-dessus de la tête » dans le repère du corps. Les bras
  tendus devant le corps pointeraient vers le sol.

### 5. Ce que l'image et la mesure ont appris

- **De près, le crâne était un œuf.** Les orbites, trop peu creusées, ne se voyaient pas. Dans un mélange additif, un
  creux ne s'assombrit pas tout seul : la lumière ne fait que s'ajouter. Il faut **éteindre son fond** (le poids
  d'éclat à 0) et creuser plus large.
- **Le capuchon faisait un casque** autour de la tête : on l'a retiré.
- **Le haut du linceul faisait un col de tuyau**, un anneau à plat autour du cou : on l'a drapé, plus bas sur la pente
  des épaules et devant.
- **La mesure** : on a tracé, image par image, la vie du héros et l'origine de chaque coup reçu, sur un héros
  immobile. Les spectres le tuent en 10,6 s (six plongées de 18 points). Puis ils **continuaient de plonger sur le
  corps**. D'où une règle : sa cible abattue, un spectre plane sans plus plonger (`prey_alive`, la santé de la cible
  passée à l'appel).

Le shader a changé : une image en Compatibilité, en plus de Forward+, pour vérifier qu'il compile partout.

- **Le test de documentation lisait trop loin.** Lancé dans le dossier du jeu de laurent, il parcourait aussi les
  outils de suivi et les sources extraites, que Godot ignore (chacun contient un `.gdignore`). Il saute désormais les
  dossiers qui contiennent un `.gdignore`.

### 6. Les tests

- **L'outil de maillage** : ses triangles tournent comme Godot le veut ; un tube a un anneau par point et ses deux
  bouts fermés ; une nappe a deux faces aux normales opposées.
- **Les pièces** : deux orbites creuses, avec un feu dans chacune ; les os ne bougent pas sous le shader, le linceul
  ondule et se dissout de plus en plus bas ; un bas en lambeaux ; une construction par pièce, toujours la même.
- **Le spectre** :
  - il dort, puis plane, annonce, plonge et touche une fois, remonte ;
  - sa cible abattue, il ne plonge plus ;
  - trois tirs le dissipent ;
  - son modèle est un squelette spectral : le shader sur chaque pièce, un matériau à lui, des maillages partagés ;
  - pour annoncer, il ouvre les bras au-dessus des épaules et la mâchoire ;
  - il plonge couché, griffes en avant ;
  - dissipé, il s'affaisse.
- **L'appel** et **la scène principale** : les spectres sortent sous le seuil et chassent le héros.

Avec les cas des étapes précédentes : 183 cas verts.
