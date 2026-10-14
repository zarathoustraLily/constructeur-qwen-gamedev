# Tokyo — notes de travail (à relire après une coupure de contexte)

## Sources vérifiées le 11 octobre 2026 (pages lues, citations exactes)

1. **Gabarit oblique sur rue (道路斜線制限)** — Arrondissement d'Ōta, « 建物の高さについての制限 »
   <https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/tatemono_tyuuikisei/takasaseigen.html>
   - pente 1,25 dans les zones d'habitation (第1種/第2種低層住居専用, 第1種/第2種中高層住居専用, 第1種/第2種住居, 準住居) ; 1,5 dans les autres zones (その他の地域 1.5) ;
   - mesurée depuis la limite OPPOSÉE de la voie (前面道路の反対側の境界線) ;
   - ne s'applique que jusqu'à une « distance d'application » (適用距離) de 20, 25, 30 ou 35 m selon la zone et le COS ;
   - si l'immeuble est en retrait, la limite opposée est réputée reculée d'autant (後退した距離に相当する分だけ…外側にあるものとみなされます).
   - Loi sur les normes de construction (建築基準法), art. 56 : numéro donné par ma recherche, pas lu dans le texte de loi.
2. **Enseignes en saillie** — Bureau des routes nationales de Tokyo (国土交通省 関東地方整備局 東京国道事務所), « 占用許可申請の詳細 »
   <https://www.ktr.mlit.go.jp/toukoku/toukoku00078.html>
   - enseignes en drapeau (突出看板) et stores (日除け) : saillie ≤ 1,0 m ;
   - enseignes murales (壁面看板) : saillie ≤ 0,3 m ;
   - bas de l'enseigne à 2,5 m au moins du sol (最下部と路面との距離は、高さ2.5m以上).
   - Ce sont les règles de CE gestionnaire, pour les routes nationales qu'il gère. Pas une règle générale vérifiée.
3. **50 cm de la limite** — Code civil japonais, art. 234 : « 建物を築造するには、境界線から50センチメートル以上の距離を保たなければならない。 »
   Cité par un géomètre-expert (土地家屋調査士 奥野尚彦), Q&A professionnel, <https://smtrc.jp/useful/qa/kyokaihikai/qa-kyokaihikai_06.html>,
   qui cite aussi l'exception de la loi sur les normes de construction : dans les zones de prévention des incendies, un mur
   extérieur résistant au feu peut être bâti sur la limite (numéro d'article NON confirmé : ne pas le donner).
4. **Largeur des voies** — Arrondissement d'Ōta, « 2項道路 »
   <https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/k_douro/douro.html>
   - une voie au sens de la loi fait en principe 4 m au moins (建築基準法の道路は、本来幅員が4メートル以上) ;
   - les ruelles anciennes de 1,8 m à 4 m sont réputées voies, à condition de reculer à 2 m de l'axe (道路の中心から2メートル後退).
5. **Garde-corps 1,10 m** — Réponse du Cabinet à la Chambre des représentants, n° 48 (内閣衆質二〇三第四八号), 8 décembre 2020
   <https://www.shugiin.go.jp/internet/itdb_shitsumon.nsf/html/shitsumon/b203048.htm>
   - le règlement d'application de la loi (建築基準法施行令 第126条第1項) impose, autour des toits-terrasses d'évacuation
     (屋上広場等), un garde-corps, une clôture ou un grillage d'au moins 1,1 m. Le cours prend la même hauteur pour les balcons
     (extension NON vérifiée dans le texte).

## Non vérifié (à dire tel quel dans les notes)
- Formats de carreaux : 二丁掛 227 × 60 mm, 小口平 108 × 60 mm, 45二丁 95 × 45 mm, 50角 45 × 45 mm : cotes nominales citées de
  mémoire, pas relues dans un catalogue.
- Verre armé (網入りガラス), poteaux électriques, réservoirs de toit, 雑居ビル : observation courante, pas de source lue ici
  (essai de K. Varnelis sur les zakkyo biru lu plus tôt dans la conversation, sans URL conservée).
- Toutes les cotes d'immeuble (hauteurs d'étage, largeurs de travée, tailles de fenêtre) : plausibles, non relevées.

## Plan des 13 étapes (parallèle à Paris)
001 mur percé, immeuble étroit · 002 carrelage : carreaux et joints · 003 bruit : teinte par carreau, coulures, relief ·
004 fenêtres coulissantes en aluminium · 005 pièce derrière la vitre, bureaux éclairés · 006 niveaux : commerce et étages ·
007 balcons, garde-corps, climatiseurs · 008 auvent, acrotère, descentes d'eau (profils extrudés) ·
009 toit-terrasse, réservoir, gabarit oblique (+ shader béton) · 010 devanture, rideau métallique, enseignes (+ palette 5_data) ·
011 la graine · 012 la rue : parcelles étroites, hauteurs libres (+ poteaux et fils) · 013 niveaux de détail.

## Décisions
- Touche de qualité : P (pas Q : collision AZERTY avec la caméra). Corrigé dans common le 11/10 à 23 h 28.
- Test de Tokyo : maître propre au style (master/tokyoiste/test.gd), pour ne pas toucher aux fichiers de Paris déjà livrés.
- Enseignes : Label3D + SystemFont (polices japonaises du système), variable pour passer en lettres latines.
- Retrait des étages : tout l'étage recule de `_setback` ; les étages qui n'ont plus la place ne sont pas montés.

6. **Polices japonaises de Windows** — Microsoft Learn, « Windows 11 font list »
   <https://learn.microsoft.com/typography/fonts/windows_11_font_list>
   - « Yu Gothic » et « MS Gothic » sont dans la liste de base de Windows 11 ; « Meiryo » est dans les polices
     supplémentaires japonaises (à installer). D'où l'ordre : Yu Gothic, MS Gothic, Meiryo, puis polices Mac et Linux.

7. **Garde-corps à barreaux et gabarit** — Arrondissement de Nakano, « 高さ制限における屋上や途中階のパイプ手すりについて 令2条1項6号ハ », 1er septembre 2022
   <https://www.city.tokyo-nakano.lg.jp/machizukuri/kenchiku/tetsuzuki/kakunin-shinsei/kenchikukijyunho.files/tesuri20220901.pdf>
   - condition : « 手すりが縦桟のパイプ状のもので、見通しがきき、採光通風に影響のないもの » ; les panneaux et tôles perforées sont exclus ;
   - « 道路斜線、隣地斜線は、バルコニーや屋外廊下の手すりで、1.に該当するものは高さに算入しなくてもよい » :
     pour le gabarit sur rue, un garde-corps à barreaux verticaux de balcon peut ne pas être compté dans la hauteur.
   - D'où la règle du cours : les terrasses des étages en retrait ont TOUJOURS un garde-corps à barreaux (non compté) ;
     l'acrotère plein du toit, lui, est compté. C'est la pratique de CET arrondissement.

## Conception de l'immeuble (résumé)
- Façade z = 0, vers +Z. `_setback` : recul du niveau courant (gabarit). Logements : balcon EN CREUX (loggia) : le mur
  des fenêtres recule de `balcony_depth`, le garde-corps reste au nu de la façade ; murs d'aile aux deux bouts ; poutre de
  rive en haut ; dalle [base_y, base_y + 0.12].
- Niveaux : rez-de-chaussée (boutique à partir de 010), `office_floors` étages de bureaux (fenêtres en bandeau, au nu),
  puis des logements. Travée d'escalier (`core_side`) : petites fenêtres dépolies, porte au rez-de-chaussée.
- Fenêtres : un seul matériau ; INSTANCE_CUSTOM = (sorte de pièce, hauteur d'allège, restaurant, -).
- Enseignes : rectangles instanciés (shader enseigne) ; COLOR = fond ; CUSTOM = (nb caractères, vertical, graine, sorte).
  De près : Label3D (vrai texte) ; au-delà : fausse écriture du shader.

## État au 12 octobre, 0 h 55
- Tokyo : tous les maîtres écrits et balisés (master/tokyoiste/*), les 13 étapes se génèrent, s'importent, passent leur test
  et le contrôle des avertissements GDScript (lint.sh) ; rendus Compatibilité de toutes les étapes, Forward+ et Mobile de la
  rue (sans erreur). Robustesse de la rue : 17 cas extrêmes sans erreur (tmp/dev_tk/dev_street.gd).
- Corrigé en passant dans common : mesh_builder.gd (variable locale « box » -> « own », étape 013) : Paris 013 change.
- Reste : notes md de Tokyo (13), notes jumelles (26), LISEZMOI, PDF, livraison finale (archive unique), pont vers D:.
- Pièges : profondeur mesurée grossièrement de loin en Compatibilité -> jamais deux faces à moins de 3 cm dans les zones
  moyenne et lointaine ; lint.sh pour les avertissements ; pkill par nom de processus (pkill Godot_v4), jamais -f.

## État au 12 octobre, 5 h 50
- Relecture de 012 et 013 : corrigés la règle des 50 cm (deux voisins à 1 m AU MOINS), la hauteur à l'alignement
  (rez-de-chaussée + un étage dans 6 m), « box() orienté » et « cône à deux rayons » déjà vus en 010, 300 -> ~260 fenêtres,
  fil plus fin qu'un pixel dès ~15 m (720p, champ 58°), joint de 8 mm dès ~5-8 m (note 002 et commentaire du shader).
- Rue : max_gap = 2 × BOUNDARY_DISTANCE (1 m), street_width borné par Palette.MIN_ROAD_WIDTH ; tirages toujours lancés
  (balcon, auvent, édicule, panneau de toit, part de bureaux). randi_range(a, a) NE consomme PAS de tirage (vérifié) ;
  randf_range(a, a) si. Palette : SIGN_RED_INK et PAINT_COLORS supprimés ; TILE_COLORS et FRAME_COLORS passés à 12+ ;
  WALL_SIGN_MAX_PROJECTION utilisé par fascia().
- Shader des enseignes (13+) : la fausse écriture suit la mise en page du Label3D (taille, centrage) : la bascule se voit
  beaucoup moins. Étapes 010 à 012 inchangées.
- Mesures (rue par défaut, 35 immeubles) : 45 318 triangles de près ; 012 : 272 ms ; 013 q1 sans LOD 255 ms ; q1 253 ms ;
  q0 151 ms ; q2 1 258 ms (deux passages de 90 images, dispersion 7 %). Objets 736/551/372, textes 117, ombres 253.
- Notes jumelles (26) écrites : md/<style>/jumeau_NNN.md, générées par tmp/twins.py.
- Paris : sources du gabarit appuyées sur deux documents de la Ville de Paris (Commission du Vieux Paris 2016 ; document
  sur le secteur sauvegardé du Marais, p. 260) ; Wikipédia gardé, signalé de seconde main, pour 11,70 et 14,62 m.
- Archive : deliver/001_Batiments_proceduraux_paris_et_tokyo.zip (26 projets vérifiés un par un, identiques aux maîtres).
- Livret PDF : book/build_book.py + book/book.css (Chromium via Playwright, deux passes pour le sommaire, signets pypdf).
