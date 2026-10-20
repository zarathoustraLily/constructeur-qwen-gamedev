## Le même pas, à Paris et à New York

Les dossiers voisins `building_proceduraux_parisien_etape_013` et `building_proceduraux_newyorkais_etape_013` font le même pas : à Paris, « Niveaux de détail : ne dessiner que ce qui se voit » ; à New York, « Niveaux de détail et occultation ».

- **Ce qui ne change pas** : la même mécanique, dans le même outil de maillage : `set_zones()`, les distances de visibilité, une boîte englobante commune, pas de marge, pas d'ombre pour les petites pièces, la finesse des shaders, la touche P, et la ligne de mesure qui compte ce que le moteur dessine.
- **Ici, à Tokyo** : une rue légère, 45 000 triangles : le gain se compte en objets à dessiner (textes des enseignes, fils), et une pièce peut même grossir au loin, comme les fils.
- **À Paris** : une rue lourde, 176 000 triangles avec ses corniches : les réglages du moteur font l'essentiel du gain, les niveaux de détail le reste.
- **À New York** : des tours trop hautes pour une seule distance, découpées gradin par gradin ; une façade lointaine qui remplace au-delà de 250 m des centaines de pièces par un rectangle de la même allure ; l'occultation, une boîte par gradin. De loin, treize fois moins de triangles.

Lancer les trois visites avec la ligne de mesure et comparer : la même technique ne donne pas le même gain sur trois contenus différents. D'où la règle : mesurer d'abord.
