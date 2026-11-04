# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Bobine existe : il lui faut un endroit où vivre. Le Terrier est sa salle sous le plancher du saloon, avec ce que toute salle de départ demande : marcher,
voir, et actionner quelque chose à la main. L'histoire, la disposition et les réglages sont mes choix, à faire valider.

## Les fichiers du projet

{FILES_TABLE}

## Pourquoi la main avant l'atelier

L'étape suivante pose des armes à prendre, la dernière une porte à ouvrir. Les deux demandent la même chose : voir ce qui est à portée, dire ce qu'on peut en faire, réagir à un bouton.
Cette étape écrit ce mécanisme une seule fois, et l'essaie sur l'objet le plus simple : une bougie qu'on souffle.

- `Interactable` est une zone. Elle ne sait pas ce qu'elle déclenche : son porteur écoute `used`.
- `Interactor` est la main : une zone sur le héros, qui retient l'objet actif le plus proche.
- `InteractPrompt` montre l'invite, avec le bouton de l'appareil qu'on tient.

Le texte peut changer sans signal : `refresh` compare à chaque image l'invite montrée à celle de l'objet. Une chaîne comparée ne crée rien, et la bougie n'a pas à prévenir la main.

**La main ne cherche pas dans un groupe à chaque image.** `get_nodes_in_group` crée un tableau, et la règle du combat est « aucune allocation ». Une `Area3D` tient sa liste à jour par ses signaux.

**L'appui passe par une mémoire**, comme la roulade et le soin. L'état `Move` le consomme : un appui pendant une roulade répond à sa fin, et un coup reçu n'actionne rien.

**L'invite lit elle-même les évènements d'entrée.** Elle sait donc quelle touche nommer sans que le héros s'en mêle. Un stick qui dérive ne compte pas : `InputEventJoypadMotion` part dès que l'axe bouge d'un rien, d'où le seuil.

Dans `Hud`, seule l'invite connaît la main, et `Interactor` est dans `1_core` : la règle des dossiers tient (`4_ui` ne dépend pas de `3_entities`).

## Ce qu'on a fait, dans l'ordre

### 1. Les murs : du CSG, pour une raison précise

Il faut une salle fermée, avec des ouvertures, modifiable dans l'éditeur. Des boîtes séparées laisseraient des faces cachées et des joints. Le CSG soustrait les salles d'un bloc plein :

- `Block` est le bloc plein ; `Nest`, `Passage` et `Workshop` sont soustraits ;
- les planchers et plafonds sont ajoutés ensuite : ils ont leur propre matière ;
- les fentes du plafond sont soustraites à la fin, avec une matière qui brille, et cela suffit à les dessiner.

Les enfants d'un `CSGCombiner3D` s'appliquent **dans l'ordre**. Une pièce ajoutée après une soustraction reste entière.

Le prix habituel du CSG est la reconstruction à chaque déplacement. Ici rien ne bouge : il n'est payé qu'une fois, au chargement. `use_collision` donne une forme concave dont les faces regardent la salle, le bon sens depuis l'étape 25.
Le mesurer évite de le supposer : `mesurer_salle.gd`.

Les matières sont en triplanaire **dans le monde** (`uv1_world_triplanar`) : une boîte CSG n'a pas de coordonnées de texture utiles, et le bois garde la même échelle sur toutes les parois. Sur ce décor qui ne bouge pas, le défaut vu à l'étape précédente n'existe pas.

### 2. Les objets du géant

Le monde se raconte par l'échelle : un livre devient un lit, un fer à cheval le cadre d'une porte, une roue de charrette tient contre le mur. `SolidProp` donne à chacun une boîte à sa taille.

Le corps n'hérite pas de l'échelle du maillage : il est `top_level`, et prend seulement sa rotation et sa position. Une forme de collision sous une échelle non uniforme se comporte mal, et la documentation le dit.

`outils/tailles_decor.gd` lit la taille des maillages et leurs matières dans `saloon.tscn` : on pose un objet sans deviner.

### 3. La qualité sans lune

`GraphicsQualityApplier` attendait une lune et une brume, et le Terrier n'a ni l'une ni l'autre. Les tests de l'ancien chemin restent, et le nouveau cas a le sien. Il n'y a pas de réglage vide à remplir dans la scène, seulement deux tests de `null` sur des choses qui peuvent ne pas exister.

## Ce que l'image a corrigé

- **Le fer à cheval bouchait la vue** : un maillage plat agrandi 46 fois a 1,4 m d'épaisseur. Son échelle est maintenant de 5 dans l'épaisseur.
- **Il était posé à l'envers, puis de travers** : je croyais son ouverture sur l'axe Z de son maillage. Elle est sur X. L'image seule l'a montré.
- **Tout tirait à l'orange, et la moitié est restait noire** : une ambiance froide et plus forte, une seconde bougie, les fentes en lumière froide. Le contraste vient du désaccord entre le froid du haut et le chaud du bas.
- **Bobine était une silhouette noire** devant la bougie : c'est le même remède, l'ambiance plus forte.

## Les erreurs de cette étape

- **Un heredoc bash avec des apostrophes** a cassé tout le script : déjà noté au § 10 de la reprise, et refait. Les fichiers s'écrivent par l'outil d'écriture ou par un script Python.
- **`get_global_transform` hors de l'arbre** dans `voir_salle.gd` : une scène ajoutée dans `_initialize` n'entre dans l'arbre qu'à la première image. Déjà noté, et refait aussi.

## À retenir

- Écrire un mécanisme sur l'objet le plus simple avant de le mettre sur ceux qui comptent.
- Le CSG coûte quand il bouge. Pour un décor fixe, on le paie une fois.
- L'ordre des enfants d'un `CSGCombiner3D` fait partie de la scène.
- Un test ne voit pas qu'un fer à cheval est à l'envers.
