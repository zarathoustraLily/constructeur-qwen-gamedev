# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un combat exigeant n'a de sens que si l'on peut perdre. La conception demande : trois fioles,
chacune longue à boire (immobile, punissable) ; la mort fait recommencer. Il faut aussi ce qui fera mal au héros :
la **zone de coup** que les attaques du golem allumeront à l'étape 8.

Ce qu'on obtient : le héros a 100 points de vie ; un coup le fait reculer et chanceler un instant, sans pouvoir agir,
puis le protège 0,6 s des coups suivants ; la roulade esquive tout pendant son début ; X (manette) ou E fait boire
une fiole : 1,1 s immobile, le soin arrive à 0,7 s, et un coup reçu avant fait perdre la fiole sans soigner ; à zéro,
il tombe, et le niveau recommence 3 secondes plus tard, tout remis à neuf.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : le golem n'est pas encore là pour frapper ; la vie et les fioles se lisent dans l'inspecteur distant
   (`Hero/Health`, `Hero/Flasks`). Boire une fiole (X ou E) se voit : le héros s'arrête net.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Ce qui frappe : une zone allumée pendant la fenêtre du coup

`Hitbox` (`1_core/combat/`) est une `Area3D` sur la couche des coups du boss, qui regarde la couche du héros. Elle
est éteinte par défaut ; une attaque l'allume au moment où le coup doit toucher (`activate(dégâts)`) et l'éteint
après. Allumée, elle frappe ce qui la touche déjà (`get_overlapping_bodies`) et ce qui entre ensuite
(`body_entered`), **une seule fois par allumage** : sans cette règle, un coup de marteau qui dure dix images
frapperait dix fois.

Elle ne connaît pas le héros : elle frappe tout corps qui sait recevoir un coup (`has_method(&"take_hit")`). Un
script de `1_core/` ne doit pas dépendre d'une entité de `3_entities/` (règle des dossiers) ; demander une méthode
plutôt qu'une classe garde la zone réutilisable (un tonneau destructible, plus tard, n'aura qu'à avoir `take_hit`).

### 2. Recevoir un coup : trois protections, dans l'ordre

`Hero.take_hit(montant, origine)` rend les dégâts vraiment faits, et rien quand :
1. le héros roule (son invulnérabilité de l'étape 4) ;
2. il est dans le répit qui suit un coup (`HealthComponent`, le même que la cible de l'étape 5, avec 0,6 s de répit
   cette fois : un boss qui frappe deux fois de suite ne doit pas tuer d'un coup) ;
3. il est déjà tombé.

Un coup qui porte fait passer à **Hit** : le héros recule à l'opposé du coup (`knockback_direction`), à 5 m/s qui
retombent à zéro en 0,35 s, et ses entrées sont ignorées. Le dernier coup fait passer à **Dead** et annonce
`defeated`.

### 3. Boire une fiole : immobile et punissable

`FlaskComponent` ne compte que les fioles ; ce qu'une fiole rend et le temps qu'il faut pour la boire sont dans les
réglages du héros. L'état **Heal** prend la fiole **au début** (un coup reçu avant le soin la fait perdre), arrête le
héros, soigne à 0,7 s, et revient à Move à 1,1 s. Le soin passe par la mémoire d'appui, comme la roulade.

C'est la règle qui donne du sens au combat : on boit quand le golem ne peut pas frapper (après son coup, pendant sa
récupération). Le golem de l'étape 7 laissera exactement ces fenêtres.

### 4. Tomber et recommencer

Le héros tombé ne fait plus rien (état Dead, seule la gravité agit). La scène principale écoute `defeated`, lance un
minuteur de 3 s (`EncounterSettings.restart_delay` : le joueur a le temps de voir ce qui l'a tué), puis recharge la
scène (`reload_current_scene`). Tout repart de zéro : héros, fioles, cible, et le golem quand il sera là, sans
écrire de code de remise à zéro pour chacun (et donc sans en oublier un).

### 5. Les tests d'abord, et ce qu'ils ont appris

- La zone de coup, dans un vrai monde physique : couche et masque ; éteinte, rien ; allumée, une fois ; rallumée, de
  nouveau ; ce qui entre allumée ; un corps sans `take_hit` ignoré.
- Les fioles ; le héros : coup et recul, rien pendant la roulade, répit, fiole bue immobile et soin au bon moment,
  pas de fiole pas de soin, fiole perdue si un coup tombe pendant la gorgée, chute une seule fois et plus aucun
  mouvement ; la scène : le minuteur de recommencement part avec son délai.

**Ce que le test a appris.** La première version posait une victime `StaticBody3D` dans la zone : aucun coup ne
partait. Le moteur physique du projet est GodotPhysics3D (le réglage `physics/3d/physics_engine` vaut « DEFAULT »,
et la référence de `ProjectSettings` dit : « DEFAULT is currently equivalent to GodotPhysics3D ») ; avec lui, la zone
n'a signalé aucun `StaticBody3D` posé dans son volume, alors qu'elle signale un `CharacterBody3D`. Le héros est un
`CharacterBody3D` : le test emploie donc le même type de corps. Règle : un test de collision reproduit les types de
corps du jeu, pas des corps commodes.

**Le recommencement se vérifie en jouant.** Sous GdUnit, la scène courante est le lanceur de tests : y recharger la
scène relancerait les tests. Le test vérifie donc la décision (le minuteur part, avec le bon délai), et le
rechargement lui-même a été vérifié en jouant le niveau sans fenêtre : un scénario charge `main.tscn`, fait tomber
le héros, attend 3,5 s, et lit la scène neuve (autre identifiant, héros à 100 de vie, 3 fioles, état Move).
