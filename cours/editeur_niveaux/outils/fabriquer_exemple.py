"""Fabrique les données d'exemple du cours « editeur_niveaux » : une planche d'assets fictifs, le catalogue, trois
salles, les ennemis et les effets d'un petit jeu qui suit le plan du roguelike V002. Même graine, mêmes fichiers.

Demandes de laurent du 2026-11-05 : « fais le cours et le débogage de l'éditeur de jeu » ; format de salle propre au
cours (« Format à nous ») ; « tu vérifies bien que ça peut fonctionner avec le jeu rogue_like_002 et que ça permettra
de paramétrer le jeu, d'éditer les niveaux, les FX, les animations, les collisions, les spawns, de choisir les
ennemis ». L'éditeur vit dans le projet du jeu (charte, §0 et §5) : il lit les mêmes classes de données
(`1_core/data/*.gd`) et les mêmes `.tres` (`5_data/`) que le jeu.

Sorties :
- `<source>/6_assets/exemple/planche.png` : la planche (binaire, dans le jeu source du cours : clé `editeur_niveaux`
  de [sources]) ;
- dans les maîtres : `5_data/catalogue/catalogue.tres`, `5_data/salles/<id>.tres`, `5_data/ennemis/<id>.tres`,
  `5_data/effets/<id>.tres`.

Une salle range ses choses en tableaux compacts, un tableau par champ (`thing_ids`, `thing_positions`…) : une salle
de plusieurs centaines de choses se charge d'un bloc, sans une ressource par chose.

    python cours/editeur_niveaux/outils/fabriquer_exemple.py [--source <dossier>] [--graine 7]
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
MAITRES = ICI.parent / "maitres"
SOURCE_DEFAUT = Path(r"D:\GODOT\PROJETS_DEMOS\PROJET_EDITEUR_NIVEAUX")
PLANCHE = "6_assets/exemple/planche.png"
CASE = 128
COLONNES = 8

# (id, catégorie, calque par défaut, taille en jeu en mètres (largeur, profondeur), couleur, forme)
ASSETS = [
    ("sol_tole", "sol", "sol", (4.0, 4.0), (92, 98, 110), "carre"),
    ("sol_panneaux", "sol", "sol", (4.0, 4.0), (196, 196, 184), "grille"),
    ("sol_caoutchouc", "sol", "sol", (4.0, 4.0), (48, 50, 54), "rayures"),
    ("sol_beton", "sol", "sol", (4.0, 4.0), (140, 134, 124), "carre"),
    ("detail_aeration", "detail", "detail_sol", (1.5, 1.5), (60, 64, 70), "grille"),
    ("detail_bandes", "detail", "detail_sol", (2.0, 0.5), (220, 180, 40), "rayures"),
    ("detail_huile", "detail", "detail_sol", (1.2, 1.0), (30, 28, 34), "tache"),
    ("detail_trappe", "detail", "detail_sol", (1.5, 1.5), (110, 116, 124), "disque"),
    ("caisse_cargo", "obstacle", "obstacles", (1.2, 1.2), (120, 96, 60), "carre"),
    ("fut_carburant", "obstacle", "obstacles", (0.9, 0.9), (200, 90, 40), "disque"),
    ("console", "obstacle", "obstacles", (1.4, 0.8), (40, 150, 150), "carre"),
    ("casiers", "obstacle", "obstacles", (1.6, 0.6), (150, 150, 160), "rayures"),
    ("reacteur", "obstacle", "obstacles", (3.0, 3.0), (60, 200, 190), "disque"),
    ("conteneur", "obstacle", "obstacles", (4.0, 2.4), (170, 70, 50), "rayures"),
    ("mur_droit", "obstacle", "obstacles", (4.0, 0.5), (130, 136, 146), "carre"),
    ("cloison", "obstacle", "obstacles", (3.0, 0.4), (220, 140, 40), "rayures"),
    ("tuyaux_plafond", "avant_plan", "avant_plan", (4.0, 1.0), (20, 24, 28), "rayures"),
    ("cables_pendants", "avant_plan", "avant_plan", (3.0, 1.0), (16, 18, 22), "tache"),
    ("lampe", "avant_plan", "avant_plan", (1.0, 1.0), (240, 200, 120), "disque"),
    ("porte_sas", "porte", "obstacles", (3.0, 0.6), (80, 200, 120), "carre"),
]
CALQUES = ["sol", "detail_sol", "obstacles", "avant_plan"]

# Rôles d'ennemis du plan de V002 (PLAN_DU_COURS.md, §5, valeurs proposées) :
# (id, nom, rôle, PV, repère m, vitesse m/s, portée m, préparation, tir, récupération, poids, dégâts, couleur)
ENNEMIS = [
    ("melee", "Mêlée", "melee", 50, 9, 3.0, 1.5, 0.6, 0.2, 1.2, 0.6, 3, (0.85, 0.35, 0.3)),
    ("brute", "Brute", "melee", 180, 7, 2.0, 2.0, 0.5, 0.3, 1.8, 1.5, 8, (0.6, 0.3, 0.2)),
    ("toupie", "Toupie", "melee", 40, 14, 4.5, 2.0, 1.0, 1.2, 1.0, 0.5, 4, (0.9, 0.7, 0.2)),
    ("cone", "Cône", "melee", 110, 8, 2.5, 4.0, 1.0, 2.5, 0.8, 1.0, 1, (0.4, 0.7, 0.3)),
    ("tireur", "Tireur", "distance", 70, 14, 2.5, 12.0, 0.8, 0.2, 1.2, 0.8, 3, (0.3, 0.5, 0.9)),
    ("racine", "Racine", "distance", 240, 16, 0.0, 18.0, 0.8, 1.5, 3.0, 2.0, 5, (0.3, 0.8, 0.6)),
    ("bombe", "Bombe", "melee", 60, 4, 2.0, 3.0, 0.5, 0.3, 0.0, 1.0, 7, (1.0, 0.5, 0.1)),
]
# (id, nom, particules par seconde, durée de vie s, taille m, couleur, additif)
EFFETS = [
    ("fumee", "Fumée", 12, 2.5, 0.8, (0.7, 0.7, 0.72, 0.6), False),
    ("etincelles", "Étincelles", 40, 0.6, 0.08, (1.0, 0.75, 0.3, 1.0), True),
    ("vapeur", "Vapeur", 20, 1.4, 0.5, (0.85, 0.95, 1.0, 0.5), False),
]


# --- écriture des .tres (texte de Godot) ---

def nombre(v: float | int) -> str:
    if float(v) == math.floor(float(v)) and abs(float(v)) < 2 ** 53:
        return str(int(v))
    return repr(round(float(v), 4))


def chaine(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def nombres(vals) -> str:
    return ", ".join(nombre(v) for v in vals)


def entete(classe: str, scripts: list[tuple[str, str, str]], n_sous: int = 0) -> list[str]:
    lignes = [f'[gd_resource type="Resource" script_class="{classe}" format=3]', ""]
    for ident, kind, chemin in scripts:
        lignes.append(f'[ext_resource type="{kind}" path="{chemin}" id="{ident}"]')
    lignes.append("")
    return lignes


# --- planche ---

def dessiner_planche(chemin: Path) -> dict[str, tuple[int, int, int, int]]:
    lignes = math.ceil(len(ASSETS) / COLONNES)
    image = Image.new("RGBA", (COLONNES * CASE, lignes * CASE), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    rects: dict[str, tuple[int, int, int, int]] = {}
    for i, (nom, categorie, _calque, _taille, couleur, forme) in enumerate(ASSETS):
        x0, y0 = (i % COLONNES) * CASE, (i // COLONNES) * CASE
        # Une dalle de sol remplit sa case : posée bord à bord, elle se raccorde à la suivante (avec une marge, la vue
        # montrait un joint vide entre deux dalles). Les autres assets gardent une marge transparente.
        marge = 0 if categorie == "sol" else 8
        boite = [x0 + marge, y0 + marge, x0 + CASE - marge - 1, y0 + CASE - marge - 1]
        fonce = tuple(max(0, c - 60) for c in couleur) + (255,)
        plein = tuple(couleur) + (255,)
        if forme == "disque":
            d.ellipse(boite, fill=plein, outline=fonce, width=4)
        elif forme == "tache":
            d.ellipse([boite[0], boite[1] + 20, boite[2], boite[3] - 20], fill=plein, outline=fonce, width=3)
        else:
            d.rectangle(boite, fill=plein, outline=fonce, width=4)
        if forme == "grille":
            for k in range(1, 4):
                p = boite[0] + k * (boite[2] - boite[0]) // 4
                q = boite[1] + k * (boite[3] - boite[1]) // 4
                d.line([p, boite[1], p, boite[3]], fill=fonce, width=3)
                d.line([boite[0], q, boite[2], q], fill=fonce, width=3)
        elif forme == "rayures":
            for k in range(boite[0], boite[2], 18):
                d.line([k, boite[1], min(k + 30, boite[2]), boite[3]], fill=fonce, width=5)
        rects[nom] = (x0, y0, CASE, CASE)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image.save(chemin)
    return rects


def catalogue_tres(rects: dict[str, tuple[int, int, int, int]]) -> str:
    lignes = entete("AssetCatalogDef", [("1_catalog", "Script", "res://1_core/data/asset_catalog_def.gd"),
                                        ("2_asset", "Script", "res://1_core/data/asset_def.gd"),
                                        ("3_planche", "Texture2D", f"res://{PLANCHE}")])
    sous = []
    for nom, categorie, calque, (largeur, profondeur), _c, _f in ASSETS:
        ancre = (0.5, 1) if categorie in ("obstacle", "porte") else (0.5, 0.5)
        sous.append(f"Resource_{nom}")
        lignes += [f'[sub_resource type="Resource" id="Resource_{nom}"]', 'script = ExtResource("2_asset")',
                   f'id = &"{nom}"', 'atlas = ExtResource("3_planche")',
                   f"region = Rect2i({nombres(rects[nom])})", f"size_m = Vector2({nombres((largeur, profondeur))})",
                   f"anchor = Vector2({nombres(ancre)})", f'category = &"{categorie}"',
                   f'default_layer = &"{calque}"',
                   "tags = PackedStringArray(" + ", ".join(chaine(t) for t in nom.split("_")) + ")", ""]
    lignes += ["[resource]", 'script = ExtResource("1_catalog")', 'id = &"catalogue"',
               "layers = PackedStringArray(" + ", ".join(chaine(c) for c in CALQUES) + ")",
               'assets = Array[ExtResource("2_asset")]([' + ", ".join(f'SubResource("{s}")' for s in sous) + "])", ""]
    return "\n".join(lignes)


def ennemi_tres(e) -> str:
    ident, nom, role, pv, repere, vitesse, portee, pre, tir, recup, poids, degats, couleur = e
    lignes = entete("EnemyDef", [("1_enemy", "Script", "res://1_core/data/enemy_def.gd")])
    lignes += ["[resource]", 'script = ExtResource("1_enemy")', f'id = &"{ident}"', f"display_name = {chaine(nom)}",
               f'role = &"{role}"', f"max_health = {nombre(pv)}", f"aggro_m = {nombre(repere)}",
               f"speed_mps = {nombre(vitesse)}", f"attack_range_m = {nombre(portee)}",
               f"windup_s = {nombre(pre)}", f"fire_s = {nombre(tir)}", f"recover_s = {nombre(recup)}",
               f"weight = {nombre(poids)}", f"damage = {nombre(degats)}", f"color = Color({nombres(couleur)}, 1)", ""]
    return "\n".join(lignes)


def effet_tres(f) -> str:
    ident, nom, debit, vie, taille, couleur, additif = f
    lignes = entete("FxDef", [("1_fx", "Script", "res://1_core/data/fx_def.gd")])
    lignes += ["[resource]", 'script = ExtResource("1_fx")', f'id = &"{ident}"', f"display_name = {chaine(nom)}",
               f"rate = {nombre(debit)}", f"lifetime_s = {nombre(vie)}", f"size_m = {nombre(taille)}",
               f"color = Color({nombres(couleur)})", f"additive = {'true' if additif else 'false'}", ""]
    return "\n".join(lignes)


# --- salles ---

def salle(ident: str, nom: str, largeur: float, profondeur: float, n_obstacles: int, n_details: int,
          inconnues: bool, pool: list[str], profondeur_jeu: int, alea: random.Random) -> str:
    choses: list[dict] = []

    def ajouter(asset: str, calque: str, x: float, z: float, **extra: object) -> int:
        ident_chose = len(choses) + 1
        chose = {"id": ident_chose, "name": f"{asset}_{ident_chose:03d}", "asset": asset, "layer": calque,
                 "position": (round(x, 2), 0, round(z, 2)), "rotation": 0, "scale": 1, "parallax": 1,
                 "hsv": (0, 0, 0), "color": (1, 1, 1, 1), "active": 1, "height": 0, "parent": 0, "sort": 0}
        chose.update(extra)
        choses.append(chose)
        return ident_chose

    sol = alea.choice([a for a in ASSETS if a[1] == "sol"])[0]
    for i in range(int(largeur // 4)):
        for j in range(int(profondeur // 4)):
            ajouter(sol, "sol", 2 + 4 * i, 2 + 4 * j)
    details = [a[0] for a in ASSETS if a[1] == "detail"]
    for _ in range(n_details):
        ajouter(alea.choice(details), "detail_sol", alea.uniform(1, largeur - 1), alea.uniform(1, profondeur - 1),
                rotation=alea.choice([0, 90, 180, 270]))
    obstacles = [a[0] for a in ASSETS if a[1] == "obstacle"]
    murs = []
    for _ in range(n_obstacles):
        asset = alea.choice(obstacles)
        x, z = alea.uniform(2, largeur - 2), alea.uniform(2, profondeur - 2)
        echelle = alea.choice([1, 1, 0.75, 1.25])
        id_obstacle = ajouter(asset, "obstacles", x, z, rotation=alea.choice([0, 0, 90]), scale=echelle)
        if asset in ("mur_droit", "conteneur", "reacteur"):
            murs.append((x, z, asset, echelle))
        if alea.random() < 0.15:
            ajouter("lampe", "avant_plan", x, z, parent=id_obstacle, parallax=1.2, height=2.5)
    for _ in range(max(2, n_obstacles // 10)):
        ajouter(alea.choice(["tuyaux_plafond", "cables_pendants"]), "avant_plan", alea.uniform(2, largeur - 2),
                alea.uniform(2, profondeur - 2), parallax=1.35, height=3,
                hsv=(0, round(alea.uniform(-0.2, -0.01), 2), round(alea.uniform(-0.4, -0.01), 2)))
    ajouter("porte_sas", "obstacles", largeur / 2, 0.5)
    extras = {}
    if inconnues:
        extras[choses[3]["id"]] = '{"note": "a verifier en jeu"}'
        extras[choses[10]["id"]] = '{"x_lumiere": {"rayon": 3.5}}'

    # Collisions : le contour de la salle, puis un rectangle par grand obstacle (en mètres, x et z).
    tailles = {a[0]: a[3] for a in ASSETS}
    polygones = [(0, 0, largeur, 0, largeur, profondeur, 0, profondeur)]
    for x, z, asset, echelle in murs:
        demi_l, demi_p = tailles[asset][0] * echelle / 2, tailles[asset][1] * echelle / 2
        polygones.append((round(x - demi_l, 2), round(z - demi_p, 2), round(x + demi_l, 2), round(z - demi_p, 2),
                          round(x + demi_l, 2), round(z + demi_p, 2), round(x - demi_l, 2), round(z + demi_p, 2)))
    apparitions = [(round(alea.uniform(3, largeur - 3), 2), 0, round(alea.uniform(6, profondeur - 3), 2))
                   for _ in range(8)]
    roles = [alea.choice(["melee", "distance", "tous"]) for _ in apparitions]
    # Chaque ennemi de la rencontre doit avoir un point de son rôle (EnemyDef.pool_errors refuserait la salle) : on le
    # vérifie à la fabrication plutôt que de compter sur le tirage.
    accueil = {"melee": ("melee", "tous"), "distance": ("distance", "tous")}
    role_de = {e[0]: e[2] for e in ENNEMIS}
    for ennemi in pool:
        assert any(r in accueil[role_de[ennemi]] for r in roles), f"{ident} : aucun point pour {ennemi}"
    effets = [(alea.choice([f[0] for f in EFFETS]), (round(alea.uniform(2, largeur - 2), 2), 0,
                                                       round(alea.uniform(2, profondeur - 2), 2))) for _ in range(3)]

    def colonne(cle: str) -> list:
        return [c[cle] for c in choses]

    lignes = entete("RoomData", [("1_room", "Script", "res://1_core/data/room_data.gd")])
    lignes += [
        "[resource]", 'script = ExtResource("1_room")', f'id = &"{ident}"', f"display_name = {chaine(nom)}",
        f"size_m = Vector2({nombres((largeur, profondeur))})",
        "layers = PackedStringArray(" + ", ".join(chaine(c) for c in CALQUES) + ")",
        f"thing_ids = PackedInt32Array({nombres(colonne('id'))})",
        "thing_names = PackedStringArray(" + ", ".join(chaine(n) for n in colonne("name")) + ")",
        "thing_assets = PackedStringArray(" + ", ".join(chaine(n) for n in colonne("asset")) + ")",
        "thing_layers = PackedStringArray(" + ", ".join(chaine(n) for n in colonne("layer")) + ")",
        f"thing_positions = PackedVector3Array({nombres(v for p in colonne('position') for v in p)})",
        f"thing_rotations = PackedFloat32Array({nombres(colonne('rotation'))})",
        f"thing_scales = PackedFloat32Array({nombres(colonne('scale'))})",
        f"thing_parallax = PackedFloat32Array({nombres(colonne('parallax'))})",
        f"thing_hsv = PackedVector3Array({nombres(v for p in colonne('hsv') for v in p)})",
        f"thing_colors = PackedColorArray({nombres(v for p in colonne('color') for v in p)})",
        f"thing_active = PackedByteArray({nombres(colonne('active'))})",
        f"thing_heights = PackedFloat32Array({nombres(colonne('height'))})",
        f"thing_parents = PackedInt32Array({nombres(colonne('parent'))})",
        f"thing_sort = PackedInt32Array({nombres(colonne('sort'))})",
        "thing_extras = Dictionary[int, String]({" + ", ".join(f"{k}: {chaine(v)}" for k, v in extras.items())
        + "})",
        "collisions = Array[PackedVector2Array]([" + ", ".join(f"PackedVector2Array({nombres(p)})"
                                                            for p in polygones) + "])",
        f"hero_start = Vector3({nombres((largeur / 2, 0, 3))})",
        f"spawn_positions = PackedVector3Array({nombres(v for p in apparitions for v in p)})",
        "spawn_roles = PackedStringArray(" + ", ".join(chaine(r) for r in roles) + ")",
        "encounter_pool = PackedStringArray(" + ", ".join(chaine(p) for p in pool) + ")",
        f"encounter_depth = {profondeur_jeu}",
        "effect_ids = PackedStringArray(" + ", ".join(chaine(e[0]) for e in effets) + ")",
        f"effect_positions = PackedVector3Array({nombres(v for e in effets for v in e[1])})",
        "",
    ]
    print(ident, len(choses), "choses,", len(polygones), "collisions,", len(apparitions), "apparitions")
    return "\n".join(lignes)


def ecrire(rel: str, texte: str) -> None:
    chemin = MAITRES / rel
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8", newline="\n")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--source", type=Path, default=SOURCE_DEFAUT)
    p.add_argument("--graine", type=int, default=7)
    a = p.parse_args()
    alea = random.Random(a.graine)
    rects = dessiner_planche(a.source / PLANCHE)
    ecrire("5_data/catalogue/catalogue.tres", catalogue_tres(rects))
    tous = [e[0] for e in ENNEMIS]
    ecrire("5_data/salles/hangar.tres", salle("hangar", "Le hangar", 48, 32, 60, 30, True, tous, 3, alea))
    ecrire("5_data/salles/soute.tres", salle("soute", "La soute", 36, 28, 40, 24, False,
                                             ["melee", "brute", "tireur", "bombe"], 4, alea))
    ecrire("5_data/salles/pont.tres", salle("pont", "Le pont", 24, 20, 18, 10, True, ["melee", "toupie", "cone"], 5,
                                            alea))
    for e in ENNEMIS:
        ecrire(f"5_data/ennemis/{e[0]}.tres", ennemi_tres(e))
    for f in EFFETS:
        ecrire(f"5_data/effets/{f[0]}.tres", effet_tres(f))
    print("planche :", a.source / PLANCHE)


if __name__ == "__main__":
    main()
