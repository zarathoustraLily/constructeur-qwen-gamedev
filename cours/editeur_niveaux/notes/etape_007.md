# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La demande : « un carré bleu autour du sprite pour le manipuler comme sur Photoshop, pour le scaler
ou le faire tourner ou le déplacer, et choisir son niveau de profondeur ». On la découpe en trois parties qui ne se
mélangent pas : la géométrie du cadre (où sont les poignées, ce que donne un glisser), le dessin du cadre, et la
souris. Les gestes eux-mêmes existent déjà (étape 5) : le cadre ne fait que les appeler.

Ce qu'on obtient : F5, un clic sur un obstacle l'entoure d'un cadre bleu ; on le déplace en tirant l'intérieur, on
l'agrandit par un coin, on le tourne par la poignée ronde au-dessus ; Ctrl aimante ; Maj+clic ajoute ou retire une
chose ; glisser dans le vide trace un rectangle de sélection ; Page haut et Page bas changent sa profondeur (avec Ctrl :
devant ou derrière tout son calque). Ctrl+Z annule chaque geste en une fois.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5, puis cliquer sur un obstacle du hangar, et tirer ses poignées.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La géométrie du cadre, sans nœud

`1_core/editor/transform_gizmo.gd` ne dessine rien et ne lit aucune souris : c'est de la géométrie, qui se teste en
quelques lignes. À partir du rectangle de la sélection à l'écran (`box`), il place quatre poignées d'angle et une
poignée de rotation au-dessus du milieu, dit ce qui se trouve sous un point (`hit_test` : une poignée, l'intérieur du
cadre, ou rien), puis traduit un glisser :
- une poignée d'angle donne un **facteur d'échelle** : la distance au centre du cadre à l'arrivée, divisée par la
  distance au départ ; tirer un coin deux fois plus loin du centre double l'échelle ;
- la poignée ronde donne un **angle** : celui que le curseur a parcouru autour du centre (`Vector2.angle_to`) ;
- l'intérieur donne un **déplacement**.
Les tailles des poignées et la couleur du cadre viennent des réglages.

### 2. Un aperçu, puis un seul geste

Pendant qu'on tire, la chose doit suivre la souris ; mais chaque petit mouvement ne doit pas devenir un pas
d'annulation. La vue sait donc montrer un **aperçu** (`set_preview`) : les choses sélectionnées déplacées, tournées ou
agrandies autour du centre du groupe, sans que le document change. Au relâchement, `SelectionInput` confie **un seul**
geste à `EditorActions` (`move`, `rotate` ou `scale_by`), puis efface l'aperçu. Le test
`test_tirer_l_interieur_deplace_en_un_pas_avec_un_apercu` vérifie les deux : pendant le glisser, la chose a bougé à
l'écran mais pas dans le document ; après, elle a bougé dans le document, et un seul Ctrl+Z la ramène.

Le calcul de l'aperçu suit la même règle que les gestes : déplacer, puis tourner et agrandir autour du centre du
groupe. Pour une chose seule, le centre est sa propre position : elle tourne sur elle-même.

Une variable `position`, `rotation` ou `scale` dans la vue aurait masqué les propriétés du `Control` : avec les
avertissements traités en erreurs, le script ne se chargerait plus. Les noms choisis (`place_m`, `turn_deg`,
`factor_now`) l'évitent.

### 3. Sélectionner à la souris

La vue sait dire quelle chose est sous un point (`thing_at`) : on parcourt les choses de la plus haute à la plus basse,
et la première dont l'emprise tournée contient le point gagne (`Geometry2D.is_point_in_polygon`). Le sol est verrouillé
(`locked_layers`) : sinon chaque clic dans le vide prendrait une dalle, et chaque rectangle en prendrait des dizaines.
`things_in` rend ce qu'un rectangle touche.

### 4. La souris, traduite en commandes

`4_ui/editor/selection_input.gd` écoute `gui_input` de la vue. Un appui sur une poignée commence un glisser du cadre ;
ailleurs, c'est un clic en attente. Au-delà de quelques pixels (`drag_threshold_px`), un clic en attente devient un
rectangle de sélection. Au relâchement : le geste, la sélection du rectangle, ou le clic. Les touches de profondeur
n'arrivent qu'à une vue qui a le focus : le script lui donne `FOCUS_ALL` à l'installation, et la vue prend le focus à
chaque appui ; sans cela, `grab_focus()` écrirait un avertissement à chaque clic.

### 5. Le dessin du cadre

`4_ui/editor/selection_overlay.gd` est un calque posé sur la vue, qui laisse passer la souris (`MOUSE_FILTER_IGNORE`) :
le cadre bleu, ses quatre poignées pleines, la poignée ronde reliée au haut du cadre, et le rectangle de sélection en
cours, en bleu transparent. Il redessine quand le script de la souris le lui dit (`overlay_changed`).

### 6. La coquille assemble

La coquille crée la sélection et les gestes, et installe les deux nouveaux nœuds. Après une suppression ou une
annulation, elle retire de la sélection ce qui n'existe plus (`retain`).

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : un clic entoure un obstacle d'un cadre bleu ; les coins l'agrandissent, la poignée ronde le tourne, l'intérieur
  le déplace ; Page haut le passe devant ses voisins.
