Règles obligatoires d’organisation du projet

R01 — Structure de référence

L’arborescence définie dans ce document est obligatoire. Les dossiers principaux, leurs noms et leurs responsabilités doivent être conservés.

De nouveaux sous-dossiers sont autorisés lorsqu’ils respectent la responsabilité de leur dossier parent. Aucun nouveau dossier principal de contenu ne doit être ajouté sans modification explicite de ce contrat.

Les numéros servent au classement visuel ; ils ne définissent pas l’ordre d’exécution du jeu.

R02 — Classement par responsabilité

Chaque fichier possède un emplacement de référence, déterminé par son rôle.

| Dossier | Responsabilité |
|---|---|
| `0_autoload/` | Services globaux persistants : déroulement, état de partie, événements partagés, audio global et traces. |
| `1_core/` | Mécanismes et contrats génériques, sans contenu propre à un niveau, un personnage ou une arme. |
| `2_sequence/` | Ordre des étapes et réalisation de chaque étape : cinématiques, menus du déroulé et niveaux. |
| `3_entities/` | Acteurs du jeu : joueur, ennemis, boss et projectiles, avec leurs comportements propres. |
| `4_ui/` | HUD, interfaces superposées et composants d’interface réutilisables. |
| `5_data/` | Paramètres de conception : caractéristiques, configurations d’armes, descriptions de vagues et autres réglages. |
| `6_assets/` | Ressources visuelles et sonores : modèles, textures, audio, shaders, matériaux et polices. |
| `7_tests/` | Tests organisés en miroir des éléments testés. |

L’extension du fichier ne détermine pas son dossier. Par exemple, `sequence.tres` reste dans `2_sequence/`, une configuration d’arme va dans `5_data/`, un matériau dans `6_assets/`.

R03 — Propriété locale

La scène, le script et les états spécifiques d’une entité restent ensemble dans son dossier.

Exemples :
- Machine à états générique → `1_core/state_machine/`.
- État d’attaque propre au joueur → `3_entities/player/states/`.
- Contrôleur de vagues propre au premier niveau → `2_sequence/levels/level_01/`.

Les ressources visuelles et sonores externes restent centralisées dans `6_assets/`, y compris lorsqu’elles servent à une seule entité.

Un élément partagé doit être référencé depuis son emplacement de référence, sans être dupliqué.

R04 — Frontières à respecter

Un menu qui constitue une étape du déroulé appartient à `2_sequence/menus/`. Un écran de pause superposé appartient à `4_ui/overlays/`. Un composant visuel réutilisable peut être placé dans un sous-dossier de `4_ui/`.

Les classes qui décrivent les réglages, comme `enemy_data.gd`, appartiennent à `5_data/types/`. Elles décrivent et valident des données ; elles ne pilotent pas le comportement du jeu.

Les contrats génériques, comme `step.gd`, appartiennent à `1_core/`.

`game_state.gd` conserve l’état courant de la partie. `5_data/` contient les réglages utilisés pour construire cette partie.

R05 — Déroulement du jeu

`sequence.tres` définit l’ordre des étapes.

`game_flow.gd` lit cette séquence et gère les transitions. Il ne doit pas contenir une seconde liste de niveaux codée en dur.

Chaque étape respecte le contrat défini dans `1_core/step/` et signale sa fin. Elle ne charge pas directement l’étape suivante.

Un comportement limité à une entité ou à un niveau ne doit pas devenir un autoload simplement pour être accessible facilement.

R06 — Dépendances

`1_core/` ne doit dépendre d’aucun autoload ni contenu concret du projet. Ses mécanismes reçoivent leurs paramètres et leurs références de l’extérieur.

Une entité ne doit pas dépendre du chemin d’un niveau particulier ou de l’organisation interne du HUD.

Les étapes assemblent les entités, l’interface et les réglages nécessaires. Les échanges passent par des contrats explicites, des références fournies ou des signaux.

R07 — Nommage, tests et exceptions techniques

Les fichiers et dossiers créés pour le jeu utilisent `snake_case`, sauf les documents explicitement nommés autrement, dont `ORGANISATION.md`.

Exemple de miroir de test :
`3_entities/player/` → `7_tests/3_entities/player/`.

Seuls les dossiers de tests utiles sont créés.

Les éléments techniques nécessaires, comme `project.godot`, les fichiers générés par Godot et les fichiers de versionnement, sont traités séparément du contenu du jeu. `addons/` est réservé aux extensions tierces si le projet en utilise.

Ces exceptions ne peuvent pas servir à héberger du contenu mal classé.

R08 — Gestion des ambiguïtés

Tout nouvel élément doit avoir une responsabilité identifiable et un emplacement justifiable par ces règles.

Si aucun emplacement ne convient, signaler précisément l’ambiguïté. Ne pas inventer une exception, créer un dossier fourre-tout ou modifier silencieusement le contrat.