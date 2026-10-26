# Contour par coque inversée (shader spatial, passe suivante)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier contour`.

## Ce que fait l'effet

Un trait de couleur autour de la silhouette : le maillage est redessiné une seconde fois, gonflé le long de ses normales et vu de dos (`cull_front`), d'une couleur unie. Seul le bord dépasse.

## Quand l'employer

Objet sélectionné ou interactif, ennemi ciblé, style dessin animé. Le shader se met en `next_pass` du matériau de l'objet : on garde son apparence.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`contour.gdshader`, vérifié)

```glsl
shader_type spatial;
// Contour (« coque inversée ») : une seconde passe du maillage, gonflée le long des normales et dessinée de dos,
// d'une couleur unie. Seul le bord dépasse derrière l'objet : on voit un trait autour de sa silhouette.
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float thickness = 0.05;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Montrer le contour : le matériau du trait est dessiné après la surface, sur le même maillage.
func entourer(surface: Material, trait_contour: ShaderMaterial) -> void:
	surface.next_pass = trait_contour


## Retirer le contour.
func retirer_contour(surface: Material) -> void:
	surface.next_pass = null
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 0 pixels sombres sur la ligne du milieu sans contour, 18 avec, 0 une fois retiré.

## Pièges

- Sur un maillage à arêtes vives (un cube), les normales des faces sont séparées : le gonflement ouvre le trait aux coins (limite connue de la méthode, non mesurée ici). Un maillage lissé donne un trait continu.
- L'épaisseur est en unités du maillage : `VERTEX` et `NORMAL` sont en espace du modèle (godot-docs, spatial_shader.rst). Le trait suit l'échelle de l'objet et paraît plus fin de loin.
- `next_pass` modifie le matériau lui-même, une ressource partagée (godot-docs, resources.rst) : posé sur un matériau commun, il entoure tous les objets qui l'utilisent.
