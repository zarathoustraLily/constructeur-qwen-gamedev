# New York : carnet de conception (interne)

Style : `newyorkais` → `building_proceduraux_newyorkais_etape_NNN`. Livret unique à trois villes.
Choix de l'utilisateur (12 octobre, 8 h 30) : les deux familles de tours (maçonnerie en gradins
de 1916 et tours de verre de 1961) ; un seul livret pour Paris, Tokyo et New York.

## Sources vérifiées (lues le 12 octobre 2026)

1. Museum of the City of New York, *The Greatest Grid*, « The Commissioners' Plan, 1811 » (Making the Plan)
   <https://thegreatestgrid.mcny.org/greatest-grid/making-the-plan/12>
   - « the standard cross street is 60 feet » ; « The avenues are 100 feet wide » ; « major cross streets are 100 feet » ;
     « all blocks are 200 feet north to south » ; îlots est-ouest : 920 pieds entre 5e et 6e avenues, 620 à 640 pieds à
     l'est, « the West Side blocks are all 800 feet long ».
2. MCNY, *The Greatest Grid*, « The Setback Principle of the 1916 Zoning Law »
   <https://thegreatestgrid.mcny.org/greatest-grid/manhattan-monumentality/294>
   - cinq variantes de la formule, selon la largeur de la rue et l'angle du retrait ;
     « A tower of unlimited height was allowed on 25 percent of lot ».
3. Carol Willis, The Skyscraper Museum, « How the 1916 Zoning Law Shaped Manhattan's Central Business Districts » (2016)
   <https://old.skyscraper.org/zoning/>
   - districts 1, 1¼, 1½, 2, 2½ fois ; exemple 1½ fois sur une rue de 100 pieds : façade verticale jusqu'à 150 pieds, puis
     un pied de recul pour trois pieds de hauteur ; 2 fois : 200 pieds, puis 1 pour 4 ; plan diagonal projeté « from the
     center of the street » ; premier retrait vers 90 pieds sur les rues transversales, 150 à 200 sur les avenues ;
     tour illimitée sur 25 % du terrain.
   - Déduction (cohérente avec les deux exemples) : le plan part de l'axe de la rue, au sol, et passe par le point
     (alignement, m × largeur) : sa pente est 2m (4 pour 1 en district « deux fois »).
4. The Skyscraper Museum, « Impact of 1916 Zoning » <https://skyscraper.org/skyline/impact-of-1916-zoning/>
   - profondeur maximale d'un bureau : 28 pieds (8,5 m) de la fenêtre au couloir et au noyau d'ascenseurs.
5. The Skyscraper Museum, « The 1961 Zoning Law » <https://old.skyscraper.org/EXHIBITIONS/DOWNTOWN_NEW_YORK/CONTENT/dny_law21.htm>
   - principe du FAR ; zonage incitatif : étages en plus contre places, arcades, entrées de métro ; tour nue : de 25 à 40 %
     du terrain.
6. Ville de New York, Zoning Resolution, texte en vigueur (dernière modification le 5 décembre 2024)
   - 33-432 <https://zr.planning.nyc.gov/print/pdf/node/17760> : C5, C6 : mur de façade de 85 pieds ou six étages au plus ;
     retrait initial 20 pieds sur rue étroite, 15 sur rue large ; plan d'exposition au ciel à 85 pieds au-dessus de la
     ligne de rue, pente 2,7 pour 1 (rue étroite) et 5,6 pour 1 (rue large).
   - 33-451 <https://zr.planning.nyc.gov/print/pdf/node/17766> : tour sur 40 % du terrain au plus ; à 15 pieds au moins
     d'une rue étroite, 10 pieds d'une rue large.
   - 33-454 <https://zr.planning.nyc.gov/print/pdf/node/17765> : petits terrains : 50 % jusqu'à 10 500 pi², puis un point
     de moins par tranche de 1 000 pi², 41 % jusqu'à 19 999 pi².
   - 33-122 <https://zr.planning.nyc.gov/index.php/article-iii/chapter-3/33-122> : FAR 15,00 en C5-3, C5-5, C6-6, C6-7,
     C6-9 ; 10,00 en C5-2, C6-4.
7. MCNY, « Plazas » <https://thegreatestgrid.mcny.org/greatest-grid/plazas> : bonus de surface contre une place ; le
   Seagram Building comme modèle ; places qui rompent l'alignement.
8. Godot 4.7.2, doc/classes : OccluderInstance3D, ProjectSettings rendering/occlusion_culling/use_occlusion_culling
   (coût processeur ; « Large open scenes generally benefit more from mesh LOD and visibility ranges » ; déplacer un
   occulteur rarement, par exemple pour la génération procédurale).

## Pas encore vérifié (les outils web sont bloqués jusqu'à 10 h)
- brique : formats et appareils (Brick Industry Association, TN 10 et TN 30) ;
- hauteurs d'étage de bureaux (CTBUH) ; trame des murs-rideaux ;
- largeur des trottoirs (MCNY « Sidewalks ») ; définition d'une « wide street » (75 pieds ?) dans le Zoning Resolution.

## Plan des 13 étapes (même ossature que Paris et Tokyo)
001 Building : une tour, piliers et bandeaux (une bande par étage, un pilier par travée : le mur autour des trous, à
    l'échelle d'une tour) ; quatre façades ; un noyau sombre derrière.
002 Shader : brique, appareil à boutisses (un rang de boutisses toutes les six assises) ; MeshBuilder ; matériaux.
003 Shader : le bruit : teinte par brique, suie, coulures sous les appuis.
004 Building + Shader : fenêtres à guillotine, rectangles instanciés.
005 Shader : bureaux derrière la vitre, la nuit (profondeur 8,5 m : les 28 pieds de 1916).
006 Building : les gradins du règlement de 1916 (liste de gradins ; base de pierre ; tour sur 25 %).
007 Building + Shader : la tour de verre de 1961 : mur-rideau dessiné par le shader sur un rectangle par face ;
    la pièce derrière la vitre passe dans un .gdshaderinc partagé ; place devant la tour ; 40 % ; FAR 15.
008 Building : profils : chaperons de gradins, ailettes verticales des murs-rideaux, marquise.
009 Building + Shader : couronnement : flèche, gradins de couronne, château d'eau, écran de machinerie ;
    shader de couronne (acier à chevrons, cuivre, bois du château d'eau) ; couronne éclairée la nuit.
010 Building + Shader : rez-de-chaussée : hall, porte tambour, numéro, boutiques ; listes dans 5_data.
011 Variation : la graine (famille, couronne, teintes, retraits).
012 Variation : le quartier : avenue et rues, îlots de 200 pieds, parcelles traversantes, deux règlements ;
    trottoirs, passages piétons, feux, lampadaires, cheminées de vapeur, entrée de métro.
013 Performance : niveaux de détail (de loin, une façade de briques devient un rectangle dessiné par le shader du
    mur-rideau) et occultation (un occulteur par gradin).

## Vérifié à 10 h 20
9. Brick Industry Association, Technical Notes 10, « Dimensioning and Estimating Brick Masonry », février 2009
   <https://gobrick.com/media/file/10-dimensioning-and-estimating-brick-masonry.pdf>
   - brique modulaire : nominale 4 × 2⅔ × 8 in (102 × 68 × 203 mm), spécifiée 3⅝ × 2¼ × 7⅝ in (92 × 57 × 194 mm) ;
     joint ⅜ in (9,5 mm) ; trois assises = 8 in (203 mm). Brique « standard » : 3⅝ × 2¼ × 8 in.
10. Technical Notes 30, « Bonds and Patterns in Brickwork », mars 1999 (gobrick.com)
   <https://gobrick.com/media/file/30-bonds-and-patterns-in-brickwork.pdf>
   - common bond (American bond) : running bond avec un rang de boutisses pleines à intervalles réguliers,
     « Header courses usually appear at every fifth, sixth or seventh course » ; running bond : que des panneresses.
11. Zoning Resolution, section 12-10, définitions, reproduites par CUNY City Tech (OpenLab) :
   <https://openlab.citytech.cuny.edu/bt3t1/zoning-text/>
   - « A “wide street” is any #street# 75 feet or more in width » ; « A “narrow street” is any #street# less than 75 feet
     wide ». (Page officielle 12-10 : non lue, adresse construite refusée.)
- Non trouvés : hauteurs d'étage (CTBUH ne les publie pas sur son calculateur), largeur des trottoirs (MCNY non).
  → cotes plausibles, à signaler comme non relevées.
