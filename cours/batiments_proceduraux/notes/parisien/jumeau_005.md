## Le même pas, à Tokyo et à New York

Les dossiers voisins `building_proceduraux_tokyoiste_etape_005` et `building_proceduraux_newyorkais_etape_005` font le même pas : à Tokyo, « Une pièce derrière la vitre, bureaux éclairés » ; à New York, « Une pièce derrière la vitre, bureaux la nuit ».

- **Ce qui ne change pas** : l'« interior mapping » : un rayon, une boîte, la paroi touchée en premier ; la lumière de nuit sortie par `EMISSION` ; un tirage par fenêtre à partir de sa position.
- **Ici, à Paris** : un salon : des murs, un sol, un plafond, un lustre, des rideaux.
- **À Tokyo** : un bureau : un plafond à dalles, des tubes fluorescents, des armoires de métal, un store à lames.
- **À New York** : un bureau jusqu'à 28 pieds de profondeur : faux plafond à dalles et luminaires encastrés, cloisons basses, classeurs, store à enrouleur ; la nuit, les étages s'allument en entier, ou presque pas.

Repérer, dans les trois shaders, la séparation entre « quelle paroi est touchée » et « de quelle couleur elle est » : seule la seconde partie change d'une ville à l'autre.
