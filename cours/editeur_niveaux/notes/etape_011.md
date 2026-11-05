# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une salle de combat ne vaut que par sa rencontre : d'où entre le héros, où apparaissent les
ennemis, et lesquels. Le jeu tire ses vagues parmi les ennemis que la salle autorise, et les fait apparaître sur des
points qui acceptent leur rôle. L'éditeur doit donc montrer ces points, laisser choisir les ennemis parmi les vraies
définitions du jeu, et refuser une rencontre que le jeu ne pourrait pas jouer.

Ce qu'on obtient : un mode « Apparitions ». Le départ du héros (H, en vert) et les points d'apparition (C au contact,
D à distance, T pour tous) se tirent à la souris ; Ctrl+clic ajoute un point, R change son rôle, Suppr le retire. À
droite, la rencontre : la profondeur de la salle et les ennemis cochés. Une salle qui cite un ennemi inconnu, ou un
ennemi sans point de son rôle, ne s'enregistre pas.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 ; choisir le mode « Apparitions » ; tirer le H ; décocher « Tireur » dans la rencontre ; Ctrl+Z.
3. `5_data/ennemis/` : les sept définitions, modifiables dans l'Inspecteur.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les ennemis, des données du jeu

`1_core/data/enemy_def.gd` décrit un type d'ennemi : rôle (au contact ou à distance), santé, repère, vitesse, portée,
cadence de l'attaque (préparation, coup, récupération), poids dans le plafond des vagues, dégâts. Les sept définitions de
`5_data/ennemis/` sont celles que le jeu fera vivre : l'éditeur ne les recopie pas, il les lit. Ajouter un ennemi au jeu,
c'est ajouter un fichier ; il apparaît aussitôt dans la rencontre de l'éditeur.

`1_core/editor/definition_folder.gd` charge toutes les définitions d'un dossier, triées par identifiant, en vérifiant
que chaque fichier a bien le script attendu : un fichier d'une autre famille posé là par erreur est signalé, pas ignoré
en silence. Il servira aussi aux effets et aux animations.

### 2. Une rencontre jouable

`EnemyDef.pool_errors(salle, ennemis)` dit ce qui empêcherait le jeu de jouer la rencontre : un ennemi de la rencontre
que le jeu ne connaît pas, ou un ennemi dont aucun point d'apparition n'accepte le rôle (`ROLES` : un ennemi au contact
apparaît sur un point « melee » ou « tous »). La coquille l'ajoute aux contrôles d'enregistrement ; le panneau de la
rencontre l'affiche sous la liste, au fur et à mesure. Le générateur des salles d'exemple vérifie la même règle à la
fabrication : il ne compte pas sur le tirage au hasard des rôles.

### 3. Tirer les points

`4_ui/editor/spawn_input.gd` suit le même schéma que les collisions : il cherche le point le plus proche dans un rayon
donné en pixels (converti en mètres), montre un aperçu pendant le glisser, et confie un seul changement au document au
relâchement. Ajouter ou retirer un point change deux colonnes à la fois (positions et rôles) : `set_room_fields` les
reçoit ensemble, en un pas, et `validate()` vérifie qu'elles ont la même longueur.

### 4. Le panneau de la rencontre

`4_ui/editor/encounter_panel.gd` : un `SpinBox` pour la profondeur, une case par ennemi (nom, rôle, santé, poids).
Cocher ou décocher change la rencontre ; une annulation recoche la case : le panneau se recale sur le document à
chaque changement, sans renvoyer de signal (`set_pressed_no_signal`). En mode « Apparitions », il prend la place de
l'inspecteur.

### 5. Le calque des apparitions

`4_ui/editor/spawn_view.gd` dessine le départ du héros et chaque point de la couleur de son rôle, avec son initiale
(`draw_string`, avec la police par défaut du thème) ; le point choisi est cerclé (`draw_arc`).

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, mode « Apparitions » : retirer tous les points « distance » et « tous » de la soute, puis Ctrl+S : refusé, avec la
  raison.
