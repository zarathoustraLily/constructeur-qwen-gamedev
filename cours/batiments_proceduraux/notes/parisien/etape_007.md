# Paris · étape 007 · Balcons filants et ferronnerie

**Pistes : Building et Shader.** Deux balcons courent sur toute la façade, à l'étage noble et
au dernier étage. Leur dalle est de la géométrie. Leur garde-corps est un rectangle, sur
lequel un shader dessine le fer et découpe le vide.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. S'approcher d'un balcon : le garde-corps
porte son ombre de dentelle sur la façade.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le shader `…_ferronnerie.gdshader` est
nouveau : c'est la leçon de l'étape.

## Ce qu'on a fait, dans l'ordre

### 1. Un champ de plus dans `Level`

```gdscript
## Profondeur du balcon filant, 0 s'il n'y en a pas.
var balcony: float = 0.0
```

`_make_levels()` le remplit pour deux niveaux, d'après deux nouvelles variables :
`noble_balcony` (85 cm) et `top_balcony` (70 cm). À zéro, pas de balcon.

Une règle de composition s'ajoute au même endroit : aux étages à balcon, les portes-fenêtres
montent plus haut que les autres baies (`balcony_window_bonus`).

### 2. La dalle et ses consoles : `_build_balcony()`

Une boîte pour la dalle, en avant du mur. Sous elle, une console à chaque limite de travée :
deux boîtes en escalier. Aux deux bouts de la façade, les consoles sont ramenées vers
l'intérieur par `clampf()`, pour ne pas dépasser chez le voisin.

Dans `_build_level()`, le balcon prend la place du bandeau :

```gdscript
if level.balcony > 0.0:
	_build_balcony(base_y, level.balcony)
elif index > 0:
	# bandeau
```

### 3. Le garde-corps : trois rectangles

Un panneau de face et deux retours, posés avec `panel()` comme les fenêtres. Les retours sont
tournés d'un quart de tour :

```gdscript
var frame: Transform3D = Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(...))
```

C'est tout pour la géométrie. Un garde-corps modelé barreau par barreau coûterait des
milliers de triangles par balcon.

### 4. Les baies sans balcon

Une porte-fenêtre sans balcon reçoit un garde-corps dans sa baie. `_build_level()` le décide
d'une ligne :

```gdscript
var guard: bool = not level.base and level.balcony <= 0.0 and level.sill < 0.3
```

Ni soubassement, ni balcon, et une allège basse : il faut un garde-corps.

### 5. Dessiner avec une distance signée

L'idée du shader : pour chaque pixel du rectangle, calculer sa **distance au fer le plus
proche**. Négative dans le fer, positive dans le vide.

Avec cette convention, chaque pièce s'écrit en une ligne :

| Pièce | Distance |
|---|---|
| Lisse horizontale à la hauteur `y0` | `abs(p.y - y0) - hw` |
| Barreau vertical en `u = 0` | `abs(u) - hw` |
| Anneau de rayon `r` | `abs(length(c) - r) - hw` |
| Barre oblique de `a` à `b` | `sd_segment(p, a, b) - hw` |

`hw` est la demi-largeur du fer. Et **réunir deux pièces, c'est prendre le minimum de leurs
distances** : `d = min(d, autre_piece)`. Tout le garde-corps est une suite de `min()`.

### 6. Répéter un motif

Pour répéter un barreau tous les 11 cm, on ne fait pas de boucle. On replie la coordonnée :

```glsl
float u = (fract(p.x / module) - 0.5) * module;   // de -module/2 à +module/2, dans chaque module
```

Tous les modules partagent alors le même calcul. C'est le `floor()` des assises, en version
centrée. Le nombre de modules est arrondi pour que le motif tombe juste sur la longueur du
panneau.

### 7. Trois motifs

L'uniforme `motif` choisit ce qui remplit le champ entre les lisses : des barreaux droits, des
volutes en S (deux spirales reliées par une tige, `sd_scroll()`), ou des croix de Saint-André.
Une frise de cercles court sous la main courante.

### 8. Découper le vide

```glsl
ALPHA = max(step(0.5, solid), step(threshold, veil));
ALPHA_SCISSOR_THRESHOLD = 0.5;
```

`ALPHA` vaut 0 ou 1, et le seuil dit au moteur de jeter les pixels en dessous. Ce n'est pas de
la transparence : le pixel est gardé ou jeté. Deux avantages : pas de tri à faire, et le vide
ne porte pas d'ombre, donc le garde-corps projette son dessin.

De loin, les fers sont plus fins qu'un pixel. Si on les jetait tous, le garde-corps
disparaîtrait ; si on les gardait tous, il deviendrait un mur noir. Le shader garde alors les
lisses et les montants, et rend le reste par une trame : un pixel sur quelques-uns.

### 9. La taille du panneau

Comme la fenêtre de l'étape 004, le shader lit la taille du panneau dans l'échelle de son
instance. Un balcon de 8 m et un garde-corps de baie de 1,30 m utilisent le même matériau.

## Ce qu'il faut retenir

1. Une distance signée : négative dedans, positive dehors. `min()` réunit.
2. `fract()` répète un motif sans boucle.
3. `ALPHA_SCISSOR_THRESHOLD` découpe, sans transparence, et les ombres suivent.
4. La géométrie donne la silhouette (la dalle), le shader donne le détail (le fer).

## À essayer

- `railing_motif` : barreaux, volutes, croisillons.
- `noble_balcony` à 0 : plus de balcon, un garde-corps dans chaque baie.
- `top_balcony` à 1,5 : un grand balcon de dernier étage.
- Dans le shader : `frieze` à `false`, `bar_width` à 0,03.
- Écrire `ALBEDO = vec3(d * 20.0);` et retirer les deux lignes `ALPHA` : on voit la distance.
{TWIN}
## Étape suivante

008 : les boîtes des bandeaux et de la corniche deviennent de vraies moulures, par des profils
extrudés.
