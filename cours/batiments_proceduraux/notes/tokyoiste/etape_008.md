# Tokyo · étape 008 · Auvent, acrotère, descentes d'eau

**Piste : Building.** Un immeuble de ce genre n'a pas de moulures. Ce qui dessine ses
arêtes, ce sont des tôles pliées et des tuyaux : l'auvent au-dessus du rez-de-chaussée, la
couvertine qui coiffe l'acrotère, les appuis d'aluminium sous les fenêtres, les descentes
d'eau de pluie. Aucune de ces pièces n'est une boîte. On apprend ici à les fabriquer : par un
profil qu'on fait glisser, ou qu'on fait tourner.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Deux variables de plus dans le groupe
**Façade** : `canopy_depth` et `downpipes`. S'approcher du haut de la façade, puis du pied
d'un tuyau.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. À lire : `…_profils.gd`, nouveau et court,
puis dans le script de l'immeuble `_build_canopy()`, `_build_downpipes()` et la fin de
`_build_parapet()`. Dans `1_core`, `mesh_builder.gd` n'a pas changé : on se sert enfin de
`extrude()`, `sweep()` et `cone()`, qui y étaient depuis l'étape 002.

## Ce qu'on a fait, dans l'ordre

### 1. Dessiner une section : `…_profils.gd`

Une tôle pliée a la même section d'un bout à l'autre. On ne décrit donc que cette section :
une liste de points en deux dimensions, comme une coupe sur du papier millimétré.

```gdscript
static func canopy(depth: float, thickness: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(depth, -0.03), Vector2(depth, thickness + 0.05), Vector2(depth - 0.03, thickness + 0.05),
		Vector2(depth - 0.03, thickness - 0.01), Vector2(0.0, thickness + 0.02),
	])
```

Convention du fichier : `x` est la saillie vers la rue (0 au nu du mur), `y` la hauteur.
L'auvent ci-dessus est une dalle mince, en légère pente vers la rue, avec un relevé au nez.

Les fonctions sont `static` : on les appelle sans créer d'objet, `Profiles.canopy(0.9, 0.08)`.

Quatre profils : `canopy()` l'auvent, `coping()` la couvertine, `sill()` l'appui de fenêtre,
`circle()` la section d'un tuyau.

### 2. Faire glisser la section : `extrude()`

```gdscript
	_mesh.extrude(Profiles.canopy(canopy_depth, 0.08), MeshBuilder.along_x(Vector3(0.0, y, 0.0)), width, _materials.aluminium)
```

`extrude(profil, repère, longueur, matériau)` fait glisser le profil sur une longueur, et
ferme les deux bouts. Les normales sont calculées pour chaque arête du profil ; deux
facettes voisines qui font un angle faible sont lissées.

### 3. Le repère : où va la section

Le profil est dessiné à plat, en `x` et `y`. Le repère dit comment le poser dans l'immeuble.
`MeshBuilder.along_x(origine)` est le repère d'une pièce horizontale qui court le long de la
façade : le `x` du profil part vers la rue, son `y` vers le haut, et la longueur de
l'extrusion suit l'axe X de l'immeuble. L'origine est le milieu de cette longueur.

C'est la même idée que le repère des rectangles de `panel()` : une forme simple, décrite
dans son propre espace, puis posée.

### 4. La couvertine

```gdscript
	_mesh.extrude(Profiles.coping(PARAPET_DEPTH, 0.03, 0.05), MeshBuilder.along_x(Vector3(0.0, base_y + parapet_height, 0.0)), width + 0.06, _materials.aluminium)
```

C'est le chapeau de tôle de l'acrotère. Son profil est un U renversé : il déborde de 3 cm de
chaque côté du muret et retombe en goutte d'eau. Son dessus penche vers le toit, pour que la
pluie ne coule pas sur la façade. Un profil peut être creux : `extrude()` découpe lui-même
ses deux bouts en triangles.

### 5. Les appuis de fenêtre

Sous chaque fenêtre qui a une allège, un appui d'aluminium de 7 cm :

```gdscript
		if sill > 0.3:
			# Appui d'aluminium sous la fenêtre : un profil de tôle pliée, extrudé sur sa largeur.
			_mesh.extrude(Profiles.sill(0.07), MeshBuilder.along_x(Vector3(x, bottom, wall_z + 0.5 * WALL_DEPTH)), size.x + 0.04, _materials.aluminium)
```

Les portes-fenêtres des balcons n'en ont pas : leur seuil est la dalle.

### 6. Les descentes d'eau : un cylindre

```gdscript
		_mesh.cone(Vector3(x, bottom_y + 0.5 * length, pipe_z), radius, radius, length, _materials.pipe, Basis.IDENTITY, 8)
```

`cone()` fabrique un tronc de cône. Avec deux rayons égaux, c'est un cylindre : un tuyau.
Le dernier argument est le nombre de pans. Huit suffisent pour un tuyau de 9 cm : ses
normales sont lissées, l'œil voit un rond.

Autour du tuyau, des boîtes : la boîte à eau en haut, là où il reçoit l'eau du toit, et un
collier tous les deux mètres.

### 7. Le coude : faire tourner la section

En bas, le tuyau tourne vers le caniveau. Ce n'est plus une section qui glisse tout droit,
c'est une section qui suit un arc : `sweep()`.

```gdscript
		var frame: Transform3D = Transform3D(Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT), Vector3(x, bottom_y, pipe_z + elbow))
		_mesh.sweep(Profiles.circle(radius, 8), frame, Vector2(elbow, elbow), PI, 1.5 * PI, _materials.pipe, 6)
```

`sweep(profil, repère, rayons, angle de départ, angle d'arrivée, matériau, pas)` balaie le
profil le long d'un arc tracé dans le plan XY du repère. Ici le profil est un cercle (la
section du tuyau), l'arc un quart de cercle de 12 cm de rayon, de l'angle π à l'angle 3π/2.

Le repère est construit à la main : ses trois axes sont l'arrière-avant de l'immeuble
(`Vector3.BACK`, c'est `+Z`, vers la rue), le haut, et la gauche. L'arc se trace donc dans
le plan vertical qui va vers la rue. `Basis(a, b, c)` prend les trois axes dans l'ordre ; ils
doivent rester perpendiculaires et tourner dans le bon sens, sinon la pièce sort retournée.

### 8. Tout dans le même maillage

Toutes ces pièces partent dans le même `MeshBuilder` que les murs. À la fin, `commit()` fait
toujours un maillage par matériau : un pour l'aluminium (auvent, couvertine, appuis, lisses),
un pour les tuyaux. Le nombre d'appels de dessin ne dépend pas du nombre de pièces.

L'immeuble est passé de 1 224 à 1 932 triangles. Les deux descentes d'eau en font 480 à elles
seules, colliers et coudes compris : plus de la moitié de ce qui a été ajouté. Une pièce
ronde coûte cher, même petite. L'étape 013 y reviendra.

### 9. Une cote qui vient d'un règlement

`canopy_depth` ne dépasse pas 1 m dans l'inspecteur. C'est la saillie permise à un store
au-dessus d'une route nationale par le bureau qui gère ces routes à Tokyo, avec 2,50 m de
hauteur libre en dessous. L'auvent est posé à `ground_height - 0.8`, et `ground_height` ne
descend pas sous 3,30 m : il reste toujours 2,50 m.

Source : ministère japonais du Territoire, Bureau des routes nationales de Tokyo, « 占用許可
申請の詳細 », <https://www.ktr.mlit.go.jp/toukoku/toukoku00078.html>, lu le 11 octobre 2026.
Ce sont les règles de ce gestionnaire, pour les routes qu'il gère.

## Ce qu'il faut retenir

1. Une pièce de section constante se décrit par sa section, en deux dimensions.
2. `extrude()` la fait glisser, `sweep()` la fait tourner, `cone()` fait les ronds.
3. Un repère dit où poser une forme décrite dans son propre espace.
4. Le nombre d'appels de dessin dépend des matériaux, pas des pièces.
5. Une pièce ronde coûte beaucoup de triangles.

## À essayer

- `canopy_depth` à 0 : plus d'auvent. `downpipes` à faux.
- Dans `…_profils.gd`, `canopy()` : changer `thickness + 0.05` en `thickness + 0.25` aux deux
  endroits. Le relevé du nez devient un bandeau.
- Dans `_build_downpipes()` : `radius` à 0,08 ; le dernier argument de `cone()` à 4 : un tuyau
  carré.
- Dans `sweep()`, remplacer `1.5 * PI` par `2.0 * PI` : le coude fait un demi-tour.
{TWIN}
## Étape suivante

009 : le toit. Une étanchéité, des acrotères, l'édicule de l'escalier, un réservoir d'eau.
Et la règle qui donne leur silhouette aux immeubles de Tokyo : le gabarit oblique.
