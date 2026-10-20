# Paris · étape 012 · La rue : parcelles, gabarit, régularité

**Piste : Variation.** C'est la dernière étape de construction. L'immeuble des étapes 001 à 011 sait tout
faire seul : une façade, des balcons, un toit, des boutiques, et un immeuble différent à
chaque graine. On n'y touche plus. On écrit un second générateur, la rue, qui se sert du
premier comme d'une brique.

Ce projet contient donc tout : **les façades parisiennes et la rue**.

> **Cette rue est juste, mais elle est lourde.** Chaque immeuble y est dessiné en entier à
> toute distance. L'étape 013 y remédie : niveaux de détail, ombres, finesse des shaders. Pour
> se servir de la rue, prendre le projet de l'étape 013 ; celui-ci montre comment elle est
> faite.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`). Le code utilise des
   fonctions apparues avec Godot 4.4 : il ne tournera pas sur une version plus ancienne.
2. Lancer avec F5 : on est dans la rue, à hauteur d'homme.
3. Clic droit maintenu et souris : regarder. ZQSD : se déplacer. A et E : descendre, monter.
   Maj : aller vite. **N** : jour ou nuit. **F** : recadrer. Échap : quitter.

Deux scènes de visite, dans `2_sequence/step_viewer/` :

| Scène | Ce qu'elle montre |
|---|---|
| `step_viewer.tscn` | La rue. C'est la scène principale. |
| `step_viewer_immeuble.tscn` | Un immeuble seul. L'ouvrir, puis F6. |

Pour régler les variables : ouvrir dans l'éditeur la scène de la rue
(`{NAME}_rue.tscn`) ou celle de l'immeuble (`{NAME}.tscn`), cliquer sur le nœud racine,
changer une variable dans l'inspecteur. Tout se reconstruit aussitôt, sans lancer le jeu.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Tous les fichiers de l'immeuble portent le
numéro 012 ; la dernière colonne dit lesquels ont réellement changé à cette étape : la rue
(nouvelle), la palette (agrandie) et le test (une scène de plus).

## Ce qu'on a fait, dans l'ordre

Tout est dans `{NAME}_rue.gd`. Les passages cités ci-dessous y sont commentés ligne à ligne.

### 1. Un générateur devient une brique

La rue ne fabrique aucun triangle d'immeuble. Elle crée des nœuds « immeuble », règle leurs
variables, et les laisse se construire :

```gdscript
const Building := preload("res://6_assets/Mesh/Procedural/DECORS/Building/{NAME}.gd")

var building: Building = Building.new()   # un nœud qui porte le script de l'immeuble
building.bay_count = 5                    # ses variables : les mêmes que dans l'inspecteur
building.stone_color = Color(0.95, 0.92, 0.86)
_root.add_child(building)                 # add_child() appelle son _ready(), donc rebuild()
```

Deux choses à remarquer :

- `Building` est une constante qui contient un script. Elle sert aussi de type :
  `var building: Building`. L'éditeur connaît alors ses variables et signale une faute de
  frappe dans leur nom.
- **L'ordre compte** : toutes les variables sont réglées avant `add_child()`. L'immeuble n'est
  ainsi construit qu'une fois.

C'est possible parce que l'immeuble a été écrit, depuis l'étape 001, comme une fonction de ses
variables : mêmes variables, même immeuble. La rue ne sait rien des fenêtres.

### 2. Découper la longueur en parcelles : `_draw_lots()`

On avance le long de la rue en tirant, pour chaque parcelle, un nombre de travées (entre
`min_bays` et `max_bays`) et une largeur de travée (entre 2,30 et 2,90 m). Le seul piège est
la fin : si ce qui resterait après une parcelle est trop étroit pour un immeuble, cette
parcelle prend tout le reste, et on recalcule sa largeur de travée pour tomber juste.

```gdscript
if remaining - width < narrowest:
	bays = clampi(roundi(remaining / 2.6), 1, 12)
	bay_width = remaining / float(bays)
	width = remaining
```

La somme des largeurs vaut donc exactement la longueur de la rue : pas de trou, pas de
dépassement.

### 3. Le gabarit : la largeur de la voie fixe la hauteur des façades

À Paris, la hauteur d'une façade dépend de la largeur de la rue. La table est une donnée, pas
du code : elle est dans `5_data`, dans `{NAME}_palette.gd`.

| Largeur de la voie | Hauteur maximale de la façade |
|---|---|
| moins de 7,80 m | 11,70 m |
| de 7,80 à 9,75 m | 14,62 m |
| de 9,75 à 20 m | 17,55 m |
| 20 m et plus | 20 m |

`facade_height_limit()` lit cette table. Changer `street_width` de 12 à 20 m ajoute un étage
à toute la rue.

### 4. Remplir le gabarit : `_draw_storeys()` et `_fit_storeys()`

On tire des hauteurs d'étage plausibles, puis on cherche combien d'étages courants tiennent
sous le gabarit, et on étire ou on tasse un peu le tout pour arriver juste dessous. Deux
garde-fous : aucun étage ne descend sous 2,60 m (on en retire plutôt un), et on n'étire pas
de plus de 6 %.

Le résultat est rangé dans une petite classe, `Storeys`, qui ne contient que des nombres.
`_apply_storeys()` les recopie dans les variables de l'immeuble.

### 5. La régularité : `_mix_storeys()`

Dans un îlot haussmannien, les balcons et les corniches filent d'un immeuble à l'autre. On
l'obtient en tirant **une seule fois** des hauteurs d'étage pour toute la rue (`common`), et
en les donnant à tous les immeubles.

La variable `regularity` règle la part des immeubles qui suivent ces hauteurs communes. Les
autres tirent les leurs, sous un gabarit un peu plus bas : ce sont les immeubles plus anciens
ou plus modestes, qui cassent la ligne.

- `regularity = 1` : toutes les lignes sont continues ;
- `regularity = 0` : chaque immeuble a ses hauteurs.

### 6. L'aspect : `_apply_aspect()`

Tout ce qui distingue un immeuble de son voisin est tiré ici : teinte de la pierre, suie,
zinc, porte, menuiseries, ornement, balcons, pente du comble. Les teintes viennent des listes
de la palette.

Un tirage n'est pas forcément uniforme. `clean_share` est la part des façades ravalées : une
façade ravalée tire sa pierre parmi les trois teintes les plus claires, avec très peu de suie
et un zinc clair ; les autres tirent dans le reste de la liste. On tire d'abord la famille,
puis la valeur dans la famille : c'est ce qui évite les mélanges absurdes, comme une pierre
blanche couverte de suie.

Ce que l'immeuble sait tirer seul (forme de la porte, motif des garde-corps, lucarnes,
boutiques) n'est pas tiré ici : la rue lui donne seulement une graine, `variation_seed`.

### 7. Un dé par immeuble

```gdscript
var random: RandomNumberGenerator = RandomNumberGenerator.new()
random.seed = hash([variation_seed, "immeuble", side, index])
```

Chaque immeuble a son propre générateur, dont la graine dépend de la graine de la rue, du
côté et du rang. Si un seul dé servait à toute la rue, allonger la rue ou ajouter un tirage
dans un immeuble décalerait tous les suivants : toute la rue changerait.

Même idée dans `_mix_storeys()` : le dé est lancé même quand son résultat ne sert pas, pour
que bouger `regularity` ne change pas la couleur des pierres.

### 8. Poser les immeubles : `_build_side()`

- Le côté -1 est en z négatif et regarde vers +Z : l'immeuble est posé tel quel.
- Le côté +1 est en face : l'immeuble fait demi-tour (`rotation.y = PI`).
- Deux voisins sont décalés de quelques millimètres en profondeur (`FACADE_STAGGER`). Leurs
  corniches se recouvrent un peu ; posées exactement dans le même plan, elles se
  disputeraient les mêmes pixels et l'image scintillerait.

### 9. Le sol : `_build_ground()`

Des boîtes, avec l'outil de maillage de `1_core` : la chaussée, deux trottoirs, deux bordures.
Le dessus des trottoirs est à y = 0, le sol des immeubles ; la chaussée est 14 cm plus bas.

### 10. La nuit

`set_night()` transmet la valeur à chaque immeuble, et la garde pour la redonner après une
reconstruction.

## Les variables de la rue

| Groupe | Variable | Effet |
|---|---|---|
| Voie | `street_length` | Longueur de la rue. |
| | `street_width` | Largeur de façade à façade. Fixe la hauteur des façades. |
| | `sidewalk_width` | Largeur de chaque trottoir. |
| | `two_sides` | Deux faces, ou une seule. |
| Parcelles | `min_bays`, `max_bays` | Largeur des immeubles, en travées. |
| | `regularity` | Part des immeubles alignés sur les hauteurs de la rue. |
| Aspect | `shop_share` | Part des immeubles à boutiques. |
| | `clean_share` | Part des façades ravalées. |
| | `variation_seed` | Change tous les tirages. |

## Les variables d'un immeuble

| Groupe | Variables |
|---|---|
| Plan | `bay_count`, `bay_width`, `depth` |
| Niveaux | `ground_height`, `entresol`, `entresol_height`, `noble_height`, `floor_count`, `floor_height`, `top_floor`, `top_floor_height` |
| Rez-de-chaussée | `door_bay`, `door_style`, `door_width`, `shops`, `showcase_share`, `awnings` |
| Façade | `window_width`, `noble_balcony`, `top_balcony`, `balcony_window_bonus`, `ornament`, `railing_motif`, `rusticated_base`, `course_height` |
| Comble | `brisis_angle`, `brisis_length`, `dormers`, `dormer_style`, `chimneys` |
| Aspect | `stone_color`, `soot`, `zinc_brightness`, `door_color`, `frame_color`, `variation_seed` |

Chacune est décrite dans l'inspecteur, au survol, et en tête de `{NAME}.gd`.

## Ce qu'il faut retenir

1. Un générateur dont tout passe par des variables devient la brique d'un générateur plus grand.
2. Les règles d'un style (ici le gabarit et la régularité) font plus pour le résultat que le
   détail : ce sont elles qui font qu'on reconnaît une rue de Paris.
3. Les listes et les tables sont des données : elles vont dans `5_data`.
4. Un dé par objet, avec une graine tirée de la graine du parent : ce qu'on ajoute ne décale
   pas ce qui existe.

## À essayer

Dans la scène `{NAME}_rue.tscn`, sur le nœud racine :

- `street_width` à 12 : la rue perd un étage. À 8 : encore un.
- `regularity` à 0, puis à 1.
- `clean_share` à 1 : une rue ravalée. À 0 : une rue grise.
- `two_sides` décoché, `street_length` à 300 : une longue face de rue.
- `variation_seed` : une autre rue à chaque valeur.
- Dans `{NAME}_palette.gd` : ajouter une teinte à `STONE_COLORS`, relancer.
{TWIN}
## Poids, mesuré

Sur la rue par défaut (110 m, deux faces, 16 immeubles), dans Godot 4.7.2, sur une machine
lente à deux cœurs :

| | Un immeuble de 5 travées | La rue |
|---|---|---|
| Triangles | 12 443 | 176 282 |
| Objets dessinés | 21 | 316 |
| Temps de montage | environ 30 ms | environ 450 ms |

Chaque immeuble a ses propres matériaux, soit une vingtaine d'objets dessinés par immeuble, et
il est dessiné en entier à toute distance : c'est ce que corrige l'étape 013.

Le temps d'affichage sur une vraie carte graphique n'a pas été mesuré : le projet a été rendu
en logiciel. Le compteur en haut de l'écran le donne sur la machine où le projet tourne. **R** baisse la
résolution du rendu 3D, **V** coupe la synchro verticale.

## Ce qui a été vérifié

- Le projet s'importe sans erreur dans Godot 4.7.2 et tous ses scripts passent la vérification
  du moteur.
- Le test de `7_tests` passe : l'immeuble et la rue se construisent, et se reconstruisent à
  l'identique.
- La rue a été montée avec des réglages ordinaires et extrêmes (largeur de 6 à 40 m, longueur
  de 30 à 300 m, régularité 0 et 1, une ou deux faces, `min_bays` plus grand que `max_bays`).
  Dans tous les cas : aucune erreur, les parcelles remplissent exactement la longueur, aucune
  façade ne dépasse le gabarit.
- L'immeuble de ce projet a été comparé à celui livré avant le cours, dans la même scène et
  avec la même caméra : même nombre de triangles, et la même image à 0,4 % des pixels près,
  tous au bord des fenêtres (leur shader a été réécrit plus simplement).
- La rue a été rendue avec les trois moteurs de rendu de Godot : Compatibilité, Forward+ et
  Mobile.
- Le projet s'ouvre dans l'éditeur sans écran, sur la scène de la rue, sans erreur.

Ce qui n'a pas pu l'être : le rendu sur une vraie carte graphique, et les réglages faits à la
souris dans l'inspecteur. La reconstruction a été testée par script.

## Limites

- Des façades droites : pas d'immeuble d'angle, pas de carrefour, pas de façade sur cour.
- Pas d'arbres, de réverbères ni de mobilier urbain. Le sol est uni.
- Les cotes sont plausibles, elles ne sont pas relevées sur des immeubles réels.
- Les enseignes utilisent la police par défaut de Godot.
- La pièce derrière une vitre est rendue par l'émission : elle ne reçoit ni les ombres ni les
  lumières de la scène.

## Sources

- Gabarit, le principe : Commission du Vieux Paris, « Avis sur les surélévations »,
  8 juin 2016 : la hauteur des façades est « proportionnée à la largeur des rues » depuis les
  déclarations royales de 1783-1784.
  <https://cdn.paris.fr/paris/2019/07/24/96c7fb6b51d8031da44957cc76cf6b48.pdf>
- Gabarit, le palier de 1859 : Ville de Paris, document sur le secteur sauvegardé du Marais,
  chapitre III.6 « Le XXe siècle », p. 260 : « le règlement de 1859 autorisant le relèvement
  de la corniche de 17, 54 à 20 mètres ».
  <https://cdn.paris.fr/paris/2020/02/26/a4878f9d14006d1dcb7c244500153fa5.pdf>
- Gabarit, les paliers de 11,70 et 14,62 m, leurs largeurs de voie, la diagonale à 45° des
  combles et l'étage d'au moins 2,60 m : source de seconde main, Wikipédia, « Règlements
  d'urbanisme de Paris », qui cite B. Landau (« La fabrication des rues de Paris au
  XIXe siècle ») et C. Mignot (*Grammaire des immeubles parisiens*, Parigramme, 2004). Ces
  chiffres n'ont pas été retrouvés dans un texte d'institution.
- Régularité : Cité de l'architecture et du patrimoine, fiche de la maquette « L'immeuble
  1, boulevard Saint-Michel, 1860 » : « les lignes de balcons et des séparations d'étages
  forment des lignes continues d'un immeuble à l'autre », balcons « aux deuxième et cinquième
  étages ».
  <https://www.citedelarchitecture.fr/sites/default/files/documents/2017-09/fo_boulevardsaintmichel_def.pdf>
- Composition de la façade : Cité de l'architecture et du patrimoine, « Bricol'archi :
  l'immeuble haussmannien », 2021.
  <https://www.citedelarchitecture.fr/sites/default/files/documents/2021-04/bricolarchi_immeuble_haussmannien_v2.pdf>

## Les étapes qui mènent ici

Chacune a son projet Godot, dans un dossier voisin de celui-ci.

| N° | Piste | Ce qu'on y construit |
|---|---|---|
| 001 | Building | Un mur percé de baies |
| 002 | Shader | Pierre de taille : assises et joints |
| 003 | Shader | Le bruit : teinte par bloc, suie, relief |
| 004 | Building + Shader | Fenêtres à petits bois |
| 005 | Shader | Une pièce derrière la vitre, la nuit |
| 006 | Building | Niveaux : soubassement, étage noble, dernier étage |
| 007 | Building + Shader | Balcons filants et ferronnerie |
| 008 | Building | Moulures par profils extrudés |
| 009 | Building + Shader | Comble en zinc, lucarnes, cheminées |
| 010 | Building + Shader | Porte, boutiques, enseignes |
| 011 | Variation | La graine : un immeuble différent à chaque tirage |
| 012 | Variation | La rue (ce projet) |
| 013 | Performance | Niveaux de détail : ne dessiner que ce qui se voit |
