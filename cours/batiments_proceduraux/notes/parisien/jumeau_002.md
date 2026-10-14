## Le même pas, à Tokyo et à New York

Les dossiers voisins `building_proceduraux_tokyoiste_etape_002` et `building_proceduraux_newyorkais_etape_002` font le même pas : à Tokyo, « Carrelage : carreaux et joints » ; à New York, « Brique : appareil et joints ».

- **Ce qui ne change pas** : l'ossature du shader : des coordonnées de face en mètres tirées de la position, une grille par `floor()`, la distance au joint le plus proche, un masque filtré par `fwidth()`.
- **Ici, à Paris** : des assises de pierre de 38 cm de haut, découpées en blocs.
- **À Tokyo** : des rangs de carreaux émaillés de 23,5 × 6,8 cm, joints compris. À cette taille, un joint de 8 mm est plus fin qu'un pixel dès une dizaine de mètres : le filtrage n'y est pas un raffinement, il est indispensable.
- **À New York** : des briques modulaires de 20,3 × 6,8 cm, joint compris, en appareil à boutisses : toutes les six assises, un rang de briques vues par leur bout, deux fois plus courtes, que le shader reconnaît au numéro de l'assise.

Mettre les trois fichiers `.gdshader` côte à côte et suivre les mêmes sections : coordonnées, rangs, joints, couleur. Le shader d'une autre ville se lit alors presque sans explication.
