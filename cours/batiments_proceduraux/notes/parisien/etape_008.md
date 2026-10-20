# Paris · étape 008 · Moulures par profils extrudés

**Piste : Building.** Les bandeaux et la corniche étaient des boîtes. Une façade parisienne
est faite de moulures : des sections arrondies qui courent le long d'une ligne. On les obtient
en dessinant la section une fois, puis en la faisant glisser. C'est l'extrusion.

L'immeuble passe de 1 928 à 9 400 triangles : les moulures sont ce qui coûte le plus cher en
géométrie. L'étape 013 apprendra à ne pas les dessiner de loin.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` : une variable de plus, `ornament`, dans le groupe « Façade ».

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le fichier `…_profils.gd` est nouveau. Dans
`1_core/procedural/mesh_builder.gd`, lire `extrude()` et les quatre fonctions de repère du
début : elles étaient là depuis l'étape 002, elles servent maintenant.

## Ce qu'on a fait, dans l'ordre

### 1. Dessiner une section : `…_profils.gd`

Un profil est une liste de points en deux dimensions, comme une coupe sur du papier
millimétré. Convention : `x` est la saillie par rapport au mur, `y` la hauteur.

```gdscript
static func string_course(height: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(0.0, 0.0), Vector2(0.3 * depth, 0.0)]
	_quarter(points, Vector2(0.3 * depth, 0.0), Vector2(0.72 * depth, 0.32 * height), false)
	...
	return points
```

Les cotes sont des fractions de `height` et `depth` : le même profil sert à toutes les
tailles. `_quarter()` ajoute un quart d'ellipse, bombé ou creusé, en six segments. La console
en S est une courbe de Bézier (`bezier_interpolate`).

Les fonctions sont `static` : on les appelle sans créer d'objet, `Profiles.cornice(0.5, 0.6)`.
Ce fichier ne sait rien du maillage ; il ne rend que des points.

### 2. Faire glisser la section : `extrude()`

```gdscript
_mesh.extrude(profil, repère, longueur, matériau)
```

`extrude()` relie le profil à sa copie, `longueur` plus loin, par un rectangle par segment,
puis ferme les deux bouts. Deux soins :

- **les normales** : deux segments voisins qui font un angle faible partagent une normale
  moyenne, et la moulure paraît ronde ; au-delà de l'angle `SMOOTH_ANGLE`, l'arête reste vive ;
- **les bouts** : `Geometry2D.triangulate_polygon()` découpe le profil en triangles, quelle
  que soit sa forme.

### 3. Le repère : où va la section

Le même profil sert pour un bandeau horizontal, un montant vertical et une traverse. Ce qui
change, c'est le repère dans lequel on l'extrude. `MeshBuilder` en fournit quatre :

| Repère | La section est dans le plan | Elle glisse le long de |
|---|---|---|
| `along_x(origine)` | saillie vers la rue, hauteur vers le haut | X : bandeaux, corniches |
| `jamb(origine, côté)` | largeur qui s'éloigne de la baie, saillie vers la rue | Y : montants de chambranle |
| `head(origine)` | largeur vers le haut, saillie vers la rue | X : traverse de chambranle |
| `facing_street(origine)` | X et Y de la façade | Z : clefs, vers la rue |

Un repère est un `Transform3D` : trois axes et une origine. `along_x` s'écrit
`Basis(Vector3.BACK, Vector3.UP, Vector3.RIGHT)` : le x du profil part vers la rue, son y
monte, et l'extrusion court le long de X.

### 4. Trois niveaux d'ornement

```gdscript
@export_enum("Nu", "Mouluré", "Riche") var ornament: int = 2
```

Le code des boîtes de l'étape 006 n'est pas supprimé : il devient le niveau « Nu ».

```gdscript
if ornament >= ORNAMENT_MOULDED:
	_mesh.extrude(Profiles.string_course(0.22, 0.11), MeshBuilder.along_x(...), width, _materials.stone)
else:
	_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
```

| Pièce | Nu | Mouluré | Riche |
|---|---|---|---|
| Bandeaux | boîte | profil | profil |
| Corniche | deux boîtes | profil et denticules | plus des modillons |
| Baies | appui en boîte | chambranle, appui profilé | plus une clef |
| Baies de l'étage noble | — | corniche de baie | sur deux consoles |
| Balcons | consoles en boîtes | nez mouluré, consoles en S | pareil |
| Angles | — | — | chaînes d'angle |

### 5. L'encadrement d'une baie : `_build_surround()`

Trois extrusions du même profil : deux montants (`jamb`, un de chaque côté) et une traverse
(`head`). À l'étage noble, une petite corniche au-dessus ; ailleurs, en niveau riche, une
clef. Un champ de plus dans `Level`, `noble`, dit à quel étage on est.

Le soubassement n'a pas de chambranles : `if level.base ... return`.

### 6. Les pièces répétées : denticules et modillons

Sur la corniche, une rangée de petits cubes (les denticules) et, en niveau riche, de petites
consoles (les modillons). Une boucle, un pas calculé pour tomber juste sur la largeur :

```gdscript
var dentils: int = maxi(int(width / 0.17), 1)
for index: int in range(dentils):
	var x: float = (float(index) + 0.5) * (width / float(dentils)) - 0.5 * width
```

### 7. Tout dans le même maillage

Toutes ces pièces sont en pierre. L'outil de maillage les range avec les murs : les
9 400 triangles tiennent dans deux maillages de pierre, celui des étages et celui du
soubassement, donc deux appels de dessin.

## Ce qu'il faut retenir

1. Une moulure, c'est une section et une ligne. On dessine la section une fois.
2. Le même profil dans des repères différents donne des pièces différentes.
3. Les cotes d'un profil sont des fractions : il s'adapte à toutes les tailles.
4. Le code simple qu'on remplace reste utile : il devient le niveau le plus sobre.

## À essayer

- `ornament` : Nu, Mouluré, Riche.
- Dans `…_profils.gd`, changer `ARC_STEPS` de 6 à 2 : les arrondis deviennent anguleux, et le
  nombre de triangles baisse.
- Dans `_build_surround()`, changer `band_width` : tous les chambranles suivent.
- Dans `cornice()`, déplacer un point : la corniche de couronnement et celles des baies
  changent ensemble.
{TWIN}
## Étape suivante

009 : le comble. Un toit brisé en zinc, des lucarnes, des cheminées, et un troisième shader.
