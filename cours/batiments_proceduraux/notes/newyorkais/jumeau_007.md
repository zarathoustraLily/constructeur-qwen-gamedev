## Le même pas, à Paris et à Tokyo

Les dossiers voisins `building_proceduraux_parisien_etape_007` et `building_proceduraux_tokyoiste_etape_007` font le même pas : à Paris, « Balcons filants et ferronnerie » ; à Tokyo, « Balcons, garde-corps, climatiseurs ».

- **Ce qui ne change pas** : un grand rectangle, et un shader qui y dessine une structure répétée par `floor()` et `fract()`, des barreaux ou des meneaux : la géométrie reste simple, le dessin est calculé.
- **Ici, à New York** : la façade entière d'une tour de verre, sur un seul rectangle par face : modules, étages, verre de vision, allèges, et derrière le verre les bureaux de l'étape 005, rangés dans un `.gdshaderinc` que deux shaders partagent. Et un second règlement, celui de 1961 : la hauteur de la tour sort d'une division.
- **À Paris** : des balcons filants qui avancent sur la rue, à l'étage noble et au dernier étage, avec une ferronnerie à arabesques.
- **À Tokyo** : des balcons en creux : le mur des fenêtres recule, le garde-corps reste au nu de la façade ; des barreaux, des panneaux, et la grille d'un climatiseur.

Comparer les trois shaders : à Paris et à Tokyo, le vide est découpé par l'alpha ; à New York, le verre est délimité par une distance au meneau. Dans les trois, une grille, une distance, un seuil.
