# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Dans un combat de boss exigeant, on survit en esquivant : la roulade rend invulnérable un court
instant, elle coûte de l'endurance, et l'endurance règle le rythme du combat (on ne peut pas rouler sans fin). C'est
aussi le premier moment où le héros fait autre chose que courir : c'est donc ici que la **machine à états** entre dans
le projet.

Ce qu'on obtient : B (manette) ou Espace fait rouler vers le stick (ou droit devant, stick lâché) ; pendant les
0,3 premières secondes, aucun coup ne porte ; une roulade coûte un quart de la jauge ; pressée un peu avant la fin de
la roulade en cours, la suivante part dès que possible ; le bouton tenu fait sprinter, ce qui vide la jauge ;
essoufflé, le héros court jusqu'à ce qu'on relâche le bouton.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : rouler (B ou Espace), enchaîner les roulades, tenir le bouton pour sprinter. L'endurance n'a pas encore de
   jauge à l'écran (elle viendra avec l'interface) : dans l'inspecteur distant, `Hero/Stamina` montre sa valeur.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Lire la demande jusqu'au bout

La conception dit : « invincibilité au début de la roulade, coûte de l'endurance ; mémoire d'appui (une roulade
pressée un peu tôt part dès que possible) » et « la roulade et le sprint la consomment ; elle remonte après un court
délai ». Le tableau des contrôles n'a pas de bouton de sprint : on le met, comme souvent dans le genre, sur le bouton
de roulade **tenu**. Un appui fait rouler tout de suite (pas d'attente du relâchement : la roulade doit répondre) ;
si le bouton est encore tenu à la fin de la roulade, le héros sprinte.

Chaque phrase devient une règle qu'un test peut vérifier ; la liste des règles est écrite en tête de chaque suite de
tests, avant le code.

### 2. Pourquoi une machine à états maintenant

Jusqu'ici le héros faisait une seule chose, courir, dans son `_physics_process`. Avec la roulade, il en fait deux qui
s'excluent : pendant une roulade, le stick ne dirige plus, la vitesse est fixe, l'invulnérabilité est active. Mettre
cela dans des `if` du même script mène vite à des drapeaux qui se contredisent (« en roulade mais en train de
viser »). Une machine à états donne une seule réponse à « que fait le héros ? » : un seul état actif à la fois, qui
entre, tourne, sort.

On reprend la machine de l'atelier, déjà testée (`1_core/state_machine/`) : un `StateMachine` dont les enfants
`State` sont les états ; un état demande le suivant par `finish(&"Nom")` ; la machine appelle `exit` de l'ancien puis
`enter` du nouveau. Seule différence : sa priorité, `ProcessOrder.ACTORS`, celle des acteurs dans ce projet.

Le héros n'a plus de `_physics_process` : sa machine fait tourner l'état actif, qui appelle les mouvements du héros
(`step` pour courir, `slide` pour rouler). Le héros garde ce qu'il sait faire ; les états décident quand.

### 3. Deux composants, chacun son travail

- `StaminaComponent` (`1_core/components/`) : l'endurance. `spend` dépense sans passer sous zéro et relance le délai ;
  `tick` laisse passer le délai puis fait remonter, avec le temps qui reste dans l'image (un délai fini au milieu
  d'une image ne perd pas la fin de l'image) ; `changed` s'annonce pour la future jauge. Règle du genre : on peut
  agir tant qu'il reste de l'endurance, même un peu ; l'action vide alors la jauge.
- `InputBuffer` (`1_core/input/`) : la mémoire d'appui. `press` note l'appui pour `window` secondes ; `consume` le
  rend une seule fois. Sans elle, un appui fait 0,1 s avant la fin d'une roulade serait perdu, et le jeu paraîtrait
  ne pas répondre.

Les deux passent à la priorité `COMPONENTS` : l'entrée note l'appui (`INPUT`), les composants mettent leurs minuteurs
à jour, puis la machine du héros décide (`ACTORS`). L'ordre est écrit, pas laissé à l'ordre des nœuds dans l'arbre.

### 4. Les deux états

- **Move** : si une roulade attend dans la mémoire **et** qu'il reste de l'endurance, on passe à Roll (l'endurance est
  vérifiée d'abord, pour ne pas consommer l'appui pour rien). Sinon il court ou sprinte : sprint si le bouton est
  tenu, le stick poussé, sans viser, avec de l'endurance, et pas essoufflé. Le sprint dépense `sprint_cost × delta`
  (une dépense par seconde, donc multipliée par le temps). Quand le sprint vide la jauge, le héros est **essoufflé**
  jusqu'au relâchement du bouton : sinon il repartirait par saccades à chaque petite remontée.
- **Roll** : à l'entrée, la direction est fixée une fois (une roulade engage : on ne la corrige pas en route), le
  corps s'y tourne d'un coup (`Motion.yaw_of`), l'endurance est dépensée, l'invulnérabilité commence. Chaque image, le
  héros glisse à vitesse fixe ; l'invulnérabilité finit après `roll_invulnerable_time` (la fin de la roulade reste
  punissable : c'est ce qui rend l'esquive exigeante) ; après `roll_duration`, retour à Move. `exit` coupe
  l'invulnérabilité quoi qu'il arrive.

Stick lâché, la roulade part droit devant : `Motion.forward_of(lacet)`, l'inverse de `yaw_of` (l'avant d'un nœud de
Godot est son -Z). Verrouillée, la caméra regarde la cible : une roulade sur le côté tourne donc autour d'elle, sans
code de plus.

### 5. Les chiffres dans les données

Vitesse 7 m/s pendant 0,5 s (3,5 m), invulnérable 0,3 s, un quart de jauge par roulade, mémoire de 0,25 s, sprint à
8 m/s pour 20 points par seconde ; jauge de 100 qui remonte de 40 par seconde après 0,7 s sans dépense. Tout est dans
`5_data/hero/` (`hero_settings.tres`, `hero_stamina.tres`), avec une ligne de commentaire qui dit ce que la valeur
donne en jeu.

### 6. Les tests d'abord

- La machine à états : ses règles, reprises de l'atelier.
- La mémoire d'appui et l'endurance, sans scène : en appelant `tick` avec des durées choisies, on vérifie le délai, la
  remontée et le plafond sans attendre de vraies secondes.
- Le héros, en vraie physique (images de 1/60 s) : la roulade va vers le stick à sa vitesse ; invulnérable au début
  seulement (vérifié à 0,05 s puis à 0,38 s, encore en roulade) ; coût et retour à Move ; rien sans endurance ; un
  second appui 0,35 s après le premier donne deux roulades, un second appui à 0,03 s n'en donne qu'une ; sprint,
  essoufflement, reprise après relâchement ; pas de sprint en visant.

Pour compter les roulades, le test écoute `state_changed` de la machine : on vérifie ce que le joueur verrait (deux
roulades), pas une variable interne.
