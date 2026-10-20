# Tokyo · étape 012 · La rue : parcelles étroites, hauteurs libres

**Piste : Variation.** Un second script, `…_rue.gd`, fabrique une rue entière : il découpe sa
longueur en parcelles, crée un immeuble par parcelle et règle ses variables par des tirages.
Il ne dessine aucun mur. Il pose aussi ce qui appartient à la rue elle-même : la chaussée,
les poteaux électriques et leurs fils.

Ce qu'on obtient par défaut : une rue de 80 m sur 6 m de large, 35 immeubles sur ses deux
côtés, 45 318 triangles.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5 : la visite part du bout de la rue.
Appuyer sur N : les enseignes, les fenêtres et les lampes des poteaux s'allument.

Deux scènes se règlent dans l'inspecteur :

- `{NAME}_rue.tscn` : la rue. Changer `street_width` et regarder les toits ;
- `{NAME}.tscn` : un immeuble seul, comme aux étapes précédentes.

Pour visiter un immeuble seul : lancer `2_sequence/step_viewer/step_viewer_immeuble.tscn`
(F6 une fois la scène ouverte).

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Un seul fichier à lire, `…_rue.gd` : il est
entièrement nouveau. La palette gagne deux cotes du règlement et les deux listes de teintes
où la rue tire ; le test gagne une vérification.

## Ce qu'on a fait, dans l'ordre

### 1. Un générateur fait d'un autre générateur

L'immeuble des étapes 001 à 011 a trente-trois variables. La rue ne sait rien de ses
fenêtres ni de ses balcons : elle ne connaît que ces variables.

```gdscript
		var building: Building = Building.new()
		building.bay_count = bays
		building.bay_width = bay_width
```

`Building` est le script de l'immeuble, chargé par `preload`. `Building.new()` crée un
immeuble comme le ferait l'éditeur. On règle ses variables, puis :

```gdscript
		_root.add_child(building)
```

`add_child()` déclenche le `_ready()` de l'immeuble, donc sa construction : toutes ses
variables doivent être réglées **avant**.

C'est la leçon de l'étape. Un générateur bien paramétré devient la brique d'un générateur
plus grand. Tout le travail des onze premières étapes se résume ici à une ligne.

### 2. Découper la rue en parcelles : `_draw_lots()`

```gdscript
		var bays: int = random.randi_range(min_bays, maxi(min_bays, max_bays))
		var bay_width: float = snappedf(random.randf_range(BAY_WIDTH_MIN, BAY_WIDTH_MAX), 0.05)
		var gap: float = random.randf_range(minf(min_gap, max_gap), max_gap)
```

Une parcelle, c'est trois nombres : un nombre de travées, une largeur de travée, et
l'interstice qui la sépare de la suivante. On en tire jusqu'à remplir la longueur. La
dernière prend tout ce qui reste, sans interstice : la somme tombe juste, au millimètre.

Les parcelles sont étroites : une à trois travées, soit de 2 m à 8 m de façade. Seule la
dernière de chaque côté peut être plus large, puisqu'elle prend le reste.

### 3. Pas de murs mitoyens

L'interstice est la première différence avec une rue parisienne, où les immeubles se
touchent. Au Japon, le code civil (article 234) demande de bâtir à 50 cm au moins de la
limite de sa parcelle : deux voisins qui s'y tiennent sont séparés d'un mètre. Dans les
quartiers classés contre l'incendie, un mur extérieur résistant au feu peut aller jusqu'à la
limite, et les immeubles se touchent presque. La rue tire donc l'interstice entre deux
bornes : `min_gap`, 5 cm, et `max_gap`, un mètre par défaut.

```gdscript
@export_range(0.0, 2.0, 0.01, "suffix:m") var max_gap: float = 2.0 * Palette.BOUNDARY_DISTANCE
```

Les 50 cm du code civil sont dans la palette, et la valeur par défaut de la variable en est
un calcul. Le nombre du règlement n'est écrit qu'à un seul endroit.

Source : question d'un géomètre-expert (土地家屋調査士) sur les limites de propriété, qui cite
les deux textes, <https://smtrc.jp/useful/qa/kyokaihikai/qa-kyokaihikai_06.html>, lu le
11 octobre 2026. Le numéro de l'article de la loi sur les normes de construction n'y est pas
donné.

Conséquence pour le maillage : les murs latéraux se voient. C'est pour eux que le béton de
l'étape 009 a été écrit.

### 4. Des hauteurs libres

Seconde différence. À Paris, la rue impose une hauteur de façade à tous. Ici, la rue
n'impose rien : chaque immeuble tire son nombre d'étages.

```gdscript
	building.floor_count = random.randi_range(min_floors, maxi(min_floors, max_floors))
```

Environ un tiers des immeubles sont des bureaux, un tiers des logements, un tiers mêlent les
deux. La ligne de toits est en dents de scie.

### 5. Le gabarit : la rue ne calcule rien

```gdscript
		building.road_width = street_width
		building.slope_zone = slope_zone
```

La seule règle commune est le gabarit oblique de l'étape 009, qui dépend de la largeur de la
voie. La rue ne fait aucun calcul : elle donne sa largeur et sa zone à chaque immeuble, et
c'est l'immeuble qui recule ses étages, ou renonce à ceux qui n'ont plus la place.

Une rue de 6 m, avec une pente de 1,5, permet 9 m de haut à l'alignement : le
rez-de-chaussée et un étage. Tout ce qui dépasse recule. Dans la rue par défaut,
29 immeubles sur 35 ont des étages en retrait. Élargir la rue à 12 m (18 m de haut à
l'alignement) redresse les façades, sans changer une ligne du script de l'immeuble.

La loi demande 4 m de largeur au moins pour une voie ; c'est le minimum de `street_width`,
lu lui aussi dans la palette. Les ruelles plus étroites existent, mais on doit alors bâtir à
2 m de leur axe : le cours ne le modélise pas.

Source : arrondissement d'Ōta, « 2項道路 »,
<https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/k_douro/douro.html>, lu le
11 octobre 2026.

### 6. Un dé par immeuble

```gdscript
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = hash([variation_seed, "immeuble", side, index])
```

La graine de chaque immeuble dépend de la graine de la rue, du côté et du rang. Allonger la
rue ajoute des immeubles au bout sans changer les autres, sauf le dernier de chaque côté,
qui avait pris le reste de la longueur. En passant de 80 m à 150 m : 33 immeubles sur
35 restent identiques, variable pour variable. C'est la réponse au problème de l'étape 011 :
des tirages indépendants demandent des dés séparés.

Les parcelles ont leur propre dé, lui aussi : `hash([variation_seed, "parcelles", side])`.

Dans chaque immeuble, la règle de l'étape 011 tient toujours : le nombre de tirages ne
dépend jamais d'un tirage. Une cote est tirée avant de savoir si elle servira :

```gdscript
	var balcony: float = snappedf(random.randf_range(0.9, 1.3), 0.05)
	building.balcony_depth = balcony if random.randf() < 0.85 else 0.0
```

Un piège : `a and b` n'évalue pas `b` quand `a` est faux. Le dé se lance donc en premier :

```gdscript
	building.penthouse = random.randf() < 0.8 and building.floor_count >= 2
```

Ainsi, passer `max_floors` de 5 à 10 change la hauteur des immeubles sans tirer une autre
rue : les 35 immeubles gardent leur revêtement, leur teinte et leur boutique. Une exception à
connaître : quand ses deux bornes sont égales, `randi_range()` n'a rien à tirer, et il ne
lance pas le dé. Avec `min_floors` égal à `max_floors`, les tirages suivants se décalent.

### 7. Tirer l'aspect : `_apply_aspect()`

Cette fonction règle une vingtaine de variables de l'immeuble. Trois façons de faire :

- **tirer une valeur dans une liste de la palette** : la teinte du revêtement, celle de
  l'aluminium ;
- **tirer avec une probabilité** : `random.randf() < shop_share` ;
- **laisser faire l'immeuble** : pour ce qu'il sait tirer lui-même, la rue met la variable
  sur « Selon la graine » (0) et lui donne une graine.

```gdscript
	building.core_side = 0
	building.variation_seed = random.randi_range(0, 1000000)
```

Certains tirages dépendent d'un autre : un édicule seulement si l'immeuble a au moins deux
étages, un panneau sur le toit seulement s'il en a quatre.

### 8. Le sol : des bandes côte à côte

Sans trottoir, la chaussée va de façade à façade. De chaque côté : un caniveau de béton au
pied des immeubles, puis une ligne blanche qui réserve une bande aux piétons.

Ces bandes ne sont pas posées **sur** la chaussée. Elles sont posées **à côté** d'elle : la
chaussée s'arrête où la ligne commence. Deux faces l'une sur l'autre, à quelques millimètres
d'écart, se disputent les mêmes pixels dès qu'on s'éloigne : la carte graphique mesure la
profondeur de moins en moins finement avec la distance.

Avec `sidewalk_width` au-dessus de zéro, la rue a des trottoirs et une bordure, comme à
Paris.

### 9. Les poteaux : un objet par poteau

Chaque poteau est un nœud à part, avec son propre outil de maillage :

```gdscript
		var mesh: MeshBuilder = MeshBuilder.new()
		var holder: Node3D = Node3D.new()
		mesh.cone(Vector3(0.0, 0.5 * POLE_HEIGHT, 0.0), 0.17, 0.11, POLE_HEIGHT, concrete, Basis.IDENTITY, 10)
```

Le poteau est un `cone()` dont le rayon du haut est plus petit que celui du bas, comme pour
la lanterne de l'étape 010. Ses traverses, ses isolateurs et son transformateur sont des
boîtes et des cylindres.

Pourquoi un outil par poteau, et non un seul pour tous ? L'étape 013 fera disparaître les
petites pièces avec la distance. Il faut pour cela que chaque poteau soit un objet, qui ait
sa propre distance à la caméra.

Les cotes (11 m de haut, un poteau tous les 30 m) sont plausibles ; elles ne sont pas
relevées.

### 10. Les fils : une courbe en segments

Un fil qui pend dessine une courbe. On l'approche par huit segments droits :

```gdscript
		var point: Vector3 = from + Vector3(t * span, -4.0 * sag * t * (1.0 - t), 0.0)
		var segment: Vector3 = point - previous
		var tilt: Basis = Basis(Vector3.BACK, atan2(segment.y, segment.x))
		mesh.box(Vector3(segment.length() + 0.01, thickness, thickness), 0.5 * (previous + point), material, tilt)
```

`-4.0 * sag * t * (1.0 - t)` est une parabole : nulle aux deux bouts, `sag` au milieu.
Chaque segment est une boîte fine, tournée dans la pente de la courbe : `box()` accepte une
orientation en dernier argument, comme pour les jambes de force du panneau de toit
(étape 010). `atan2()` donne l'angle de la pente, et `Basis(axe, angle)` la rotation autour
de l'axe qui traverse la rue.

Onze fils par portée : trois sur chaque traverse, trois de basse tension, deux câbles de
téléphone plus gros et plus bas.

### 11. Les lampes : de vraies lumières

Chaque poteau porte une lampe. C'est la seule vraie lumière de la scène, après le soleil :

```gdscript
		var lamp: OmniLight3D = OmniLight3D.new()
		lamp.shadow_enabled = false
		lamp.visible = false
```

Elle n'a pas d'ombre : une lampe à ombres redessine tout ce qui l'entoure. `set_night()`
rend les lampes visibles et allume leur globe, dont le matériau a une émission.

Les fenêtres et les enseignes, elles, n'éclairent rien : leur lumière est peinte. Trois
lampes suffisent à éclairer la chaussée ; les quelque 260 fenêtres et vitrines de la rue n'en ont
pas besoin.

### 12. Vérifier

Le test de l'étape charge la rue et demande à chacun de ses immeubles sa marge sous le
gabarit (`get_slope_margin()`, étape 009) :

```text
ok        gabarit oblique : 35 immeuble(s), marge la plus faible 0.0 m
```

Aucun ne perce la ligne. La rue a aussi été montée avec des réglages extrêmes : 4 m et 25 m
de large, 30 m et 300 m de long, un seul côté, douze étages demandés partout, des bornes
inversées. Dix-huit cas, aucune erreur, des parcelles qui tombent toujours juste.

## Ce qu'il faut retenir

1. Un générateur bien paramétré est la brique d'un générateur plus grand.
2. Régler toutes les variables avant `add_child()`.
3. Une règle commune peut être appliquée par chaque objet : la rue donne une largeur,
   l'immeuble fait le calcul.
4. Un nombre du règlement s'écrit une fois, dans la palette ; une variable peut en tirer sa
   borne ou sa valeur par défaut.
5. Un dé par objet, dont la graine dépend de son rang : les tirages sont indépendants. Et
   dans chaque objet, un nombre de tirages qui ne dépend pas du hasard.
6. Ne jamais poser deux faces l'une sur l'autre.
7. Peu de vraies lumières ; le reste se peint.

## À essayer

- `street_width` à 4, puis à 12, puis à 20 avec `max_floors` à 10.
- `max_floors` à 10 dans la rue de 6 m : les immeubles montent, en reculant, et gardent leur
  boutique.
- `slope_zone` : « Zone d'habitation ».
- `sidewalk_width` à 2 avec `street_width` à 12.
- `min_gap` et `max_gap` à 0 : des immeubles mitoyens, comme à Paris.
- `max_bays` à 6 : de grandes parcelles.
- `variation_seed` : une autre rue. `street_length` à 150 : les premiers immeubles restent.
- `two_sides` à faux, et reculer pour voir la ligne de toits.
- `poles` à faux : la rue perd une bonne part de son caractère.
{TWIN}
## Limites

- Pas de carrefour, pas d'angle de rue, pas de façade arrière.
- Les poteaux sont d'un seul côté, et aucun fil ne va des poteaux aux immeubles.
- Le distributeur de boissons est posé devant la façade, donc sur la voie : dans la réalité,
  il serait dans un retrait de l'immeuble.
- Le nombre d'étages est tiré librement. Dans la réalité, d'autres règles le bornent aussi,
  dont la surface de plancher permise ; le cours ne les modélise pas.

## Étape suivante

013 : les niveaux de détail. De loin, les enseignes n'ont plus besoin de vrai texte, ni les
balcons de barreaux, ni les poteaux de fils.
