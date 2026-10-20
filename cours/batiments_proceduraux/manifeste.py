"""Ce que contient chaque projet d'étape du cours « bâtiments procéduraux ». Lu par usine/cours/fabriquer.py.

Trois villes, treize étapes chacune. Pour chaque ville : les titres des étapes, les fichiers maîtres et leurs
étapes de présence, les scènes (l'immeuble, puis la rue ou le quartier) et la scène de visite.
"""

# Numéro de la dernière étape.
DERNIERE = 13

M = "6_assets/Mesh/Procedural/DECORS/Building/{NAME}"
SH = "6_assets/Shader/Procedural/DECORS/Building/{NAME}"
D = "5_data/DECORS/Building/{NAME}"

ETAPES_PARIS = [
    {"piste": "Building", "titre": "Un mur percé de baies"},
    {"piste": "Shader", "titre": "Pierre de taille : assises et joints"},
    {"piste": "Shader", "titre": "Le bruit : teinte par bloc, suie, relief"},
    {"piste": "Building + Shader", "titre": "Fenêtres à petits bois"},
    {"piste": "Shader", "titre": "Une pièce derrière la vitre, la nuit"},
    {"piste": "Building", "titre": "Niveaux : soubassement, étage noble, dernier étage"},
    {"piste": "Building + Shader", "titre": "Balcons filants et ferronnerie"},
    {"piste": "Building", "titre": "Moulures par profils extrudés"},
    {"piste": "Building + Shader", "titre": "Comble en zinc, lucarnes, cheminées"},
    {"piste": "Building + Shader", "titre": "Porte, boutiques, enseignes"},
    {"piste": "Variation", "titre": "La graine : un immeuble différent à chaque tirage"},
    {"piste": "Variation", "titre": "La rue : parcelles, gabarit, régularité"},
    {"piste": "Performance", "titre": "Niveaux de détail : ne dessiner que ce qui se voit"},
]

ETAPES_TOKYO = [
    {"piste": "Building", "titre": "Un mur percé de baies, immeuble étroit"},
    {"piste": "Shader", "titre": "Carrelage : carreaux et joints"},
    {"piste": "Shader", "titre": "Le bruit : teinte par carreau, coulures, relief"},
    {"piste": "Building + Shader", "titre": "Fenêtres coulissantes en aluminium"},
    {"piste": "Shader", "titre": "Une pièce derrière la vitre, bureaux éclairés"},
    {"piste": "Building", "titre": "Niveaux : commerce et étages"},
    {"piste": "Building + Shader", "titre": "Balcons, garde-corps, climatiseurs"},
    {"piste": "Building", "titre": "Auvent, acrotère, descentes d'eau"},
    {"piste": "Building + Shader", "titre": "Toit-terrasse, réservoir, gabarit oblique"},
    {"piste": "Building + Shader", "titre": "Devanture, rideau métallique, enseignes"},
    {"piste": "Variation", "titre": "La graine : un immeuble différent à chaque tirage"},
    {"piste": "Variation", "titre": "La rue : parcelles étroites, hauteurs libres"},
    {"piste": "Performance", "titre": "Niveaux de détail : ne dessiner que ce qui se voit"},
]

ETAPES_NEW_YORK = [
    {"piste": "Building", "titre": "Une tour : piliers et bandeaux"},
    {"piste": "Shader", "titre": "Brique : appareil et joints"},
    {"piste": "Shader", "titre": "Le bruit : teinte par brique, suie, coulures"},
    {"piste": "Building + Shader", "titre": "Fenêtres à guillotine"},
    {"piste": "Shader", "titre": "Une pièce derrière la vitre, bureaux la nuit"},
    {"piste": "Building", "titre": "Gradins : le règlement de 1916"},
    {"piste": "Building + Shader", "titre": "Mur-rideau : tours de verre, de 1961 à aujourd'hui"},
    {"piste": "Building", "titre": "Profils : chaperons, ailettes, marquise"},
    {"piste": "Building + Shader", "titre": "Couronnement : flèche, château d'eau, machinerie"},
    {"piste": "Building + Shader", "titre": "Rez-de-chaussée : hall, porte tambour, boutiques"},
    {"piste": "Variation", "titre": "La graine : une tour différente à chaque tirage"},
    {"piste": "Variation", "titre": "Le quartier : avenue, rues, deux règlements"},
    {"piste": "Performance", "titre": "Niveaux de détail et occultation"},
]


# --- Scènes et visite. Une scène : (suffixe, nom du nœud, variables[, suffixe du script]).
# Une visite : la scène montrée (« scene », « noeud »), les réglages de la visite, les visites en plus (« autres »),
# ou plusieurs instances côte à côte (« instances » : suffixe, nœud, position[, variables]).

def scenes_paris(etape):
    scenes = [("", "BuildingParisien", {})]
    if etape >= 12:
        scenes.append(("_rue", "RueParisienne", {}))
    return scenes


def visite_paris(etape):
    if etape >= 12:
        return {
            "scene": "_rue",
            "noeud": "Street",
            "reglages": {
                "ground": "false",
                "auto_frame": "false",
                "camera_position": "Vector3(-40, 1.7, 2.5)",
                "camera_target": "Vector3(10, 9.5, -1.5)",
                "camera_fov": "62.0",
            },
            "autres": {
                "step_viewer_immeuble": {"scene": "", "noeud": "Building", "reglages": {}, "sous_titre": "un immeuble seul"},
            },
        }
    return {"scene": "", "noeud": "Building", "reglages": {}}


def scenes_tokyo(etape):
    scenes = [("", "BuildingTokyoiste", {})]
    if etape >= 12:
        scenes.append(("_rue", "RueTokyoiste", {}))
    return scenes


def visite_tokyo(etape):
    if etape >= 12:
        return {
            "scene": "_rue",
            "noeud": "Street",
            "reglages": {
                "ground": "false",
                "auto_frame": "false",
                "camera_position": "Vector3(-38, 1.65, 0.5)",
                "camera_target": "Vector3(0, 7.5, 0)",
                "camera_fov": "58.0",
            },
            "autres": {
                "step_viewer_immeuble": {"scene": "", "noeud": "Building", "reglages": {}, "sous_titre": "un immeuble seul"},
            },
        }
    return {"scene": "", "noeud": "Building", "reglages": {}}


# Écart entre deux terrains voisins dans la visite des trois tours : une avenue de 100 pieds,
# et la largeur d'un terrain.
ECART_NEW_YORK = 45.0 + 30.48
# Les graines de la visite de l'étape 011 : quatre tirages qui montrent les trois familles.
GRAINES_NEW_YORK = [1, 2, 3, 4]


def famille_new_york(etape, famille):
    """La famille d'une scène de tour : à partir de l'étape 11, la variable s'appelle
    « family_choice » et sa liste commence par « Selon la graine »."""
    if etape >= 11:
        return {"family_choice": str(famille + 1)}
    return {"family": str(famille)}


def scenes_new_york(etape):
    scenes = [("", "BuildingNewyorkais", {})]
    if etape >= 7:
        # Les deux tours de verre : le même script que la tour de brique, d'autres variables.
        # Elles sont posées à droite de la tour de brique, de l'autre côté d'une avenue.
        scenes.append(("_verre", "BuildingNewyorkais", {
            **famille_new_york(etape, 1),
            "street_left": "30.48",
            "street_right": "30.48",
        }, ""))
        scenes.append(("_verre_integral", "BuildingNewyorkais", {
            **famille_new_york(etape, 2),
            "street_left": "30.48",
            "street_right": "0.0",
            "glass_tower_share": "0.3",
            "floor_height": "4.2",
            "glass_tint": "Color(0.58, 0.68, 0.78, 1)",
            "spandrel_color": "Color(0.1, 0.13, 0.17, 1)",
            "metal_color": "Color(0.72, 0.74, 0.76, 1)",
        }, ""))
    if etape >= 12:
        scenes.append(("_quartier", "QuartierNewyorkais", {}))
    return scenes


# Une tour se regarde de loin : la visite élargit l'objectif et porte les ombres plus loin.
VUE_TOUR_NEW_YORK = {"camera_fov": "45.0", "shadow_distance": "450.0"}


def trois_tours_new_york():
    """Les trois familles côte à côte, chacune sur son terrain, une avenue entre deux."""
    return {
        "reglages": dict(VUE_TOUR_NEW_YORK),
        "instances": [
            ("", "Brique", (-ECART_NEW_YORK, 0.0, 0.0)),
            ("_verre", "Verre1961", (0.0, 0.0, 0.0)),
            ("_verre_integral", "ToutVerre", (ECART_NEW_YORK, 0.0, 0.0)),
        ],
    }


def visite_new_york(etape):
    if etape >= 12:
        return {
            "scene": "_quartier",
            "noeud": "District",
            "reglages": {
                "ground": "false",
                "auto_frame": "false",
                "camera_position": "Vector3(-12.5, 1.7, 38)",
                "camera_target": "Vector3(-4, 30, -120)",
                "camera_fov": "62.0",
                "shadow_distance": "450.0",
            },
            "autres": {
                "step_viewer_tours": dict(trois_tours_new_york(), sous_titre="les trois familles"),
            },
        }
    if etape == 11:
        # La graine : quatre fois la même scène, tout laissé au hasard, sous quatre graines.
        tirees = {"family_choice": "0", "crown_choice": "0", "window_lights": "0", "random_massing": "true",
                  "random_colors": "true"}
        return {
            "reglages": dict(VUE_TOUR_NEW_YORK),
            "instances": [
                ("", f"Graine{graine}", ((rang - 1.5) * ECART_NEW_YORK, 0.0, 0.0), dict(tirees, variation_seed=str(graine)))
                for rang, graine in enumerate(GRAINES_NEW_YORK)
            ],
        }
    if etape >= 7:
        return trois_tours_new_york()
    return {"scene": "", "noeud": "Building", "reglages": dict(VUE_TOUR_NEW_YORK)}


def reglages_new_york(etape):
    """À partir de l'étape 13, les tours posent des boîtes d'occultation : le projet doit
    activer l'occultation, sans quoi le moteur les ignore."""
    if etape >= 13:
        return ["occlusion_culling/use_occlusion_culling=true"]
    return []


VILLES = {
    "parisien": {
        "nom": "Paris",
        "etapes": ETAPES_PARIS,
        "pretes": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
        "scenes": scenes_paris,
        "visite": visite_paris,
        "fichiers": [
            # (maître, destination, première étape, dernière étape)
            ("batiment_001.gd", M + ".gd", 1, 1),
            ("batiment.gd", M + ".gd", 2, DERNIERE),
            ("materiaux.gd", M + "_materiaux.gd", 2, DERNIERE),
            ("profils.gd", M + "_profils.gd", 8, DERNIERE),
            ("toit.gd", M + "_toit.gd", 9, DERNIERE),
            ("porte.gd", M + "_porte.gd", 10, DERNIERE),
            ("boutique.gd", M + "_boutique.gd", 10, DERNIERE),
            ("rue.gd", M + "_rue.gd", 12, DERNIERE),
            ("palette.gd", D + "_palette.gd", 10, DERNIERE),
            ("pierre.gdshader", SH + "_pierre.gdshader", 2, DERNIERE),
            ("fenetre.gdshader", SH + "_fenetre.gdshader", 4, DERNIERE),
            ("ferronnerie.gdshader", SH + "_ferronnerie.gdshader", 7, DERNIERE),
            ("zinc.gdshader", SH + "_zinc.gdshader", 9, DERNIERE),
            ("bois.gdshader", SH + "_bois.gdshader", 10, DERNIERE),
            ("store.gdshader", SH + "_store.gdshader", 10, DERNIERE),
        ],
    },
    "tokyoiste": {
        "nom": "Tokyo",
        "etapes": ETAPES_TOKYO,
        "pretes": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
        "scenes": scenes_tokyo,
        "visite": visite_tokyo,
        "fichiers": [
            ("batiment_001.gd", M + ".gd", 1, 1),
            ("batiment.gd", M + ".gd", 2, DERNIERE),
            ("materiaux.gd", M + "_materiaux.gd", 2, DERNIERE),
            ("profils.gd", M + "_profils.gd", 8, DERNIERE),
            ("toit.gd", M + "_toit.gd", 9, DERNIERE),
            ("devanture.gd", M + "_devanture.gd", 10, DERNIERE),
            ("enseignes.gd", M + "_enseignes.gd", 10, DERNIERE),
            ("rue.gd", M + "_rue.gd", 12, DERNIERE),
            ("palette.gd", D + "_palette.gd", 9, DERNIERE),
            ("carrelage.gdshader", SH + "_carrelage.gdshader", 2, DERNIERE),
            ("fenetre.gdshader", SH + "_fenetre.gdshader", 4, DERNIERE),
            ("garde_corps.gdshader", SH + "_garde_corps.gdshader", 7, DERNIERE),
            ("beton.gdshader", SH + "_beton.gdshader", 9, DERNIERE),
            ("rideau.gdshader", SH + "_rideau.gdshader", 10, DERNIERE),
            ("enseigne.gdshader", SH + "_enseigne.gdshader", 10, DERNIERE),
            ("test.gd", "7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{NAME}.gd", 1, DERNIERE),
        ],
        # Le test de Tokyo vérifie le gabarit oblique : il a son propre maître.
        "sans_commun": ["7_tests/test.gd"],
        "roles": {
            "profils.gd": "Les profils des pièces de métal plié",
            "toit.gd": "Le toit-terrasse : acrotères, édicule, réservoir",
            "devanture.gd": "La devanture du rez-de-chaussée",
            "enseignes.gd": "Les enseignes, le distributeur, la lanterne",
            "rue.gd": "La rue : parcelles, hauteurs, poteaux et fils",
            "palette.gd": "Les données : règlements, noms, teintes",
            "fenetre.gdshader": "Shader de la fenêtre coulissante et de la pièce derrière la vitre",
            "garde_corps.gdshader": "Shader des garde-corps et des grilles d'aluminium",
            "beton.gdshader": "Shader du béton brut",
            "rideau.gdshader": "Shader du rideau métallique",
            "enseigne.gdshader": "Shader des enseignes",
        },
    },
    "newyorkais": {
        "nom": "New York",
        "etapes": ETAPES_NEW_YORK,
        "pretes": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
        "scenes": scenes_new_york,
        "visite": visite_new_york,
        "fichiers": [
            ("batiment_001.gd", M + ".gd", 1, 1),
            ("batiment.gd", M + ".gd", 2, DERNIERE),
            ("materiaux.gd", M + "_materiaux.gd", 2, DERNIERE),
            ("palette.gd", D + "_palette.gd", 6, DERNIERE),
            ("brique.gdshader", SH + "_brique.gdshader", 2, DERNIERE),
            ("fenetre.gdshader", SH + "_fenetre.gdshader", 4, DERNIERE),
            ("profils.gd", M + "_profils.gd", 8, DERNIERE),
            ("couronne.gd", M + "_couronne.gd", 9, DERNIERE),
            ("rez_de_chaussee.gd", M + "_rez_de_chaussee.gd", 10, DERNIERE),
            ("quartier.gd", M + "_quartier.gd", 12, DERNIERE),
            ("bureau.gdshaderinc", SH + "_bureau.gdshaderinc", 7, DERNIERE),
            ("mur_rideau.gdshader", SH + "_mur_rideau.gdshader", 7, DERNIERE),
            ("couronne.gdshader", SH + "_couronne.gdshader", 9, DERNIERE),
            ("bronze.gdshader", SH + "_bronze.gdshader", 10, DERNIERE),
            ("facade_lointaine.gdshader", SH + "_facade_lointaine.gdshader", 13, DERNIERE),
            ("test.gd", "7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{NAME}.gd", 1, DERNIERE),
        ],
        # Le test de New York vérifie les deux règlements de zonage : il a son propre maître.
        "sans_commun": ["7_tests/test.gd"],
        # Lignes ajoutées à la section [rendering] des réglages du projet.
        "reglages_en_plus": reglages_new_york,
        "roles": {
            "batiment_001.gd": "La tour : variables, puis les triangles, écrits à la main",
            "batiment.gd": "La tour : variables, gradins, façades",
            "materiaux.gd": "Les matériaux : un shader et ses réglages par matière",
            "profils.gd": "Les profils : chaperons, bandeau, ailettes",
            "couronne.gd": "Le couronnement et le château d'eau",
            "couronne.gdshader": "Shader du couronnement : cuivre, acier, ventelles, bois",
            "rez_de_chaussee.gd": "Le rez-de-chaussée : entrée, portes tambour, boutiques",
            "bronze.gdshader": "Shader du bronze, poli à hauteur de main",
            "palette.gd": "Les données : trame de Manhattan, règlements de zonage",
            "brique.gdshader": "Shader de la brique et de la pierre",
            "fenetre.gdshader": "Shader de la fenêtre à guillotine et de la pièce derrière la vitre",
            "bureau.gdshaderinc": "La pièce derrière la vitre, partagée par deux shaders",
            "mur_rideau.gdshader": "Shader du mur-rideau des tours de verre",
            "facade_lointaine.gdshader": "Shader de la façade lointaine : toute une façade sur un rectangle",
            "scene": "Scène de la tour : un nœud, son script, ses variables",
            "scene_verre": "Scène de la tour de verre de 1961 : le même script, d'autres variables",
            "scene_verre_integral": "Scène de la tour tout en verre : le même script, d'autres variables",
            "scene_quartier": "Scène du quartier : un nœud, son script, ses variables",
            "quartier.gd": "Le quartier : trame, terrains, tours, rues",
            "visite_autre": "Seconde scène de visite : les trois familles de tours",
        },
    },
}

# Fichiers communs aux trois villes : (source dans commun/, destination, première étape).
COMMUN = [
    ("0_autoload/LISEZMOI.md", "0_autoload/LISEZMOI.md", 1),
    ("3_entities/LISEZMOI.md", "3_entities/LISEZMOI.md", 1),
    ("5_data/LISEZMOI.md", "5_data/LISEZMOI.md", 1),
    ("1_core/camera/free_camera.gd", "1_core/camera/free_camera.gd", 1),
    ("1_core/camera/free_camera_input.gd", "1_core/camera/free_camera_input.gd", 1),
    ("1_core/data/visit_settings.gd", "1_core/data/visit_settings.gd", 1),
    ("5_data/visit/visit_settings.tres", "5_data/visit/visit_settings.tres", 1),
    ("1_core/procedural/mesh_builder.gd", "1_core/procedural/mesh_builder.gd", 2),
    ("2_sequence/step_viewer/step_viewer.gd", "2_sequence/step_viewer/step_viewer.gd", 1),
    ("4_ui/step_banner/step_banner.gd", "4_ui/step_banner/step_banner.gd", 1),
    ("6_assets/Shader/Procedural/procedural_commun.gdshaderinc", "6_assets/Shader/Procedural/procedural_commun.gdshaderinc", 2),
    ("7_tests/test.gd", "7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{NAME}.gd", 1),
]

# Rôle de chaque fichier, pour le tableau de la note de l'étape. Clé : le nom du maître.
ROLES = {
    "batiment_001.gd": "L'immeuble : variables, puis les triangles, écrits à la main",
    "batiment.gd": "L'immeuble : variables et composition de la façade",
    "materiaux.gd": "Les matériaux : un shader et ses réglages par matière",
    "profils.gd": "Les profils des moulures",
    "toit.gd": "Le comble : pans, lucarnes, cheminées",
    "porte.gd": "La porte d'entrée",
    "boutique.gd": "Les boutiques du rez-de-chaussée",
    "rue.gd": "La rue : parcelles, gabarit, tirages",
    "palette.gd": "Les données : noms, teintes, table du gabarit",
    "pierre.gdshader": "Shader de la pierre de taille",
    "carrelage.gdshader": "Shader du carrelage de façade",
    "fenetre.gdshader": "Shader de la fenêtre et de la pièce derrière la vitre",
    "ferronnerie.gdshader": "Shader des garde-corps de fer",
    "zinc.gdshader": "Shader du zinc du toit",
    "bois.gdshader": "Shader du bois peint",
    "store.gdshader": "Shader de la toile des stores",
    "free_camera.gd": "Caméra libre de la visite : elle avance selon les intentions qu'on lui donne",
    "free_camera_input.gd": "Entrées de la caméra libre : clavier et souris, traduits en intentions",
    "visit_settings.gd": "Réglages de la visite : la classe (ciel, soleil, sol, cadrage, qualité)",
    "visit_settings.tres": "Réglages de la visite : les valeurs",
    "mesh_builder.gd": "Outil de maillage générique",
    "step_viewer.gd": "La visite : ciel, soleil, sol, jour et nuit, qualité",
    "step_banner.gd": "Le bandeau : titre, aide, mesure du rendu",
    "procedural_commun.gdshaderinc": "Fonctions communes à tous les shaders",
    "test.gd": "Le test de l'étape",
    "scene": "Scène de l'immeuble : un nœud, son script, ses variables",
    "scene_rue": "Scène de la rue : un nœud, son script, ses variables",
    "visite": "Scène principale : la visite",
    "visite_autre": "Seconde scène de visite : un immeuble seul",
    "projet": "Réglages du projet Godot",
}
