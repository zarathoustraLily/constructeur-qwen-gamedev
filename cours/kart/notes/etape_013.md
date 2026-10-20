# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Des boîtes à objets flottent sur la piste. En traverser une donne une bombe, et la
foudre frappe le kart. Clic gauche ou bouton de manette : la bombe part vers l'arrière, flotte si elle tombe
à l'eau, et explose cinq secondes plus tard ; dans l'eau, elle soulève une vague. Les plaques de turbo, sur la
piste et au sommet des rampes, donnent deux secondes de turbo.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+).
2. F5 : suivre la piste jusqu'à la file de boîtes. Une icône de bombe apparaît en haut à droite.
3. Clic gauche (ou bouton 10 de la manette, `use_item`) : la bombe part.
4. Les objets : `5_data/items/` (la bombe, la réserve).

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les objets sont des données

Dans `1_core/items/` :

- `ItemType` (une Resource) : le nom de l'objet, son icône, et la façon de le lancer (impulsion,
  distance de départ, rotation). `launch()` crée la scène de l'objet et la jette en avant et vers le haut,
  en tournant ;
- `ItemPool` : la réserve où tirent les boîtes. Chaque objet a son poids, et le tirage suit les poids avec le
  hasard qu'on lui donne. Le tirage pondéré, laissé à faire dans le kart d'origine, est écrit ;
- `Inventory` : deux objets au plus, qui partent dans l'ordre où ils sont arrivés. Il signale chaque
  changement.

`5_data/items/bomb.tres` décrit la bombe : impulsion 10, départ à 2 m, rotation 10 rad/s. La donnée ne
connaît pas la scène de la bombe : c'est la scène principale qui lie l'objet à sa scène (`item_scenes`). Dans
l'original, `bomb.tres` désignait `bomb.tscn` ; or 5_data ne connaît pas les acteurs (règle des dossiers).

### 2. Les boîtes, les plaques et la bombe signalent

- `ItemBox` signale `collected` quand un corps la traverse, puis se retire une seconde (décompte en physique,
  qui s'arrête en pause). Sa présentation (`item_box_view.gd`) la fait flotter, tourner et changer de couleur.
  Le temps est compté par la vue : à cadence fixe, deux parties donnent les mêmes images.
- `BoostPanel` signale `crossed`, avec sa durée de turbo (2 s).
- `Bomb` est un corps flottant (étape 007). Elle explose au bout de son délai : l'explosion est posée à côté
  d'elle, et, dans l'eau, elle soulève une vague par le contrat WaterSurface.

Aucune ne connaît le kart. Dans l'original, la boîte appelait le joueur et la plaque appelait le kart : une
entité ne dépend pas d'une autre (règle des dossiers). La rampe, un décor, contenait une plaque : c'est le niveau
(`island.tscn`) qui pose maintenant une plaque sur chaque rampe.

### 3. La scène principale décide

`2_sequence/main.gd` tient l'inventaire. Au départ, il écoute toutes les boîtes et toutes les plaques du
niveau (`find_children`). Ensuite :

- une boîte prise par le kart lui donne un objet tiré dans la réserve, à graine, et la foudre le frappe
  (un éclair déjà là repart, plutôt que d'en lancer un second) ;
- une plaque donne son turbo au kart, et le turbo lance la traînée fantôme de l'étape 010 ;
- la commande `use_item`, lue par l'adaptateur du kart (`DriveCommands.use_item`), lance le plus ancien objet
  vers l'arrière, du côté de la caméra.

L'affichage (`4_ui/hud/inventory/inventory_display.gd`) montre en haut à droite l'objet qui partira au prochain
usage, en grand, et le suivant. Il ne connaît pas l'inventaire : la scène lui donne les objets à chaque
changement.

### 4. L'explosion

`1_core/components/particle_burst_view.gd` (`ParticleBurstView`) joue une fois les particules d'un effet
(boule de feu, fumée, traînées, étincelles, pointes), puis le supprime ; son minuteur s'arrête en pause
(`create_timer(durée, false)`, règle SIM-08). C'est une présentation, d'où son nom en `_view`.

## Les tests

- `1_core/items/test_item_pool.gd` : le tirage suit les poids ; un poids nul n'est jamais tiré ; tous nuls,
  rien ; sans poids, uniforme ; réserve vide, rien ; même graine, mêmes tirages.
- `1_core/items/test_inventory.gd` : deux objets au plus, partis dans l'ordre d'arrivée ; vide, rien ; chaque
  changement signalé.
- `3_entities/interactables/test_item_box.gd` : un corps la fait signaler une fois ; prise, elle se cache ; elle
  revient ; un kart qui passe dedans est détecté.
- `3_entities/interactables/test_boost_panel.gd` : un kart qui passe dessus la fait signaler.
- `3_entities/items/bomb/test_bomb.gd` : elle explose au bout de son délai, laisse son explosion ; dans l'eau,
  une vague ; hors de l'eau, aucune.
- `4_ui/hud/inventory/test_inventory_display.gd` : vide, il se cache ; la grande case montre le prochain objet.
- `2_sequence/test_main.gd` : une boîte donne un objet et un éclair ; l'objet part vers l'arrière ; une plaque
  donne un turbo.

## Ce qu'il faut retenir

- Les objets du jeu sont des données ; ce qu'ils créent est relié par la séquence.
- Les acteurs signalent ce qui leur arrive ; la scène qui les possède décide ce que ça veut dire.
- Un tirage pondéré : tirer un nombre sous la somme des poids, puis retrancher les poids jusqu'à passer sous 0.
- Un décompte en physique plutôt qu'un minuteur : il s'arrête en pause, et il est rejouable.

## À essayer

- Dans `item_pool.tres`, passer le poids de la bombe à 0 : les boîtes ne donnent plus rien.
- Dans `main.tscn`, passer `inventory_capacity` à 1 : une seule bombe à la fois.

## Source

- Les objets, les boîtes, la bombe, son explosion et les plaques viennent du kart d'origine (GDWaterKart,
  JorisAR, licence MIT).
- Références des classes (API de Godot 4.7.2) : `Resource`, `RandomNumberGenerator`, `Area3D.body_entered`,
  `RigidBody3D.apply_central_impulse`, `SceneTreeTimer`, `Node.find_children`.

## Étape suivante

Étape 014 : la pause et le remappage des commandes. La dernière étape : le jeu complet.
