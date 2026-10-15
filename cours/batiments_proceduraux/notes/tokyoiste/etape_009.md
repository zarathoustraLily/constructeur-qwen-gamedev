# Tokyo · étape 009 · Toit-terrasse, réservoir, gabarit oblique

**Pistes : Building et Shader.** L'immeuble reçoit son toit : une étanchéité, des acrotères,
l'édicule de l'escalier, un réservoir d'eau, des climatiseurs, une antenne. Et il apprend la
règle qui donne leur silhouette aux immeubles de Tokyo : le gabarit oblique, qui fait reculer
les derniers étages. Un second matériau calculé arrive avec eux : le béton brut.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Le dernier étage est en retrait, derrière
une terrasse. Monter avec la touche E pour voir le toit. Deux groupes de plus dans
l'inspecteur : **Toit** et **Gabarit**.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Quatre fichiers nouveaux : `…_toit.gd`,
`…_palette.gd` (dans `5_data`), `…_beton.gdshader`, et dans le script de l'immeuble tout ce
qui touche au recul des étages. Commencer par là.

## Ce qu'on a fait, dans l'ordre

### 1. La règle : une ligne qui monte en oblique

À Tokyo, la hauteur d'un immeuble sur rue n'est pas un nombre. C'est une ligne. Elle part du
bord **opposé** de la voie, au niveau du sol, et monte selon une pente fixée par la zone
d'urbanisme. L'immeuble doit rester dessous.

```text
                         ╱  la ligne : hauteur = pente × distance au bord opposé
                       ╱
                     ╱ ┌───────┐
                   ╱   │ étage en retrait
                 ╱ ┌───┘       │
               ╱   │           │
             ╱     │ immeuble  │
  ─────────┴───────┴───────────┴──
  bord      voie    alignement
  opposé
```

À l'alignement, la distance au bord opposé est la largeur de la voie. Sur une voie de 11 m,
avec une pente de 1,5, la façade peut donc monter à 16,50 m. Au-dessus, chaque étage doit
reculer pour repasser sous la ligne.

Deux pentes : 1,25 dans les zones d'habitation, 1,5 dans les autres.

Source : arrondissement d'Ōta, « 建物の高さについての制限 »,
<https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/tatemono_tyuuikisei/takasaseigen.html>,
lu le 11 octobre 2026.

Ce que le cours ne modélise pas, et que la même page décrit : la règle ne s'applique que
jusqu'à une certaine distance de la voie (20 à 35 m) ; un immeuble bâti en retrait de
l'alignement gagne autant de recul pour la ligne ; d'autres gabarits s'y ajoutent, vers les
voisins et vers le nord.

### 2. Les nombres des règlements sont des données

Les deux pentes ne sont pas écrites dans le script de l'immeuble. Elles sont dans un fichier
de `5_data`, le dossier des paramètres de conception :

```gdscript
const ROAD_SLOPES: Array[float] = [1.25, 1.5]
const MIN_SETBACK: float = 1.0
const MIN_FLOOR_DEPTH: float = 4.0
```

L'immeuble le charge par `preload` et lit `Palette.ROAD_SLOPES[slope_zone]`. Changer de
règlement ne demande pas d'ouvrir un script de `6_assets`. Les deux autres constantes ne sont
pas des règlements mais des choix de conception, et le fichier le dit.

### 3. Calculer le recul de chaque niveau : `_fit_setbacks()`

`Level` gagne un champ, `setback`. La fonction parcourt les niveaux de bas en haut et se pose
une seule question : à quelle hauteur est le haut de ce niveau, et de combien faut-il reculer
pour que ce point passe sous la ligne ?

```gdscript
		var needed: float = solid_top / slope - road_width if road_width > 0.0 else 0.0
		if needed > 0.0 and index > 0:
			# On recule par demi-mètres, et jamais de moins d'un mètre. Un niveau ne peut pas
			# avancer au-dessus de celui du dessous.
			setback = maxf(setback, maxf(ceilf(needed / 0.5) * 0.5, Palette.MIN_SETBACK))
		levels[index].setback = setback
```

La ligne est à la hauteur `slope × distance`. Pour être sous elle à la hauteur `solid_top`,
il faut donc être à la distance `solid_top / slope` du bord opposé : c'est-à-dire reculer de
cette distance, moins la largeur de la voie.

Trois règles de bon sens s'y ajoutent : on recule par demi-mètres ; jamais de moins d'un
mètre, sinon la terrasse gagnée ne sert à rien ; et un niveau ne peut pas avancer au-dessus
de celui du dessous.

Pour le dernier niveau, `solid_top` compte l'acrotère : c'est un mur plein.

Avec les valeurs par défaut : cinq étages de 3 m sur un rez-de-chaussée de 3,60 m, soit
18,60 m, plus 60 cm d'acrotère. Sur une voie de 11 m, seul le dernier niveau dépasse. Il lui
faut 19,20 / 1,5 − 11 = 1,80 m, arrondis à 2 m.

### 4. Les étages qui n'ont plus la place

Plus un étage est haut, plus il recule, et moins il lui reste de profondeur. En dessous de
4 m, on ne le construit pas :

```gdscript
	var count: int = levels.size()
	while count > 1 and not _fit_setbacks(levels, count):
		count -= 1
	levels.resize(count)
```

On essaie avec tous les niveaux. Si l'un d'eux n'a plus la profondeur minimale,
`_fit_setbacks()` renvoie faux : on enlève le dernier et on recommence, car le nouveau dernier
niveau porte maintenant l'acrotère. `floor_count` devient donc un maximum demandé ;
`get_built_level_count()` dit combien de niveaux ont été montés.

### 5. Faire reculer un niveau entier

Tout ce qu'un niveau pose doit reculer du même nombre de mètres : ses murs, ses fenêtres,
son balcon. Plutôt que de retoucher chaque ligne, on passe par un seul point :

```gdscript
func _at(point: Vector3) -> Vector3:
	return point + Vector3(0.0, 0.0, -_setback)
```

`_build_level()` note le recul du niveau dans `_setback` avant de poser quoi que ce soit, et
les trois petites fonctions par lesquelles tout passe, `_wall()`, `_box()` et `_panel()`,
appliquent `_at()` :

```gdscript
	_mesh.box(size + Vector3(WALL_OVERLAP, WALL_OVERLAP, 0.0), _at(center), material)
```

C'est pour ce moment que `_panel()` et `_box()` existaient depuis les étapes 006 et 007 :
une ligne a changé dans chacune. Dans `_build_level()` et `_build_balcony()`, les appels qui
posent les murs, les dalles et les fenêtres n'ont pas bougé. Seul l'appel d'`extrude()` pour
les appuis, qui ne passe par aucune des trois, a dû recevoir `_at()` à la main.

Le carrelage, lui, n'a rien à savoir. Son motif vient de la position : il continue sans
couture sur le mur reculé.

### 6. La terrasse

Un niveau qui recule plus que celui du dessous laisse une bande de toit devant lui.
`rebuild()` le remarque en comparant les reculs de deux niveaux qui se suivent, et appelle
`_build_terrace()` : un sol d'étanchéité et un garde-corps à barreaux, avec ses deux retours.

Ce niveau n'a alors plus besoin d'un balcon en creux : sa terrasse en tient lieu.
`_fit_setbacks()` remet son `recess` à zéro.

Le garde-corps d'une terrasse est toujours à barreaux, jamais un muret. La raison est dans
la règle : pour le gabarit sur rue, l'arrondissement de Nakano ne compte pas dans la hauteur
un garde-corps de balcon fait de barreaux verticaux, à travers lequel on voit ; il compte les
panneaux pleins et les tôles perforées. Un muret plein de 1,10 m au bord de la terrasse
ferait donc dépasser l'étage du dessous.

Source : arrondissement de Nakano, « 高さ制限における屋上や途中階のパイプ手すりについて »,
1er septembre 2022,
<https://www.city.tokyo-nakano.lg.jp/machizukuri/kenchiku/tetsuzuki/kakunin-shinsei/kenchikukijyunho.files/tesuri20220901.pdf>,
lu le 12 octobre 2026. C'est la pratique de cet arrondissement.

### 7. Vérifier : `get_slope_margin()`

L'immeuble sait dire de combien il passe sous la ligne :

```gdscript
		margin = minf(margin, slope * (road_width + levels[index].setback) - solid_top)
```

C'est la plus petite distance verticale entre un mur plein et la ligne. Le test de l'étape
l'appelle et échoue si elle est négative. Par défaut, elle vaut 30 cm. Une règle qu'un
générateur prétend respecter doit pouvoir se vérifier par un nombre.

### 8. Le toit : `…_toit.gd`

Le toit a son propre script. C'est un objet à part, qu'on pose sur une base rectangulaire ;
il ne connaît de l'immeuble que ce qu'on lui donne en arguments. Tout y est `static` :

```gdscript
	RoofBuilder.build(_mesh, _materials, get_facade_width(), depth, base_y, top_setback, parapet_height,
			core_x, minf(bay_width, 2.6), penthouse, water_tank, roof_units, 0)
```

Il reçoit l'outil de maillage de l'immeuble : tout ce qu'il pose part dans les mêmes
maillages. Ce qu'il monte :

| Pièce | Comment |
|---|---|
| L'étanchéité | une boîte mince, d'un acrotère à l'autre |
| Les acrotères des côtés et du fond | trois boîtes, coiffées de tôles plates |
| L'édicule | la cage d'escalier qui continue au-dessus du toit, à l'aplomb de sa travée |
| Le réservoir d'eau | un cylindre sur quatre pieds, posé sur l'édicule |
| Les climatiseurs des bureaux | des boîtes en rang, avec la grille de l'étape 007 |
| L'antenne | un mât, une traverse, cinq brins : des boîtes de 2 à 3 cm |

Le réservoir est un `cone()` à deux rayons égaux, comme les tuyaux de l'étape 008, avec seize
pans au lieu de huit : il est gros, on verrait ses facettes.

```gdscript
	mesh.cone(middle, radius, radius, height, materials.tank, Basis.IDENTITY, 16)
```

L'acrotère côté rue reste monté par l'immeuble : il fait partie de la façade.

Limite : l'édicule et le réservoir dépassent du toit sans être comptés dans le gabarit. La
règle réelle n'exempte ces ouvrages que sous conditions, que le cours ne vérifie pas.

### 9. Le shader du béton

Les murs latéraux et le fond étaient d'un gris uni. Ils sont maintenant en béton brut, avec
l'empreinte de son coffrage. Le shader `…_beton.gdshader` ne contient aucune idée nouvelle,
et c'est sa leçon : mêmes recettes que le carrelage, autres nombres.

La grille des panneaux de coffrage, par `floor()` :

```glsl
	vec2 panel = floor(p / panel_size);
	vec2 in_panel = p - panel * panel_size;
```

Les trous d'écarteur, ces petits cônes laissés par les tiges qui tenaient le coffrage, par
`fract()` et une distance à un point :

```glsl
	vec2 to_tie = (fract(p / tie_spacing) - 0.5) * tie_spacing;
	float tie_distance = length(to_tie) - tie_radius;
```

`fract()` ramène tous les trous à un seul, comme il ramenait tous les barreaux à un seul.
`length(to_tie) - tie_radius` est la distance signée à un disque.

Les reprises de bétonnage : une ligne tous les 3 m de hauteur, là où une coulée s'est
arrêtée. Elle se calcule sur `v_pos.y`, la hauteur réelle dans l'immeuble.

Les cotes du coffrage (panneaux de 1,80 m sur 0,90 m, trous tous les 60 cm) sont plausibles ;
elles ne sont pas relevées.

### 10. Un shader, deux matériaux

```gdscript
	side = _shader_material(CONCRETE_SHADER, {
		"grime": minf(grime + 0.1, 1.0),
	})
	concrete = _shader_material(CONCRETE_SHADER, {
		"lift_height": 0.0,
		"panel_variation": 0.2,
		"grime": grime,
	})
```

`side` habille les grands murs latéraux. `concrete` sert aux dalles et aux petits ouvrages :
le même fichier `.gdshader`, sans reprises de bétonnage et avec des panneaux plus réguliers.
Un matériau, c'est un shader plus ses réglages ; rien n'oblige à écrire un shader par
matériau.

## Ce qu'il faut retenir

1. Une règle d'urbanisme se traduit en une fonction courte, et se vérifie par un nombre.
2. Les nombres d'un règlement sont des données : ils vont dans `5_data`.
3. Pour déplacer tout un morceau, faire passer toutes ses pièces par un seul point (`_at()`).
4. Un objet à part (le toit) a son script, et ne reçoit que des arguments.
5. Un nouveau matériau ne demande pas d'idée nouvelle : une grille, une distance, un filtre.

## À essayer

- `road_width` à 6 : l'immeuble devient un escalier. À 4 : le dernier étage n'est plus construit.
- `road_width` à 0 : plus de gabarit, la façade monte tout droit.
- `slope_zone` : « Zone d'habitation », avec `road_width` à 8.
- `floor_count` à 9 avec `road_width` à 11 : compter les niveaux réellement montés.
- `penthouse` à faux : le réservoir descend sur le toit.
- Dans le shader du béton : `formwork` à 0. C'est un enduit lisse, qu'on retrouvera à
  l'étape 011.
- Lancer le test de l'étape (la commande est en tête du fichier de `7_tests`) : il affiche la
  marge sous le gabarit.
{TWIN}
## Étape suivante

010 : le rez-de-chaussée devient une boutique, avec son rideau métallique. L'immeuble se
couvre d'enseignes, et un distributeur de boissons s'installe près de la porte.
