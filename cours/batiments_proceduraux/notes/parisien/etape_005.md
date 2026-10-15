# Paris · étape 005 · Une pièce derrière la vitre, la nuit

**Piste : Shader.** Derrière chaque vitre, on fait apparaître une pièce : des murs, un sol, un
plafond, un lustre, des rideaux. Sans un seul triangle de plus. La technique s'appelle
« interior mapping ». Elle sert aussi à allumer les fenêtres la nuit.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. **N** passe du jour à la nuit. Se déplacer
devant la façade : les pièces ont de la profondeur, on voit leurs murs tourner.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Tout se passe dans `…_fenetre.gdshader`, entre
les bandeaux `NOUVEAU À L'ÉTAPE 005`. Les numéros ci-dessous sont ceux des commentaires du
shader.

## Ce qu'on a fait, dans l'ordre

### 1. L'idée : prolonger le regard

La pièce n'existe pas. C'est une boîte imaginaire derrière le rectangle de la fenêtre. Pour
chaque pixel de vitre, on prend la direction du regard, on la prolonge dans cette boîte, et on
cherche quelle paroi elle touche. La couleur du pixel est celle de ce point de la paroi.

Comme la direction du regard change quand la caméra se déplace, la paroi touchée change aussi :
la pièce a de la profondeur.

### 2. Le repère de la fenêtre

Il faut exprimer le regard dans le repère de la fenêtre : x vers la droite, y vers le haut, z
vers l'extérieur. Les axes sont calculés une fois par fenêtre, dans `vertex()` :

```glsl
v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
```

Dans `fragment()`, trois produits scalaires donnent la direction `d` du regard dans ce repère.
Sa composante z est négative : le regard entre dans la pièce.

### 3. Toucher une paroi : le rayon et la boîte

La boîte a six parois, par paires : gauche et droite, sol et plafond, fond. Pour chaque paire,
on calcule la distance le long du rayon jusqu'à la paroi vers laquelle il se dirige :

```glsl
float tx = ((d.x > 0.0 ? x1 : x0) - origin.x) / d.x;         // mur de droite ou de gauche
float ty = ((d.y > 0.0 ? ceil_y : floor_y) - origin.y) / d.y; // plafond ou sol
float tz = -depth / d.z;                                      // mur du fond
float t_hit = min(tx, min(ty, tz));                           // la plus proche gagne
vec3 hit = origin + d * t_hit;
```

Dans le shader, les deux premières lignes ont en plus une garde contre la division par zéro.

`hit` est le point touché. Selon la paroi, on en tire deux coordonnées (le long du mur et la
hauteur, par exemple) et on y dessine ce qu'on veut. La fonction `wall()` dessine un mur : un
soubassement plus sombre, une cimaise, une plinthe, une corniche. Ce ne sont que des bandes
horizontales, donc des `smoothstep()` sur la hauteur.

### 4. Une pièce par fenêtre

Si toutes les pièces étaient identiques, l'illusion tomberait. Chaque fenêtre tire donc les
siennes : largeur, profondeur, position, couleur des murs, rideaux.

```glsl
v_room_key = MODEL_MATRIX[3].xyz;   // dans vertex() : la position de la fenêtre
float r0 = pc_hash3(v_room_key * 8.0 + ...);   // dans fragment() : le premier tirage
float r1 = pc_rehash(r0, 1.0);                 // les suivants en découlent
```

C'est le hachage de l'étape 003, avec une autre clé : non plus le numéro d'un bloc, mais la
position de la fenêtre. C'est pour cela que les fenêtres sont des instances : chacune a sa
matrice.

### 5. Éclairer la pièce soi-même

Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. Le shader calcule donc sa
lumière :

- le jour entre par la fenêtre et s'éteint avec la profondeur : `exp(hit.z / 3.4)` ;
- une lampe au plafond éclaire les parois selon leur orientation et leur distance ;
- la pièce est allumée si son tirage `r0` tombe sous la part de pièces allumées, qui dépend
  de `night` : 6 % le jour, 55 % la nuit.

Le résultat sort par `EMISSION`, pas par `ALBEDO` : c'est une lumière qui vient de derrière la
vitre. La nuit, les fenêtres allumées brillent sans qu'on pose une seule lampe.

### 6. Les rideaux : un plan de plus

Douze centimètres derrière la vitre, un plan. Si le rayon le touche avant la paroi, et à un
endroit où il y a de l'étoffe, il cache la pièce. Les plis sont deux sinusoïdes. Le voilage
laisse passer une partie de ce qui est derrière lui.

### 7. Le reflet : ce qui est réfléchi ne traverse pas

Plus le regard est rasant, plus une vitre renvoie le ciel et moins on voit à travers. C'est la
loi de Fresnel :

```glsl
float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
vec3 transmitted = interior * ... * (1.0 - fresnel) * ...;
```

De face, on voit la pièce. En biais, on voit le ciel.

### 8. La nuit, côté scripts

Trois lignes : l'immeuble reçoit `set_night(value)`, le garde dans `_night`, et le donne aux
matériaux, qui règlent le paramètre `night` du shader. Rien n'est reconstruit : changer un
paramètre de shader est immédiat.

`_night` est gardé pour une raison : `rebuild()` refabrique les matériaux. Sans cette
variable, changer une valeur dans l'inspecteur en pleine nuit rallumerait le jour.

## Ce qu'il faut retenir

1. Un intérieur peut n'être qu'un calcul : un rayon, une boîte, la paroi la plus proche.
2. La clé d'un tirage peut être la position de l'objet.
3. Ce que le moteur n'éclaire pas, le shader l'éclaire lui-même et le sort par `EMISSION`.
4. Un réglage qui ne change pas la géométrie ne doit pas la reconstruire.

## À essayer

- N, puis se déplacer le long de la façade.
- Dans le shader : valeur par défaut de `lit_ratio_night` à 1 : tout est allumé.
- `room_depth` à 10, puis à 2.
- `curtains` à 0 : plus de rideaux.
- Écrire `EMISSION = vec3(-d.z);` à la fin : on voit la direction du regard.

## Source

Joost van Dongen (Université d'Utrecht, Ronimo Games), « Interior Mapping: A new technique for
rendering realistic buildings », CGI 2008. Le tirage d'une pièce par fenêtre et les pièces
allumées la nuit en viennent aussi (sections 4.1 et 4.2).
<https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf>
{TWIN}
## Étape suivante

006 : la façade cesse d'être une grille. Soubassement, étage noble, étages courants, dernier
étage : chaque niveau aura sa hauteur et ses baies.
