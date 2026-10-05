"""Compétence E, « optimisation stricte » : paires départ naïf / référence optimisée.

Chaque tâche est un petit jeu 2D écrit par ce générateur (pas un jeu source) en deux versions
qui ne diffèrent que par l'efficience :

  famille     anti-pattern du départ                              référence
  allocations création et libération d'objets dans la boucle      réserve créée à l'échauffement
              (Sprite2D.new, instantiate/queue_free, RefCounted)  (pile de libres ou drapeaux)
  lots        une texture ou un matériau par entité, ou une       texture et matériau partagés,
              texture par type d'entité alternée dans l'arbre     ou atlas avec régions
  temps       voisinage en O(N²), carte de distances recalculée   grille de voisinage, carte
              à chaque image, get_node à chaque image             calculée une fois, nœuds en cache

Vérification à la génération (une paire qui échoue est écartée, avec sa raison) :
  1. comportement : l'état du jeu (`etat()`) est identique, octet pour octet, aux images de
     contrôle, en appelant `simuler(1/60)` comme le fait le test caché ;
  2. rendu : la signature de ce qui serait affiché est identique aux images 180, 240 et 300
     (gd/mesurer_efficience.gd), et les réglages de rendu sont les mêmes (fichiers communs) ;
  3. efficience : la référence n'alloue rien après l'échauffement et le départ est mesurablement
     pire sur le critère de sa famille (allocations > 0 ; lots > référence × 1,05 ; temps ≥ 3 ×
     référence, médiane de 3 exécutions).

La tâche porte `mesure_efficience` dans tache.json : réglages de la mesure et vérité terrain
déterministe de la référence et du départ (lots, allocations). Le temps n'y est jamais écrit : il
dépend de la machine et changerait l'empreinte ; le juge le mesure au moment de juger.
Le test caché (`tests_caches/test_comportement.gd`) compare `etat()` aux images de contrôle.

MultiMesh : ses données d'instances ne sont pas lisibles en headless, donc aucune référence n'en
utilise (le rendu ne serait pas vérifiable). Voir usine/efficience/gd/mesurer_efficience.gd.
"""

from __future__ import annotations

import json
import math
import random
import re
import textwrap
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from usine.efficience import mesure as mes
from usine.generateurs.commun import MARQUEUR, Production, ecrire_projet, ecrire_tache, executer_gd

ORIGINE = "generateur:efficience"
COMPETENCE = "E"
LARGEUR, HAUTEUR = 640, 360
POINTS_CONTROLE = (30, 90, 150, 240)
REGLAGES = mes.Reglages()
NOMBRE_DEFAUT = 120
RAPPORT_TEMPS_MIN = 3.0          # départ au moins 3 × plus lent que la référence (familles « temps »)


_BLOC = "\x00"
_LIGNE = "\x01"
_MARQUE = re.compile(r"^(\t*)\x00(\d+)\x00(.*?)\x00(.*)$")


def _tabs(texte: str) -> str:
    """Indentation par groupes de 4 espaces → tabulations (style Godot) ; le reste est gardé."""
    lignes = []
    for ligne in texte.split("\n"):
        n = len(ligne) - len(ligne.lstrip(" "))
        lignes.append("\t" * (n // 4) + " " * (n % 4) + ligne.lstrip(" "))
    return "\n".join(lignes)


def bloc(texte: str, n: int = 0) -> str:
    """Bloc de plusieurs lignes à insérer dans un gabarit : codé sur une ligne, il est déplié par
    `gd` (ou `deplier`) à l'indentation de la ligne où il est inséré, plus `n` niveaux."""
    t = _tabs(textwrap.dedent(texte).strip("\n"))
    return f"{_BLOC}{n}{_BLOC}" + t.replace("\n", _LIGNE) + _BLOC


indenter = bloc


def deplier(texte: str) -> str:
    sortie = []
    for ligne in texte.split("\n"):
        m = _MARQUE.match(ligne)
        if not m:
            sortie.append(ligne)
            continue
        prefixe = m.group(1) + "\t" * int(m.group(2))
        for morceau in m.group(3).split(_LIGNE):
            sortie.append(prefixe + morceau if morceau else "")
        if m.group(4):
            sortie.append(m.group(4))
    resultat = "\n".join(sortie)
    return deplier(resultat) if _BLOC in resultat else resultat


def gd(texte: str) -> str:
    """GDScript écrit avec 4 espaces dans ce fichier → tabulations ; blocs insérés dépliés."""
    return deplier(_tabs(textwrap.dedent(texte).strip("\n"))) + "\n"


def f(x: float) -> str:
    """Flottant GDScript lisible et reproductible."""
    t = f"{x:.4f}".rstrip("0")
    return t + "0" if t.endswith(".") else t


def v2(p: tuple[float, float]) -> str:
    return f"Vector2({f(p[0])}, {f(p[1])})"


def coul(c: tuple[float, float, float, float]) -> str:
    return f"Color({f(c[0])}, {f(c[1])}, {f(c[2])}, {f(c[3])})"


# ------------------------------------------------------------------ vocabulaire et décor

THEMES = {
    "tir": [("balle", "balles"), ("fleche", "fleches"), ("plasma", "plasmas"), ("dard", "dards"),
            ("eclair", "eclairs"), ("graine", "graines"), ("pique", "piques"), ("onde", "ondes")],
    "eclats": [("etincelle", "etincelles"), ("braise", "braises"), ("goutte", "gouttes"), ("flocon", "flocons"),
               ("plume", "plumes"), ("bulle", "bulles"), ("poussiere", "poussieres"), ("eclat", "eclats")],
    "vagues": [("ennemi", "ennemis"), ("slime", "slimes"), ("drone", "drones"), ("fantome", "fantomes"),
               ("araignee", "araignees"), ("meteore", "meteores"), ("rodeur", "rodeurs"), ("zombie", "zombies")],
    "mobiles": [("bille", "billes"), ("palet", "palets"), ("rocher", "rochers"), ("caisse", "caisses"),
                ("toupie", "toupies"), ("boule", "boules"), ("pion", "pions"), ("jeton", "jetons")],
    "decor": [("luciole", "lucioles"), ("etoile", "etoiles"), ("poisson", "poissons"), ("feuille", "feuilles"),
              ("nuage", "nuages"), ("lanterne", "lanternes"), ("cristal", "cristaux"), ("spore", "spores")],
    "agents": [("fourmi", "fourmis"), ("abeille", "abeilles"), ("mouton", "moutons"), ("robot", "robots"),
               ("oiseau", "oiseaux"), ("passant", "passants"), ("soldat", "soldats"), ("crabe", "crabes")],
}
FORMES = ("disque", "carre", "losange", "croix", "anneau")
NOMS = {
    "reserve": ("reserve", "vivier", "stock", "parc", "inventaire", "file_prete"),
    "actifs": ("actifs", "en_service", "occupes", "vivants", "utilises"),
    "libres": ("libres", "disponibles", "inactifs", "au_repos"),
    "prendre": ("prendre", "obtenir", "sortir", "activer", "emprunter"),
    "rendre": ("rendre", "liberer", "ranger", "desactiver", "restituer"),
    "image": ("image", "tick", "pas", "instant", "frame"),
    "compte": ("sorties", "retraits", "disparus", "fins", "termines"),
    "cadence": ("CADENCE", "PERIODE", "INTERVALLE", "RYTHME"),
    "vitesse": ("VITESSE", "ALLURE", "ELAN", "CELERITE"),
    "duree": ("DUREE_MAX", "VIE_MAX", "AGE_LIMITE", "TTL"),
    "motifs": ("motifs", "atelier", "pinceau", "dessins"),
}


def nom(rng: random.Random, cle: str) -> str:
    return rng.choice(NOMS[cle])


def couleur(rng: random.Random, alpha: float = 1.0) -> tuple[float, float, float, float]:
    return (round(rng.uniform(0.3, 1.0), 2), round(rng.uniform(0.3, 1.0), 2), round(rng.uniform(0.3, 1.0), 2), alpha)


def script_motifs() -> str:
    return gd('''
        extends RefCounted
        ## Motifs dessinés pixel par pixel : le projet ne contient aucun fichier image.

        static func motif(forme: String, taille: int, couleur: Color) -> Image:
            var img := Image.create(taille, taille, false, Image.FORMAT_RGBA8)
            var c := (taille - 1) / 2.0
            for y in taille:
                for x in taille:
                    var dx := x - c
                    var dy := y - c
                    var dedans := false
                    match forme:
                        "disque":
                            dedans = dx * dx + dy * dy <= c * c
                        "carre":
                            dedans = true
                        "losange":
                            dedans = absf(dx) + absf(dy) <= c
                        "croix":
                            dedans = absf(dx) <= c / 3.0 or absf(dy) <= c / 3.0
                        "anneau":
                            var r := dx * dx + dy * dy
                            dedans = r <= c * c and r >= c * c * 0.25
                    if dedans:
                        img.set_pixel(x, y, couleur)
            return img
        ''')


@dataclass
class Decor:
    """Éléments de rendu verrouillés de la scène (identiques dans le départ et la référence)."""
    titre: str
    fond: tuple
    clair: tuple
    teinte: tuple | None
    lumiere: tuple | None          # (position, couleur, énergie, échelle)
    hud: bool
    conteneur: str | None          # nœud qui reçoit les entités (None : la racine)
    motifs: str

    @classmethod
    def tirer(cls, rng: random.Random, titre: str) -> "Decor":
        lumiere = None
        if rng.random() < 0.6:
            lumiere = ((rng.randint(80, 560), rng.randint(60, 300)), couleur(rng), round(rng.uniform(0.6, 1.6), 2),
                       round(rng.uniform(2.0, 6.0), 1))
        return cls(titre=titre, fond=couleur(rng), clair=couleur(rng),
                   teinte=couleur(rng) if rng.random() < 0.5 else None, lumiere=lumiere, hud=rng.random() < 0.7,
                   conteneur=rng.choice((None, "Entites", "Monde", "Calque")), motifs=nom(rng, "motifs"))

    def project_godot(self) -> str:
        return (
            "; Engine configuration file.\n"
            "config_version=5\n\n"
            "[application]\n\n"
            f'config/name="{self.titre}"\n'
            'run/main_scene="res://scenes/jeu.tscn"\n\n'
            "[display]\n\n"
            f"window/size/viewport_width={LARGEUR}\n"
            f"window/size/viewport_height={HAUTEUR}\n"
            'window/stretch/mode="canvas_items"\n\n'
            "[rendering]\n\n"
            "textures/canvas_textures/default_texture_filter=0\n"
            f"environment/defaults/default_clear_color={coul(self.clair)}\n"
        )

    def scene(self) -> str:
        res = ['[ext_resource type="Script" path="res://scripts/jeu.gd" id="1_jeu"]\n']
        if self.lumiere:
            res.append('[sub_resource type="Gradient" id="Gradient_lum"]\n'
                       "colors = PackedColorArray(1, 1, 1, 1, 1, 1, 1, 0)\n")
            res.append('[sub_resource type="GradientTexture2D" id="GradientTexture2D_lum"]\n'
                       'gradient = SubResource("Gradient_lum")\n'
                       "fill = 1\nfill_from = Vector2(0.5, 0.5)\nfill_to = Vector2(1, 0.5)\n")
        noeuds = ['[node name="Jeu" type="Node2D"]\nscript = ExtResource("1_jeu")\n',
                  '[node name="Fond" type="ColorRect" parent="."]\n'
                  f"offset_right = {LARGEUR}.0\noffset_bottom = {HAUTEUR}.0\ncolor = {coul(self.fond)}\n"]
        if self.teinte:
            noeuds.append(f'[node name="Teinte" type="CanvasModulate" parent="."]\ncolor = {coul(self.teinte)}\n')
        if self.lumiere:
            (x, y), c, e, s = self.lumiere
            noeuds.append('[node name="Lumiere" type="PointLight2D" parent="."]\n'
                          f"position = Vector2({x}, {y})\ncolor = {coul(c)}\nenergy = {f(e)}\n"
                          f'texture = SubResource("GradientTexture2D_lum")\ntexture_scale = {f(s)}\n')
        if self.conteneur:
            noeuds.append(f'[node name="{self.conteneur}" type="Node2D" parent="."]\n')
        if self.hud:
            noeuds.append('[node name="Hud" type="CanvasLayer" parent="."]\n')
            noeuds.append('[node name="Score" type="Label" parent="Hud"]\n'
                          'offset_left = 8.0\noffset_top = 6.0\noffset_right = 240.0\noffset_bottom = 30.0\n'
                          'text = "0"\n')
        return f"[gd_scene load_steps={len(res) + 1} format=3]\n\n" + "\n".join(res + noeuds)

    def parent(self) -> str:
        """Expression GDScript du nœud qui reçoit les entités."""
        return f"${self.conteneur}" if self.conteneur else "self"

    def entete(self) -> str:
        lignes = [f'const Motifs := preload("res://scripts/{self.motifs}.gd")']
        if self.hud:
            lignes.append("@onready var _score: Label = $Hud/Score")
        return bloc("\n".join(lignes))

    def maj_hud(self, expr: str) -> str:
        return f"if _score:\n    _score.text = str({expr})" if self.hud else "pass"


ETAT_POINTS = '''
func _points(liste: Array[Vector2]) -> Array:
    liste.sort()
    var sortie: Array = []
    for p in liste:
        sortie.append([snappedf(p.x, 0.01), snappedf(p.y, 0.01)])
    return sortie
'''


# ------------------------------------------------------------------ familles « allocations »

@dataclass
class Paire:
    famille: str
    variante: str
    titre: str
    decor: Decor
    depart: dict[str, str]
    reference: dict[str, str]      # fichiers remplacés ou ajoutés par la référence
    symptome: str                  # ce que l'agent observe (consigne)
    entites: str                   # nom pluriel pour la consigne
    temps: bool = False

    def __post_init__(self) -> None:
        self.depart = {k: deplier(_tabs(v)) for k, v in self.depart.items()}
        self.reference = {k: deplier(_tabs(v)) for k, v in self.reference.items()}


def _source_points(rng: random.Random, n: int) -> list[tuple[int, int]]:
    return [(rng.randint(60, 580), rng.randint(40, 320)) for _ in range(n)]


def _direction_tir(rng: random.Random, image: str, idx: str) -> tuple[str, dict]:
    """Code GDScript qui calcule `direction` (Vector2 unitaire) pour une source d'indice idx."""
    motif = rng.choice(("spirale", "visee", "eventail"))
    if motif == "spirale":
        pas, dec = round(rng.uniform(0.11, 0.53), 3), round(rng.uniform(0.5, 2.5), 2)
        return f"var direction := Vector2.from_angle(float({image}) * {f(pas)} + {idx} * {f(dec)})", {}
    if motif == "visee":
        cible = (rng.randint(200, 440), rng.randint(120, 240))
        ecart = round(rng.uniform(0.05, 0.3), 3)
        return (f"var direction := SOURCES[{idx}].direction_to({v2(cible)}).rotated(float({image} % 5 - 2) * "
                f"{f(ecart)})"), {}
    largeur = round(rng.uniform(0.4, 1.4), 2)
    return (f"var direction := Vector2.from_angle(float({idx}) * 1.7 + sin(float({image}) * 0.05) * {f(largeur)})"), {}


def paire_tir(rng: random.Random, titre: str) -> Paire:
    """Sources qui tirent : un Sprite2D (ou une scène) créé à chaque tir, libéré à la sortie."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["tir"])
    n_src = rng.randint(1, 4)
    sources = _source_points(rng, n_src)
    cad, vit, duree = rng.randint(2, 7), rng.randint(140, 320), rng.randint(40, 140)
    taille, forme, c = rng.choice((4, 6, 8, 10)), rng.choice(FORMES), couleur(rng)
    IM, CO, CAD, VIT, DUR = nom(rng, "image"), nom(rng, "compte"), nom(rng, "cadence"), nom(rng, "vitesse"), nom(rng, "duree")
    direction, _ = _direction_tir(rng, IM, "s")
    avec_scene = rng.random() < 0.5
    classe = sing.capitalize() + "Tir"
    capacite = n_src * (duree // cad + 2)
    marge = 12
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n_src} source(s) tirent des {plur}.

        {d.entete()}
        const {CAD} := {cad}
        const {VIT} := {f(vit)}
        const {DUR} := {duree}
        const ZONE := Rect2({-marge}, {-marge}, {LARGEUR + 2 * marge}, {HAUTEUR + 2 * marge})
        const SOURCES: Array[Vector2] = [{", ".join(v2(p) for p in sources)}]
        ''')
    if avec_scene:
        scene_ent = (f"[gd_scene load_steps=2 format=3]\n\n"
                     f'[ext_resource type="Script" path="res://scripts/{sing}.gd" id="1_{sing}"]\n\n'
                     f'[node name="{sing.capitalize()}" type="Sprite2D"]\nscript = ExtResource("1_{sing}")\n')
        script_ent = gd(f'''
            class_name {classe}
            extends Sprite2D
            ## Un(e) {sing} : sa vitesse et son âge en images.

            var vitesse := Vector2.ZERO
            var age := 0
            ''')
        extra = {f"scenes/{sing}.tscn": scene_ent, f"scripts/{sing}.gd": script_ent}
        T = classe
        creer = f"var e: {classe} = MODELE.instantiate()"
        entete += f'const MODELE := preload("res://scenes/{sing}.tscn")\n'
    else:
        extra = {}
        T = "Sprite2D"
        creer = "var e := Sprite2D.new()"
    vars_communes = gd(f'''
        var {IM}: int = 0
        var {CO}: int = 0
        var _texture: Texture2D
        ''')
    ready_tex = f'_texture = ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))'
    parent = d.parent()
    # --- départ
    if avec_scene:
        dep_vars = f"var {plur}: Array[{T}] = []\n"
        dep_maj = gd(f'''
            var i := 0
            while i < {plur}.size():
                var e := {plur}[i]
                e.position += e.vitesse * delta
                e.age += 1
                if e.age >= {DUR} or not ZONE.has_point(e.position):
                    e.queue_free()
                    {plur}.remove_at(i)
                    {CO} += 1
                else:
                    i += 1
            ''')
        dep_tir = gd(f'''
            func _tirer(origine: Vector2, vitesse: Vector2) -> void:
                {creer}
                e.texture = _texture
                e.position = origine
                e.vitesse = vitesse
                {parent}.add_child(e)
                {plur}.append(e)
            ''')
        dep_etat = f"for e in {plur}:\n    points.append(e.position)"
    else:
        dep_vars = f"var {plur}: Array[Sprite2D] = []\nvar _vitesses: Array[Vector2] = []\nvar _ages: Array[int] = []\n"
        dep_maj = gd(f'''
            var i := 0
            while i < {plur}.size():
                {plur}[i].position += _vitesses[i] * delta
                _ages[i] += 1
                if _ages[i] >= {DUR} or not ZONE.has_point({plur}[i].position):
                    {plur}[i].queue_free()
                    {plur}.remove_at(i)
                    _vitesses.remove_at(i)
                    _ages.remove_at(i)
                    {CO} += 1
                else:
                    i += 1
            ''')
        dep_tir = gd(f'''
            func _tirer(origine: Vector2, vitesse: Vector2) -> void:
                {creer}
                e.texture = _texture
                e.position = origine
                {parent}.add_child(e)
                {plur}.append(e)
                _vitesses.append(vitesse)
                _ages.append(0)
            ''')
        dep_etat = f"for e in {plur}:\n    points.append(e.position)"
    simuler_tete = gd(f'''
        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(delta: float) -> void:
            {IM} += 1
            if {IM} % {CAD} == 0:
                for s in SOURCES.size():
                    {direction}
                    _tirer(SOURCES[s], direction * {VIT})
        ''')
    hud = indenter(d.maj_hud(CO), 1)
    etat = lambda boucle: gd(f'''
        func etat() -> Dictionary:
            var points: Array[Vector2] = []
        {indenter(boucle, 1)}
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''')
    depart = (entete + "\n" + vars_communes + dep_vars + "\n\nfunc _ready() -> void:\n    " + ready_tex + "\n\n\n"
              + simuler_tete + indenter(dep_maj, 1) + "\n" + hud + "\n\n\n" + dep_tir + "\n\n" + etat(dep_etat)
              + "\n" + gd(ETAT_POINTS))
    # --- référence : réserve créée pendant l'échauffement
    RES, ACT, LIB, PR, RE = nom(rng, "reserve"), nom(rng, "actifs"), nom(rng, "libres"), nom(rng, "prendre"), nom(rng, "rendre")
    pile = rng.random() < 0.5
    TAILLE = "TAILLE_" + RES.upper()
    ref_vars = f"const {TAILLE} := {capacite}\n" + f"var {RES}: Array[{T}] = []\nvar {ACT}: Array[bool] = []\n"
    if not avec_scene:
        ref_vars += "var _vitesses: Array[Vector2] = []\nvar _ages: Array[int] = []\n"
    if pile:
        ref_vars += f"var {LIB}: Array[int] = []\n"
    init = [creer, "e.texture = _texture", "e.visible = false", f"{parent}.add_child(e)", f"{RES}.append(e)",
            f"{ACT}.append(false)"]
    if not avec_scene:
        init += ["_vitesses.append(Vector2.ZERO)", "_ages.append(0)"]
    if pile:
        init.append(f"{LIB}.append({TAILLE} - 1 - k)")
    ref_ready = ("func _ready() -> void:\n    " + ready_tex + f"\n    for k in {TAILLE}:\n"
                 + "\n".join("        " + l for l in init) + "\n")
    vit_k = f"{RES}[k].vitesse" if avec_scene else "_vitesses[k]"
    age_k = f"{RES}[k].age" if avec_scene else "_ages[k]"
    ref_maj = gd(f'''
        for k in {TAILLE}:
            if not {ACT}[k]:
                continue
            {RES}[k].position += {vit_k} * delta
            {age_k} += 1
            if {age_k} >= {DUR} or not ZONE.has_point({RES}[k].position):
                _{RE}(k)
                {CO} += 1
        ''')
    if pile:
        trouver = f"var k: int = {LIB}.pop_back()"
        rendre_corps = f"{LIB}.push_back(k)"
    else:
        trouver = f"var k := {ACT}.find(false)"
        rendre_corps = "pass"
    ref_tir = gd(f'''
        func _tirer(origine: Vector2, vitesse: Vector2) -> void:
            _{PR}(origine, vitesse)


        func _{PR}(origine: Vector2, vitesse: Vector2) -> void:
            {trouver}
            {RES}[k].position = origine
            {vit_k} = vitesse
            {age_k} = 0
            {RES}[k].visible = true
            {ACT}[k] = true


        func _{RE}(k: int) -> void:
            {RES}[k].visible = false
            {ACT}[k] = false
            {rendre_corps}
        ''')
    ref_etat = f"for k in {TAILLE}:\n    if {ACT}[k]:\n        points.append({RES}[k].position)"
    reference = (entete + "\n" + vars_communes + ref_vars + "\n\n" + ref_ready + "\n\n" + simuler_tete
                 + indenter(ref_maj, 1) + "\n" + hud + "\n\n\n" + ref_tir + "\n\n" + etat(ref_etat) + "\n"
                 + gd(ETAT_POINTS))
    commun = {"scripts/" + d.motifs + ".gd": script_motifs(), **extra}
    return Paire("allocations", "tir", titre, d, {**commun, "scripts/jeu.gd": depart}, {"scripts/jeu.gd": reference},
                 f"des {plur} sont créé(e)s et libéré(e)s pendant la partie", plur)


def paire_eclats(rng: random.Random, titre: str) -> Paire:
    """Gerbes de particules (gravité, fondu) : une particule créée puis libérée à chaque fois."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["eclats"])
    cad, nb, duree = rng.randint(6, 20), rng.randint(4, 12), rng.randint(30, 80)
    grav = rng.randint(0, 400)
    vmin, vmax = rng.randint(40, 100), rng.randint(120, 260)
    impacts = _source_points(rng, rng.randint(2, 5))
    taille, forme, c = rng.choice((3, 4, 6, 8)), rng.choice(FORMES), couleur(rng)
    IM, CO, CAD, DUR = nom(rng, "image"), nom(rng, "compte"), nom(rng, "cadence"), nom(rng, "duree")
    G = rng.choice(("GRAVITE", "PESANTEUR", "CHUTE"))
    capacite = nb * (duree // cad + 2)
    parent = d.parent()
    entete = gd(f'''
        extends Node2D
        ## {titre} : des gerbes de {plur} qui retombent et s'effacent.

        {d.entete()}
        const {CAD} := {cad}
        const PAR_GERBE := {nb}
        const {DUR} := {duree}
        const {G} := {f(grav)}
        const IMPACTS: Array[Vector2] = [{", ".join(v2(p) for p in impacts)}]

        var {IM}: int = 0
        var {CO}: int = 0
        var _texture: Texture2D
        ''')
    gerbe = gd(f'''
        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(delta: float) -> void:
            {IM} += 1
            if {IM} % {CAD} == 0:
                var centre := IMPACTS[({IM} / {CAD}) % IMPACTS.size()]
                for j in PAR_GERBE:
                    var angle := TAU * float(j) / PAR_GERBE + float({IM}) * 0.13
                    var force := {f(vmin)} + float((j * 7 + {IM}) % 11) / 10.0 * {f(vmax - vmin)}
                    _emettre(centre, Vector2.from_angle(angle) * force)
        ''')
    ready_tex = f'_texture = ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))'
    maj_une = lambda e, v, a: gd(f'''
        {v}.y += {G} * delta
        {e}.position += {v} * delta
        {a} += 1
        {e}.modulate.a = 1.0 - float({a}) / {DUR}
        ''')
    depart = entete + gd(f'''
        var {plur}: Array[Sprite2D] = []
        var _vitesses: Array[Vector2] = []
        var _ages: Array[int] = []


        func _ready() -> void:
            {ready_tex}


        ''') + "\n\n" + gerbe + gd(f'''
            var i := 0
            while i < {plur}.size():
        {indenter(maj_une(f"{plur}[i]", "_vitesses[i]", "_ages[i]"), 2)}
                if _ages[i] >= {DUR}:
                    {plur}[i].queue_free()
                    {plur}.remove_at(i)
                    _vitesses.remove_at(i)
                    _ages.remove_at(i)
                    {CO} += 1
                else:
                    i += 1
        {indenter(d.maj_hud(CO), 1)}


        func _emettre(origine: Vector2, vitesse: Vector2) -> void:
            var e := Sprite2D.new()
            e.texture = _texture
            e.position = origine
            {parent}.add_child(e)
            {plur}.append(e)
            _vitesses.append(vitesse)
            _ages.append(0)


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    RES, ACT, LIB = nom(rng, "reserve"), nom(rng, "actifs"), nom(rng, "libres")
    TAILLE = "TAILLE_" + RES.upper()
    reference = entete + gd(f'''
        const {TAILLE} := {capacite}
        var {RES}: Array[Sprite2D] = []
        var {ACT}: Array[bool] = []
        var {LIB}: Array[int] = []
        var _vitesses: Array[Vector2] = []
        var _ages: Array[int] = []


        func _ready() -> void:
            {ready_tex}
            for k in {TAILLE}:
                var e := Sprite2D.new()
                e.texture = _texture
                e.visible = false
                {parent}.add_child(e)
                {RES}.append(e)
                {ACT}.append(false)
                _vitesses.append(Vector2.ZERO)
                _ages.append(0)
                {LIB}.append({TAILLE} - 1 - k)


        ''') + "\n\n" + gerbe + gd(f'''
            for k in {TAILLE}:
                if not {ACT}[k]:
                    continue
        {indenter(maj_une(f"{RES}[k]", "_vitesses[k]", "_ages[k]"), 2)}
                if _ages[k] >= {DUR}:
                    {RES}[k].visible = false
                    {ACT}[k] = false
                    {LIB}.push_back(k)
                    {CO} += 1
        {indenter(d.maj_hud(CO), 1)}


        func _emettre(origine: Vector2, vitesse: Vector2) -> void:
            var k: int = {LIB}.pop_back()
            {RES}[k].position = origine
            {RES}[k].modulate.a = 1.0
            _vitesses[k] = vitesse
            _ages[k] = 0
            {RES}[k].visible = true
            {ACT}[k] = true


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for k in {TAILLE}:
                if {ACT}[k]:
                    points.append({RES}[k].position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    return Paire("allocations", "eclats", titre, d,
                 {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference}, f"chaque gerbe crée de nouvelles {plur} puis les libère", plur)


def paire_vagues(rng: random.Random, titre: str) -> Paire:
    """Ennemis qui apparaissent sur les bords et marchent vers le centre ; retirés en l'atteignant."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["vagues"])
    cad, vit, rayon = rng.randint(3, 12), rng.randint(40, 160), rng.randint(10, 40)
    centre = (rng.randint(260, 380), rng.randint(140, 220))
    apparitions = [(0, rng.randint(20, 340)), (LARGEUR, rng.randint(20, 340)), (rng.randint(20, 620), 0),
                   (rng.randint(20, 620), HAUTEUR)]
    rng.shuffle(apparitions)
    apparitions = apparitions[:rng.randint(2, 4)]
    taille, forme, c = rng.choice((8, 10, 12, 16)), rng.choice(FORMES), couleur(rng)
    IM, CO, CAD, VIT = nom(rng, "image"), rng.choice(("atteints", "arrives", "percees", "intrus")), \
        nom(rng, "cadence"), nom(rng, "vitesse")
    distance_max = max(math.dist(p, centre) for p in apparitions)
    capacite = int(distance_max / vit * 60 / cad) + 3
    parent = d.parent()
    avec_classe = rng.random() < 0.5
    classe = sing.capitalize() + "Ennemi"
    entete = gd(f'''
        extends Node2D
        ## {titre} : des {plur} surgissent des bords et marchent vers le centre.

        {d.entete()}
        const {CAD} := {cad}
        const {VIT} := {f(vit)}
        const CENTRE := {v2(centre)}
        const RAYON := {f(rayon)}
        const APPARITIONS: Array[Vector2] = [{", ".join(v2(p) for p in apparitions)}]

        var {IM}: int = 0
        var {CO}: int = 0
        var _texture: Texture2D
        ''')
    tete = gd(f'''
        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(delta: float) -> void:
            {IM} += 1
            if {IM} % {CAD} == 0:
                _faire_apparaitre(APPARITIONS[({IM} / {CAD}) % APPARITIONS.size()])
        ''')
    ready_tex = f'_texture = ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))'
    extra: dict[str, str] = {}
    if avec_classe:
        extra[f"scripts/{sing}.gd"] = gd(f'''
            class_name {classe}
            extends Sprite2D
            ## Un(e) {sing} qui marche vers le centre.

            var actif := false


            func avancer(delta: float, cible: Vector2, vitesse: float) -> void:
                position = position.move_toward(cible, vitesse * delta)
            ''')
        T, creer = classe, f"var e := {classe}.new()"
        avancer = lambda e: f"{e}.avancer(delta, CENTRE, {VIT})"
    else:
        T, creer = "Sprite2D", "var e := Sprite2D.new()"
        avancer = lambda e: f"{e}.position = {e}.position.move_toward(CENTRE, {VIT} * delta)"
    depart = entete + gd(f'''
        var {plur}: Array[{T}] = []


        func _ready() -> void:
            {ready_tex}


        ''') + "\n\n" + tete + gd(f'''
            for e in {plur}.duplicate():
                {avancer("e")}
                if e.position.distance_to(CENTRE) <= RAYON:
                    {plur}.erase(e)
                    e.queue_free()
                    {CO} += 1
        {indenter(d.maj_hud(CO), 1)}


        func _faire_apparaitre(origine: Vector2) -> void:
            {creer}
            e.texture = _texture
            e.position = origine
            {parent}.add_child(e)
            {plur}.append(e)


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    RES, ACT, PR, RE = nom(rng, "reserve"), nom(rng, "actifs"), nom(rng, "prendre"), nom(rng, "rendre")
    TAILLE = "TAILLE_" + RES.upper()
    reference = entete + gd(f'''
        const {TAILLE} := {capacite}
        var {RES}: Array[{T}] = []
        var {ACT}: Array[bool] = []


        func _ready() -> void:
            {ready_tex}
            for k in {TAILLE}:
                {creer}
                e.texture = _texture
                e.visible = false
                {parent}.add_child(e)
                {RES}.append(e)
                {ACT}.append(false)


        ''') + "\n\n" + tete + gd(f'''
            for k in {TAILLE}:
                if not {ACT}[k]:
                    continue
                var e := {RES}[k]
                {avancer("e")}
                if e.position.distance_to(CENTRE) <= RAYON:
                    _{RE}(k)
                    {CO} += 1
        {indenter(d.maj_hud(CO), 1)}


        func _faire_apparaitre(origine: Vector2) -> void:
            var k := {ACT}.find(false)
            {RES}[k].position = origine
            {RES}[k].visible = true
            {ACT}[k] = true


        func _{RE}(k: int) -> void:
            {RES}[k].visible = false
            {ACT}[k] = false


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for k in {TAILLE}:
                if {ACT}[k]:
                    points.append({RES}[k].position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    return Paire("allocations", "vagues", titre, d,
                 {"scripts/" + d.motifs + ".gd": script_motifs(), **extra, "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference}, f"des {plur} sont créé(e)s à chaque apparition et libéré(e)s à "
                                                f"l'arrivée", plur)


def paire_objets(rng: random.Random, titre: str) -> Paire:
    """Mobiles qui rebondissent : un objet RefCounted « choc » créé par mobile et par image."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["mobiles"])
    n = rng.randint(6, 30)
    taille, forme, c = rng.choice((6, 8, 10, 12)), rng.choice(FORMES), couleur(rng)
    amorti = round(rng.uniform(0.7, 1.0), 2)
    IM, CO = nom(rng, "image"), rng.choice(("rebonds", "chocs", "contacts", "impacts"))
    classe = rng.choice(("Choc", "Contact", "Collision", "Rebond", "Impact"))
    parent = d.parent()
    graine_pos = rng.randint(1, 10_000)
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n} {plur} rebondissent sur les bords de l'écran.

        {d.entete()}
        const NOMBRE := {n}
        const AMORTI := {f(amorti)}
        const BORDS := Rect2({taille}, {taille}, {LARGEUR - 2 * taille}, {HAUTEUR - 2 * taille})


        class {classe}:
            extends RefCounted
            var touche := false
            var normale := Vector2.ZERO


        var {IM}: int = 0
        var {CO}: int = 0
        var {plur}: Array[Sprite2D] = []
        var _vitesses: Array[Vector2] = []


        func _ready() -> void:
            var texture := ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))
            for k in NOMBRE:
                var e := Sprite2D.new()
                e.texture = texture
                var h := (k * 7919 + {graine_pos}) % 10007
                e.position = Vector2(BORDS.position.x + float(h % 97) / 97.0 * BORDS.size.x,
                    BORDS.position.y + float(h % 89) / 89.0 * BORDS.size.y)
                _vitesses.append(Vector2.from_angle(float(h) * 0.01) * (60.0 + float(h % 150)))
                {parent}.add_child(e)
                {plur}.append(e)


        func _physics_process(delta: float) -> void:
            simuler(delta)
        ''')
    depart = entete + "\n\n" + gd(f'''
        func simuler(delta: float) -> void:
            {IM} += 1
            for k in NOMBRE:
                {plur}[k].position += _vitesses[k] * delta
                var choc := _tester({plur}[k].position)
                if choc.touche:
                    _vitesses[k] = _vitesses[k].bounce(choc.normale) * AMORTI
                    {plur}[k].position = {plur}[k].position.clamp(BORDS.position, BORDS.end)
                    {CO} += 1
        {indenter(d.maj_hud(CO), 1)}


        func _tester(p: Vector2) -> {classe}:
            var choc := {classe}.new()
            if p.x < BORDS.position.x or p.x > BORDS.end.x:
                choc.touche = true
                choc.normale = Vector2(1, 0)
            elif p.y < BORDS.position.y or p.y > BORDS.end.y:
                choc.touche = true
                choc.normale = Vector2(0, 1)
            return choc


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    unique = rng.random() < 0.5
    if unique:
        corps = gd(f'''
            var _choc := {classe}.new()


            func simuler(delta: float) -> void:
                {IM} += 1
                for k in NOMBRE:
                    {plur}[k].position += _vitesses[k] * delta
                    var choc := _tester({plur}[k].position)
                    if choc.touche:
                        _vitesses[k] = _vitesses[k].bounce(choc.normale) * AMORTI
                        {plur}[k].position = {plur}[k].position.clamp(BORDS.position, BORDS.end)
                        {CO} += 1
            {indenter(d.maj_hud(CO), 1)}


            ## Le même objet sert à chaque test : aucune allocation par image.
            func _tester(p: Vector2) -> {classe}:
                _choc.touche = false
                _choc.normale = Vector2.ZERO
                if p.x < BORDS.position.x or p.x > BORDS.end.x:
                    _choc.touche = true
                    _choc.normale = Vector2(1, 0)
                elif p.y < BORDS.position.y or p.y > BORDS.end.y:
                    _choc.touche = true
                    _choc.normale = Vector2(0, 1)
                return _choc
            ''')
    else:
        corps = gd(f'''
            func simuler(delta: float) -> void:
                {IM} += 1
                for k in NOMBRE:
                    {plur}[k].position += _vitesses[k] * delta
                    var normale := _normale({plur}[k].position)
                    if normale != Vector2.ZERO:
                        _vitesses[k] = _vitesses[k].bounce(normale) * AMORTI
                        {plur}[k].position = {plur}[k].position.clamp(BORDS.position, BORDS.end)
                        {CO} += 1
            {indenter(d.maj_hud(CO), 1)}


            ## Une valeur (Vector2) au lieu d'un objet : rien à allouer. ZERO = pas de contact.
            func _normale(p: Vector2) -> Vector2:
                if p.x < BORDS.position.x or p.x > BORDS.end.x:
                    return Vector2(1, 0)
                if p.y < BORDS.position.y or p.y > BORDS.end.y:
                    return Vector2(0, 1)
                return Vector2.ZERO
            ''')
    reference = entete + "\n\n" + corps + "\n\n" + gd(f'''
        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    return Paire("allocations", "objets", titre, d,
                 {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference}, f"un objet est créé pour chaque test de rebond des {plur}", plur)


# ------------------------------------------------------------------ famille « lots de dessin »

def _mouvement(rng: random.Random) -> tuple[str, str]:
    """(initialisation par entité, mise à jour par entité) : oscillation déterministe autour d'une base."""
    ax, ay = rng.randint(4, 40), rng.randint(4, 30)
    wx, wy = round(rng.uniform(0.01, 0.08), 3), round(rng.uniform(0.01, 0.08), 3)
    maj = (f"e.position = _bases[k] + Vector2(sin(float(t + k * 13) * {f(wx)}) * {ax}.0, "
           f"cos(float(t + k * 7) * {f(wy)}) * {ay}.0)")
    return "", maj


def _bases(rng: random.Random, n: int) -> list[tuple[int, int]]:
    return [(rng.randint(30, 610), rng.randint(30, 330)) for _ in range(n)]


def paire_lots(rng: random.Random, titre: str, variante: str) -> Paire:
    """`textures` : une ImageTexture par entité ; `materiaux` : un CanvasItemMaterial par entité ;
    `atlas` : une texture par type d'entité, types alternés dans l'arbre."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["decor"])
    n = rng.randint(12, 48)
    bases = _bases(rng, n)
    _, maj = _mouvement(rng)
    IM = nom(rng, "image")
    parent = d.parent()
    taille = rng.choice((6, 8, 10, 12, 16))
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n} {plur} flottent dans le décor.

        {d.entete()}
        const BASES: Array[Vector2] = [{", ".join(v2(p) for p in bases)}]

        var {IM}: int = 0
        var _bases: Array[Vector2] = []
        var {plur}: Array[Sprite2D] = []
        ''')
    fin = gd(f'''
        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(_delta: float) -> void:
            {IM} += 1
            var t := {IM}
            for k in {plur}.size():
                var e := {plur}[k]
                {maj}
        {indenter(d.maj_hud(IM), 1)}


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    if variante == "textures":
        forme, c = rng.choice(FORMES), couleur(rng)
        image = f'Motifs.motif("{forme}", {taille}, {coul(c)})'
        boucle_dep = gd(f'''
            func _ready() -> void:
                var image := {image}
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = ImageTexture.create_from_image(image)
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        boucle_ref = gd(f'''
            func _ready() -> void:
                var texture := ImageTexture.create_from_image({image})
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = texture
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        symptome = f"chaque {sing} reçoit sa propre texture, pourtant identique aux autres"
    elif variante == "materiaux":
        forme, c = rng.choice(FORMES), couleur(rng)
        mode = rng.choice(("CanvasItemMaterial.BLEND_MODE_ADD", "CanvasItemMaterial.BLEND_MODE_SUB",
                           "CanvasItemMaterial.BLEND_MODE_MUL"))
        image = f'Motifs.motif("{forme}", {taille}, {coul(c)})'
        boucle_dep = gd(f'''
            func _ready() -> void:
                var texture := ImageTexture.create_from_image({image})
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = texture
                    var materiau := CanvasItemMaterial.new()
                    materiau.blend_mode = {mode}
                    e.material = materiau
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        boucle_ref = gd(f'''
            func _ready() -> void:
                var texture := ImageTexture.create_from_image({image})
                var materiau := CanvasItemMaterial.new()
                materiau.blend_mode = {mode}
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = texture
                    e.material = materiau
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        symptome = f"chaque {sing} reçoit son propre matériau, pourtant réglé comme les autres"
    else:
        types = rng.randint(2, 4)
        formes = rng.sample(FORMES, types)
        couleurs = [couleur(rng) for _ in range(types)]
        images = ", ".join(f'Motifs.motif("{fo}", {taille}, {coul(co)})' for fo, co in zip(formes, couleurs))
        boucle_dep = gd(f'''
            func _ready() -> void:
                var textures: Array[Texture2D] = []
                for image in [{images}]:
                    textures.append(ImageTexture.create_from_image(image))
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = textures[k % textures.size()]
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        boucle_ref = gd(f'''
            ## Un seul atlas : les motifs côte à côte, chaque sprite affiche sa région.
            func _ready() -> void:
                var images: Array[Image] = [{images}]
                var planche := Image.create({taille} * images.size(), {taille}, false, Image.FORMAT_RGBA8)
                for j in images.size():
                    planche.blit_rect(images[j], Rect2i(0, 0, {taille}, {taille}), Vector2i(j * {taille}, 0))
                var atlas := ImageTexture.create_from_image(planche)
                for k in BASES.size():
                    var e := Sprite2D.new()
                    e.texture = atlas
                    e.region_enabled = true
                    e.region_rect = Rect2((k % images.size()) * {taille}, 0, {taille}, {taille})
                    e.position = BASES[k]
                    _bases.append(BASES[k])
                    {parent}.add_child(e)
                    {plur}.append(e)
            ''')
        symptome = f"les {plur} alternent {types} textures différentes dans l'ordre de dessin"
    # Réglages propres à chaque entité (les mêmes dans les deux versions) : variété des réponses.
    extras = rng.sample([
        "e.scale = Vector2.ONE * (1.0 + float(k % 3) * 0.25)",
        f"e.rotation = float(k % 8) * {f(round(rng.uniform(0.2, 0.8), 2))}",
        "e.flip_h = k % 2 == 0",
        f"e.z_index = k % {rng.randint(2, 4)}",
        f"e.self_modulate = Color(1, 1, 1, {f(round(rng.uniform(0.5, 0.8), 2))} + float(k % 4) * 0.05)",
        "e.centered = k % 3 != 0",
    ], rng.randint(0, 3))
    if rng.random() < 0.5:
        boucle_dep = boucle_dep.replace("for k in BASES.size():", "for k in range(BASES.size()):")
        boucle_ref = boucle_ref.replace("for k in BASES.size():", "for k in range(BASES.size()):")

    def avec_extras(code: str) -> str:
        return re.sub(r"^(\t+)e\.position = BASES\[k\]\n",
                      lambda m: m.group(0) + "".join(m.group(1) + x + "\n" for x in extras), code, flags=re.M)
    depart = entete + "\n\n" + avec_extras(boucle_dep) + "\n\n" + fin
    reference = entete + "\n\n" + avec_extras(boucle_ref) + "\n\n" + fin
    return Paire("lots", variante, titre, d, {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference}, symptome, plur)


# ------------------------------------------------------------------ famille « temps »

def paire_voisins(rng: random.Random, titre: str) -> Paire:
    """Agents qui comptent leurs voisins proches : O(N²) au départ, grille de voisinage en référence."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["agents"])
    n = rng.randint(220, 320)
    rayon = rng.randint(10, 22)
    taille = rng.choice((4, 6))
    forme, c = rng.choice(FORMES), couleur(rng)
    IM, NV = nom(rng, "image"), rng.choice(("voisinages", "proximites", "contacts", "rencontres"))
    graine_pos = rng.randint(1, 10_000)
    parent = d.parent()
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n} {plur} se déplacent ; chacun(e) pâlit selon le nombre de voisins proches.

        {d.entete()}
        const NOMBRE := {n}
        const RAYON := {f(rayon)}
        const BORDS := Rect2(0, 0, {LARGEUR - 1}, {HAUTEUR - 1})

        var {IM}: int = 0
        var {NV}: int = 0
        var {plur}: Array[Sprite2D] = []
        var _vitesses: Array[Vector2] = []
        var _voisins: Array[int] = []


        func _ready() -> void:
            var texture := ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))
            for k in NOMBRE:
                var e := Sprite2D.new()
                e.texture = texture
                var h := (k * 7919 + {graine_pos}) % 10007
                e.position = Vector2(float(h % 631) + 4.0, float(h % 349) + 4.0)
                _vitesses.append(Vector2.from_angle(float(h) * 0.017) * (20.0 + float(h % 60)))
                _voisins.append(0)
                {parent}.add_child(e)
                {plur}.append(e)


        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(delta: float) -> void:
            {IM} += 1
            for k in NOMBRE:
                var p := {plur}[k].position + _vitesses[k] * delta
                if p.x < BORDS.position.x or p.x > BORDS.end.x:
                    _vitesses[k].x = -_vitesses[k].x
                if p.y < BORDS.position.y or p.y > BORDS.end.y:
                    _vitesses[k].y = -_vitesses[k].y
                {plur}[k].position = p.clamp(BORDS.position, BORDS.end)
            _compter_voisins()
            {NV} = 0
            for k in NOMBRE:
                {NV} += _voisins[k]
                {plur}[k].modulate = Color(1, 1, 1, 1.0 - 0.15 * float(mini(_voisins[k], 5)))
        {indenter(d.maj_hud(NV), 1)}
        ''')
    depart = entete + "\n\n" + gd(f'''
        func _compter_voisins() -> void:
            var r2 := RAYON * RAYON
            for i in NOMBRE:
                var n := 0
                var p := {plur}[i].position
                for j in NOMBRE:
                    if j != i and p.distance_squared_to({plur}[j].position) < r2:
                        n += 1
                _voisins[i] = n
        ''')
    CEL = rng.choice(("cellules", "cases", "casiers", "seaux"))
    reference = entete + "\n\n" + gd(f'''
        ## Grille de cases de côté RAYON : deux voisins à moins de RAYON sont dans des cases adjacentes.
        const COLONNES := int({LARGEUR} / RAYON) + 1
        const LIGNES := int({HAUTEUR} / RAYON) + 1
        var _{CEL}: Array = []


        func _compter_voisins() -> void:
            # Les PackedInt32Array se copient à l'affectation : on remplace chaque case (ce ne sont
            # pas des objets, rien n'est alloué dans l'ObjectDB).
            _{CEL}.resize(COLONNES * LIGNES)
            for c in _{CEL}.size():
                _{CEL}[c] = PackedInt32Array()
            for i in NOMBRE:
                var p := {plur}[i].position
                var c := int(p.y / RAYON) * COLONNES + int(p.x / RAYON)
                var case: PackedInt32Array = _{CEL}[c]
                case.append(i)
                _{CEL}[c] = case
            var r2 := RAYON * RAYON
            for i in NOMBRE:
                var p := {plur}[i].position
                var cx := int(p.x / RAYON)
                var cy := int(p.y / RAYON)
                var n := 0
                for y in range(maxi(cy - 1, 0), mini(cy + 2, LIGNES)):
                    for x in range(maxi(cx - 1, 0), mini(cx + 2, COLONNES)):
                        for j in (_{CEL}[y * COLONNES + x] as PackedInt32Array):
                            if j != i and p.distance_squared_to({plur}[j].position) < r2:
                                n += 1
                _voisins[i] = n
        ''')
    algo = rng.choice(("grille", "dictionnaire", "balayage"))
    if algo == "dictionnaire":
        reference = entete + "\n\n" + gd(f'''
            ## Cases de côté RAYON rangées dans un dictionnaire (clé : coordonnées de la case) :
            ## deux voisins à moins de RAYON sont dans des cases adjacentes.
            var _{CEL} := {{}}


            func _compter_voisins() -> void:
                _{CEL}.clear()
                for i in NOMBRE:
                    var cle := Vector2i(({plur}[i].position / RAYON).floor())
                    if not _{CEL}.has(cle):
                        _{CEL}[cle] = PackedInt32Array()
                    var liste: PackedInt32Array = _{CEL}[cle]
                    liste.append(i)
                    _{CEL}[cle] = liste
                var r2 := RAYON * RAYON
                for i in NOMBRE:
                    var p := {plur}[i].position
                    var cle := Vector2i((p / RAYON).floor())
                    var n := 0
                    for dy in range(-1, 2):
                        for dx in range(-1, 2):
                            var voisine := cle + Vector2i(dx, dy)
                            if not _{CEL}.has(voisine):
                                continue
                            for j in (_{CEL}[voisine] as PackedInt32Array):
                                if j != i and p.distance_squared_to({plur}[j].position) < r2:
                                    n += 1
                    _voisins[i] = n
            ''')
    elif algo == "balayage":
        reference = entete + "\n\n" + gd(f'''
            ## Balayage : indices triés par abscisse ; pour chacun, on ne regarde que les suivants
            ## dont l'abscisse est à moins de RAYON. Chaque paire proche est comptée pour les deux.
            var _ordre := PackedInt32Array()
            var _abscisses := PackedFloat32Array()


            func _compter_voisins() -> void:
                _abscisses.resize(NOMBRE)
                var cles: Array[Vector2] = []
                for i in NOMBRE:
                    _voisins[i] = 0
                    _abscisses[i] = {plur}[i].position.x
                    cles.append(Vector2({plur}[i].position.x, float(i)))
                cles.sort()
                _ordre.resize(NOMBRE)
                for r in NOMBRE:
                    _ordre[r] = int(cles[r].y)
                var r2 := RAYON * RAYON
                for a in NOMBRE:
                    var i := _ordre[a]
                    var p := {plur}[i].position
                    for b in range(a + 1, NOMBRE):
                        var j := _ordre[b]
                        if _abscisses[j] - p.x >= RAYON:
                            break
                        if p.distance_squared_to({plur}[j].position) < r2:
                            _voisins[i] += 1
                            _voisins[j] += 1
            ''')
    etat = gd(f'''
        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{NV}": {NV}, "voisins": _voisins.duplicate(), "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    return Paire("temps", "voisins", titre, d,
                 {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart + "\n\n" + etat},
                 {"scripts/jeu.gd": reference + "\n\n" + etat},
                 f"le temps par image est élevé : chaque image compare toutes les paires de {plur}", plur, temps=True)


def paire_carte(rng: random.Random, titre: str) -> Paire:
    """Agents qui descendent une carte de distances vers un but : recalculée à chaque image au départ."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["agents"])
    cote = rng.choice((8, 10))
    col, lig = LARGEUR // cote, HAUTEUR // cote
    but = (rng.randint(2, col - 3), rng.randint(2, lig - 3))
    murs = set()
    for _ in range(rng.randint(6, 14)):
        x0, y0 = rng.randint(0, col - 1), rng.randint(0, lig - 1)
        horizontal, longueur = rng.random() < 0.5, rng.randint(4, 18)
        for t in range(longueur):
            x, y = (x0 + t, y0) if horizontal else (x0, y0 + t)
            if 0 <= x < col and 0 <= y < lig and (x, y) != but:
                murs.add((x, y))
    murs_liste = sorted(murs, key=lambda m: (m[1], m[0]))
    n = rng.randint(8, 30)
    vit = rng.randint(30, 90)
    taille = rng.choice((4, 6))
    forme, c = rng.choice(FORMES), couleur(rng)
    IM, CO = nom(rng, "image"), rng.choice(("arrives", "sauves", "rentres", "parvenus"))
    graine_pos = rng.randint(1, 10_000)
    parent = d.parent()
    CARTE = rng.choice(("distances", "carte", "champ", "couts"))
    dirs = ["Vector2i(1, 0)", "Vector2i(-1, 0)", "Vector2i(0, 1)", "Vector2i(0, -1)"]
    rng.shuffle(dirs)
    DIRS = rng.choice(("VOISINES", "DIRECTIONS", "PAS_GRILLE", "QUATRE_SENS"))
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n} {plur} suivent la carte des distances jusqu'au but en évitant les murs.

        {d.entete()}
        const COTE := {cote}
        const COLONNES := {col}
        const LIGNES := {lig}
        const BUT := Vector2i({but[0]}, {but[1]})
        const MURS: Array[Vector2i] = [{", ".join(f"Vector2i({x}, {y})" for x, y in murs_liste)}]
        const VITESSE := {f(vit)}
        const {DIRS}: Array[Vector2i] = [{", ".join(dirs)}]

        var {IM}: int = 0
        var {CO}: int = 0
        var _{CARTE} := PackedInt32Array()
        var {plur}: Array[Sprite2D] = []


        func _physics_process(delta: float) -> void:
            simuler(delta)


        func _calculer_{CARTE}() -> void:
            var bloque := PackedByteArray()
            bloque.resize(COLONNES * LIGNES)
            for m in MURS:
                bloque[m.y * COLONNES + m.x] = 1
            _{CARTE}.resize(COLONNES * LIGNES)
            _{CARTE}.fill(-1)
            var file := PackedInt32Array([BUT.y * COLONNES + BUT.x])
            _{CARTE}[file[0]] = 0
            var tete := 0
            while tete < file.size():
                var c := file[tete]
                tete += 1
                var cx := c % COLONNES
                var cy := c / COLONNES
                for dir in {DIRS}:
                    var nx: int = cx + dir.x
                    var ny: int = cy + dir.y
                    if nx < 0 or ny < 0 or nx >= COLONNES or ny >= LIGNES:
                        continue
                    var v: int = ny * COLONNES + nx
                    if bloque[v] == 0 and _{CARTE}[v] < 0:
                        _{CARTE}[v] = _{CARTE}[c] + 1
                        file.append(v)


        func _case_suivante(case: Vector2i) -> Vector2i:
            var meilleure := case
            var d := _{CARTE}[case.y * COLONNES + case.x]
            for dir in {DIRS}:
                var v: Vector2i = case + dir
                if v.x < 0 or v.y < 0 or v.x >= COLONNES or v.y >= LIGNES:
                    continue
                var dv := _{CARTE}[v.y * COLONNES + v.x]
                if dv >= 0 and (d < 0 or dv < d):
                    d = dv
                    meilleure = v
            return meilleure


        func _deplacer(delta: float) -> void:
            for e in {plur}:
                if not e.visible:
                    continue
                var case := Vector2i(int(e.position.x / COTE), int(e.position.y / COTE))
                if case == BUT:
                    e.visible = false
                    {CO} += 1
                    continue
                var suivante := _case_suivante(case)
                var cible := Vector2(suivante) * COTE + Vector2(COTE, COTE) * 0.5
                e.position = e.position.move_toward(cible, VITESSE * delta)


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in {plur}:
                if e.visible:
                    points.append(e.position)
            return {{"{IM}": {IM}, "{CO}": {CO}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    pret = gd(f'''
        var texture := ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))
        for k in {n}:
            var e := Sprite2D.new()
            e.texture = texture
            var h := (k * 7919 + {graine_pos}) % 10007
            e.position = Vector2(float(h % COLONNES) + 0.5, float(h % LIGNES) + 0.5) * COTE
            {parent}.add_child(e)
            {plur}.append(e)
        ''')
    depart = entete + "\n\n" + gd(f'''
        func _ready() -> void:
        {indenter(pret, 1)}


        func simuler(delta: float) -> void:
            {IM} += 1
            _calculer_{CARTE}()
            _deplacer(delta)
        {indenter(d.maj_hud(CO), 1)}
        ''')
    if rng.random() < 0.5:
        reference = entete + "\n\n" + gd(f'''
            ## Les murs ne bougent pas : la carte des distances se calcule une seule fois, au premier besoin.
            var _{CARTE}_prete := false


            func _ready() -> void:
            {indenter(pret, 1)}


            func simuler(delta: float) -> void:
                {IM} += 1
                if not _{CARTE}_prete:
                    _calculer_{CARTE}()
                    _{CARTE}_prete = true
                _deplacer(delta)
            {indenter(d.maj_hud(CO), 1)}
            ''')
    else:
        reference = None
    reference = reference or entete + "\n\n" + gd(f'''
        ## Les murs ne bougent pas : la carte des distances se calcule une fois, au chargement.
        func _ready() -> void:
        {indenter(pret, 1)}
            _calculer_{CARTE}()


        func simuler(delta: float) -> void:
            {IM} += 1
            _deplacer(delta)
        {indenter(d.maj_hud(CO), 1)}
        ''')
    return Paire("temps", "carte", titre, d, {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference},
                 f"le temps par image est élevé alors que les murs ne bougent jamais", plur, temps=True)


def paire_chemins(rng: random.Random, titre: str) -> Paire:
    """Nœuds retrouvés par get_node et un chemin construit à chaque image ; mis en cache en référence."""
    d = Decor.tirer(rng, titre)
    sing, plur = rng.choice(THEMES["decor"])
    n = rng.randint(300, 500)
    taille = rng.choice((4, 6))
    forme, c = rng.choice(FORMES), couleur(rng)
    IM = nom(rng, "image")
    prefixe = sing.capitalize()
    graine_pos = rng.randint(1, 10_000)
    wx = round(rng.uniform(0.02, 0.09), 3)
    groupe = rng.choice(("Essaim", "Nuee", "Banc", "Troupe"))
    entete = gd(f'''
        extends Node2D
        ## {titre} : {n} {plur} rangé(e)s sous le nœud {groupe}, qui ondulent.

        {d.entete()}
        const NOMBRE := {n}

        var {IM}: int = 0
        var _bases: Array[Vector2] = []


        func _ready() -> void:
            var texture := ImageTexture.create_from_image(Motifs.motif("{forme}", {taille}, {coul(c)}))
            var groupe := Node2D.new()
            groupe.name = "{groupe}"
            add_child(groupe)
            for k in NOMBRE:
                var e := Sprite2D.new()
                e.name = "{prefixe}%d" % k
                e.texture = texture
                var h := (k * 7919 + {graine_pos}) % 10007
                _bases.append(Vector2(float(h % 631) + 4.0, float(h % 349) + 4.0))
                e.position = _bases[k]
                groupe.add_child(e)
        ''')
    corps_maj = f"e.position = _bases[k] + Vector2(sin(float({IM} + k) * {f(wx)}) * 6.0, 0.0)"
    depart = entete + "\n\n" + gd(f'''
        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(_delta: float) -> void:
            {IM} += 1
            for k in NOMBRE:
                var e := get_node("{groupe}/{prefixe}%d" % k) as Sprite2D
                {corps_maj}
        {indenter(d.maj_hud(IM), 1)}


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for k in NOMBRE:
                points.append((get_node("{groupe}/{prefixe}%d" % k) as Sprite2D).position)
            return {{"{IM}": {IM}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    reference = entete + gd(f'''
            for e in groupe.get_children():
                _{plur}.append(e as Sprite2D)


        var _{plur}: Array[Sprite2D] = []


        func _physics_process(delta: float) -> void:
            simuler(delta)


        func simuler(_delta: float) -> void:
            {IM} += 1
            for k in NOMBRE:
                var e := _{plur}[k]
                {corps_maj}
        {indenter(d.maj_hud(IM), 1)}


        func etat() -> Dictionary:
            var points: Array[Vector2] = []
            for e in _{plur}:
                points.append(e.position)
            return {{"{IM}": {IM}, "{plur}": _points(points)}}
        ''') + "\n" + gd(ETAT_POINTS)
    return Paire("temps", "chemins", titre, d, {"scripts/" + d.motifs + ".gd": script_motifs(), "scripts/jeu.gd": depart},
                 {"scripts/jeu.gd": reference},
                 f"le temps par image est élevé : chaque image retrouve les {plur} par leur chemin", plur, temps=True)


VARIANTES: dict[str, Callable[[random.Random, str], Paire]] = {
    "tir": paire_tir,
    "eclats": paire_eclats,
    "vagues": paire_vagues,
    "objets": paire_objets,
    "textures": lambda r, t: paire_lots(r, t, "textures"),
    "materiaux": lambda r, t: paire_lots(r, t, "materiaux"),
    "atlas": lambda r, t: paire_lots(r, t, "atlas"),
    "voisins": paire_voisins,
    "carte": paire_carte,
    "chemins": paire_chemins,
}
# Part de chaque variante dans la production (somme = 1).
PARTS = {"tir": 0.14, "eclats": 0.11, "vagues": 0.11, "objets": 0.09, "textures": 0.10, "materiaux": 0.09,
         "atlas": 0.10, "voisins": 0.09, "carte": 0.09, "chemins": 0.08}


# ------------------------------------------------------------------ vérification et écriture

SCRIPT_ETAT = gd('''
    extends SceneTree
    ## Rejoue le jeu comme le test caché : simuler(1/60) à la main, état aux images de contrôle.
    ## Le jeu entre dans l'arbre pendant _initialize, mais son _ready n'a lieu qu'à la première
    ## image : la simulation se fait donc dans _process (et quit() dans _initialize ne rend pas la main).

    var jeu: Node


    func _initialize() -> void:
        jeu = load("res://scenes/jeu.tscn").instantiate()
        # Désactivé avant d'entrer dans l'arbre : le moteur n'appelle pas _physics_process à la
        # première image (seuls les appels à simuler() comptent, comme dans le test caché).
        jeu.process_mode = Node.PROCESS_MODE_DISABLED
        root.add_child(jeu)


    func _process(_delta: float) -> bool:
        jeu.set_physics_process(false)
        jeu.set_process(false)
        var points: Array = []
        for a in OS.get_cmdline_user_args()[0].split(","):
            points.append(int(a))
        for i in range(1, points.max() + 1):
            jeu.simuler(1.0 / 60.0)
            if i in points:
                print("@@USINE@@" + JSON.stringify({"image": i, "etat": JSON.stringify(jeu.etat())}))
        return true
    ''')


def test_cache(etats: dict[int, str], titre: str) -> str:
    def lit(s: str) -> str:
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
    tests = []
    for image, attendu in sorted(etats.items()):
        tests.append(gd(f'''
            func test_etat_image_{image:03d}() -> void:
                var jeu := _jeu()
                for i in {image}:
                    jeu.simuler(1.0 / 60.0)
                assert_str(JSON.stringify(jeu.etat())).is_equal({lit(attendu)})
            '''))
    return gd(f'''
        extends GdUnitTestSuite
        ## Comportement de « {titre} » : l'état du jeu aux images de contrôle est celui de la référence.


        func _jeu() -> Node:
            var jeu: Node = auto_free(load("res://scenes/jeu.tscn").instantiate())
            add_child(jeu)
            jeu.set_physics_process(false)
            jeu.set_process(false)
            return jeu
        ''') + "\n\n" + "\n\n".join(tests)


def consigne(p: Paire, mesure_dep: dict[str, Any], mesure_ref: dict[str, Any]) -> str:
    rapport = (f"Mesure du jeu tel quel (Godot headless, 60 images/s, échauffement de {REGLAGES.echauffement} "
               f"images, fenêtre jusqu'à l'image {REGLAGES.fin}) : {mesure_dep['allocations']} objet(s) alloué(s) "
               f"dans la fenêtre, {mesure_dep['lots']} lot(s) de dessin par image")
    rapport += " ; le temps par image est trop élevé." if p.temps else "."
    return (
        f"Optimisation stricte de « {p.titre} » (scripts/jeu.gd) : {p.symptome}.\n"
        f"{rapport}\n"
        "Rends le jeu plus efficace sans changer ni son comportement ni son rendu : à chaque image, les mêmes "
        f"{p.entites} aux mêmes positions, avec les mêmes pixels, couleurs et matériaux. Ne touche ni à la "
        "résolution, ni aux sections [display] et [rendering] de project.godot, ni à la lumière, à la teinte ou "
        "au fond de la scène. Garde `simuler(delta)` et `etat()` : les tests du jeu les appellent.\n"
        "Critères du juge, après l'échauffement : aucune allocation d'objet ; au plus autant de lots de dessin "
        "que la solution de référence (+5 %) ; un temps par image au plus 1,15 fois celui de la référence. "
        "Un rendu modifié est refusé, même plus rapide."
    )


@dataclass
class Candidat:
    ident: str
    paire: Paire
    raison: str | None = None
    detail: str = ""
    etats: dict[int, str] = field(default_factory=dict)
    mesures: dict[str, Any] = field(default_factory=dict)


def _fichiers(p: Paire, version: str) -> dict[str, str]:
    base = {"project.godot": p.decor.project_godot(), "scenes/jeu.tscn": p.decor.scene(), **p.depart}
    return {**base, **p.reference} if version == "reference" else base


def _etats(fichiers: dict[str, str]) -> tuple[dict[int, str], str]:
    resultats, sortie = executer_gd(fichiers, SCRIPT_ETAT, [",".join(str(i) for i in POINTS_CONTROLE)], delai_s=300)
    return {int(r["image"]): r["etat"] for r in resultats}, sortie


def verifier(c: Candidat) -> Candidat:
    """Comportement, rendu, efficience : remplit c.raison si la paire est à écarter."""
    import tempfile
    p = c.paire
    try:
        etats = {}
        for version in ("depart", "reference"):
            e, sortie = _etats(_fichiers(p, version))
            if len(e) != len(POINTS_CONTROLE):
                c.raison, c.detail = "paire_ne_tourne_pas", f"{version} : " + sortie[-600:]
                return c
            etats[version] = e
        if etats["depart"] != etats["reference"]:
            premier = min(i for i in POINTS_CONTROLE if etats["depart"][i] != etats["reference"][i])
            c.raison, c.detail = "paire_comportement_different", f"première différence à l'image {premier}"
            return c
        c.etats = etats["reference"]
        with tempfile.TemporaryDirectory(prefix="usine_paire_") as tmp:
            dossiers = {v: ecrire_projet(_fichiers(p, v), Path(tmp) / v) for v in ("depart", "reference")}
            with mes.Copie.ouvrir(dossiers["depart"]) as cd, mes.Copie.ouvrir(dossiers["reference"]) as cr:
                md = mes.lancer(cd.projet, REGLAGES, "deterministe")
                mr = mes.lancer(cr.projet, REGLAGES, "deterministe")
                c.mesures = {"depart": md, "reference": mr}
                from usine.efficience.juge import comparer_rendu
                ecarts = comparer_rendu(mr, md)
                if ecarts:
                    c.raison, c.detail = "paire_rendu_different", ecarts[0]
                    return c
                if mr["allocations"] != 0:
                    c.raison, c.detail = "reference_alloue", f"{mr['allocations']} allocations"
                    return c
                if p.famille == "allocations" and md["allocations"] <= 0:
                    c.raison = "depart_deja_efficace"
                    c.detail = "le départ n'alloue rien"
                elif p.famille == "lots" and md["lots"] <= mr["lots"] * 1.05:
                    c.raison = "depart_deja_efficace"
                    c.detail = f"lots {md['lots']} contre {mr['lots']}"
                elif p.famille == "temps":
                    if md["allocations"] != 0 or md["lots"] != mr["lots"]:
                        c.raison, c.detail = "paire_non_isolee", "le départ diffère hors du temps"
                        return c
                    td, tr = mes.mesurer_temps_croises(cd, cr, REGLAGES)
                    rapport = mes.mediane(td) / max(1.0, mes.mediane(tr))
                    c.mesures["rapport_temps"] = rapport
                    if rapport < RAPPORT_TEMPS_MIN:
                        c.raison = "ecart_temps_insuffisant"
                        c.detail = f"départ {rapport:.2f} × la référence (minimum {RAPPORT_TEMPS_MIN})"
    except mes.ErreurMesure as e:
        c.raison, c.detail = "mesure_impossible", str(e)[:600]
    return c


def ecrire(c: Candidat, sortie: Path) -> Path:
    p = c.paire
    md, mr = c.mesures["depart"], c.mesures["reference"]
    tache = {
        "id": c.ident,
        "competence": COMPETENCE,
        "consigne": consigne(p, md, mr),
        "origine": ORIGINE,
        "generateur": {"nom": "efficience", "famille": p.famille, "variante": p.variante},
        "mesure_efficience": {
            "scene": REGLAGES.scene, "echauffement": REGLAGES.echauffement, "fin": REGLAGES.fin,
            "images_rendu": list(REGLAGES.images_rendu), "temps": p.temps,
            "seuils": {"allocations": 0, "lots": 1.05, "temps": 1.15},
            "reference": {"lots": mr["lots"], "allocations": mr["allocations"]},
            "depart": {"lots": md["lots"], "allocations": md["allocations"]},
        },
        "juge": {"etapes": ["import", "check_script", "load_scene", "run_tests"]},
    }
    depart = _fichiers(p, "depart")
    tests = {"test_comportement.gd": test_cache(c.etats, p.titre)}
    return ecrire_tache(sortie, tache, depart, p.reference, tests)


TITRES = ("Pluie", "Arène", "Rempart", "Verger", "Lagon", "Forge", "Clairière", "Ruche", "Comète", "Marais",
          "Citadelle", "Grotte", "Fanal", "Prairie", "Volcan", "Atelier", "Quai", "Désert", "Jardin", "Orage")


def plan(graine: int, nombre: int) -> list[tuple[str, str, int]]:
    """[(id, variante, graine de la paire)] : répartition fixe par PARTS, ordre reproductible."""
    rng = random.Random(f"efficience:{graine}")
    quotas = {v: int(round(PARTS[v] * nombre)) for v in VARIANTES}
    while sum(quotas.values()) > nombre:
        quotas[max(quotas, key=quotas.get)] -= 1
    while sum(quotas.values()) < nombre:
        quotas[min(quotas, key=quotas.get)] += 1
    resultat = []
    for v in VARIANTES:
        for k in range(quotas[v]):
            resultat.append((f"e_{v}_{k + 1:03d}", v, rng.randint(0, 2 ** 31)))
    return resultat


# Noms génériques des gabarits et leurs synonymes : le même renommage s'applique au départ et à
# la référence d'une paire. Sans lui, deux paires de la même variante auraient presque la même
# réponse, et l'exclusion des jeux gelés (fragments, Jaccard ≥ 0,8) écarterait le reste.
SYNONYMES = {
    "k": ("k", "n", "idx", "num", "rang"),
    "e": ("e", "ent", "sp", "obj", "item"),
    "texture": ("texture", "tex", "apparence", "peau", "tex_commune"),
    "_texture": ("_texture", "_tex", "_apparence", "_peau", "_visuel"),
    "materiau": ("materiau", "mat", "melange", "effet", "fusion"),
    "BASES": ("BASES", "ANCRES", "POSITIONS", "REPERES", "PLACES"),
    "_bases": ("_bases", "_ancres", "_origines", "_reperes", "_points_fixes"),
    "NOMBRE": ("NOMBRE", "TOTAL", "EFFECTIF", "POPULATION", "QUANTITE"),
    "_vitesses": ("_vitesses", "_vels", "_deplacements", "_elans", "_derives"),
    "_ages": ("_ages", "_durees", "_vies", "_compteurs", "_horloges"),
    "points": ("points", "positions", "coords", "liste_pos", "releves"),
    "RAYON": ("RAYON", "PORTEE", "DISTANCE_VUE", "PROXIMITE", "ALLONGE"),
    "_voisins": ("_voisins", "_proches", "_entourage", "_densites", "_comptes"),
    "origine": ("origine", "depart_pos", "point", "source", "lieu"),
    "vitesse": ("vitesse", "vel", "impulsion", "elan", "pousse"),
    "_tester": ("_tester", "_verifier_bords", "_sonder", "_examiner", "_controler"),
    "BORDS": ("BORDS", "CADRE", "LIMITES", "ENCEINTE", "ARENE"),
    "groupe": ("groupe", "conteneur", "noeud_groupe", "racine_groupe", "dossier"),
    "file": ("file", "attente", "frontiere", "a_visiter", "pile_bfs"),
    "tete": ("tete", "curseur", "lecture", "position_file", "indice"),
    "bloque": ("bloque", "obstacles", "interdit", "occupe", "fermes"),
    "_emettre": ("_emettre", "_lancer", "_projeter", "_semer", "_jaillir"),
    "_tirer": ("_tirer", "_lancer_tir", "_decocher", "_projeter_tir", "_envoyer"),
    "_faire_apparaitre": ("_faire_apparaitre", "_engendrer", "_invoquer", "_lacher", "_introduire"),
    "_deplacer": ("_deplacer", "_avancer_tous", "_marcher", "_progresser", "_mouvoir"),
    "_compter_voisins": ("_compter_voisins", "_mesurer_densite", "_recenser", "_denombrer", "_sonder_voisinage"),
    "centre": ("centre", "foyer", "coeur", "epicentre", "point_impact"),
    "direction": ("direction", "cap", "axe_tir", "orientation", "sens"),
    "_case_suivante": ("_case_suivante", "_pas_suivant", "_prochaine_case", "_descendre", "_choisir_case"),
    "meilleure": ("meilleure", "choix", "elue", "retenue", "candidate"),
    "suivante": ("suivante", "prochaine", "etape", "relais", "visee"),
    "cible": ("cible", "but_local", "destination", "objectif", "arrivee"),
    "dv": ("dv", "dist_v", "cout", "rang_v", "profondeur"),
    "dir": ("dir", "d4", "delta_case", "pas_case", "decalage"),
}
_CHAINE_OU_COMMENTAIRE = re.compile(r'"(?:[^"\\]|\\.)*"|#[^\n]*')
_IDENTIFIANT = re.compile(r"(?<![.\w$])([A-Za-z_]\w*)\b(?!\s*:\s*$)")


def renommer(code: str, table: dict[str, str]) -> str:
    """Renomme les identifiants (hors chaînes, commentaires et accès `.membre`)."""
    def remplacer(morceau: str) -> str:
        return re.sub(r"(?<![.\w$])([A-Za-z_]\w*)\b", lambda m: table.get(m.group(1), m.group(1)), morceau)
    sortie, pos = [], 0
    for m in _CHAINE_OU_COMMENTAIRE.finditer(code):
        sortie.append(remplacer(code[pos:m.start()]))
        sortie.append(m.group(0))
        pos = m.end()
    sortie.append(remplacer(code[pos:]))
    return "".join(sortie)


def construire(ident: str, variante: str, graine_paire: int) -> Candidat:
    rng = random.Random(graine_paire)
    titre = f"{rng.choice(TITRES)} {ident.rsplit('_', 1)[1]}"
    paire = VARIANTES[variante](rng, titre)
    table = {nom: rng.choice(choix) for nom, choix in SYNONYMES.items()}
    # Pas de collision avec un nom déjà présent dans le code (constantes, variables de la paire).
    existants = set(re.findall(r"[A-Za-z_]\w*", paire.depart["scripts/jeu.gd"] + paire.reference["scripts/jeu.gd"]))
    table = {a: b for a, b in table.items() if a == b or b not in existants}
    paire.depart["scripts/jeu.gd"] = renommer(paire.depart["scripts/jeu.gd"], table)
    paire.reference["scripts/jeu.gd"] = renommer(paire.reference["scripts/jeu.gd"], table)
    return Candidat(ident, paire)


def generer(sortie: Path, graine: int, nombre: int = NOMBRE_DEFAUT, travailleurs: int = 4) -> Production:
    prod = Production()
    candidats = [construire(i, v, g) for i, v, g in plan(graine, nombre)]
    # Les paires « temps » se mesurent sans concurrence (le chronomètre ne doit pas voir les autres).
    rapides = [c for c in candidats if not c.paire.temps]
    lentes = [c for c in candidats if c.paire.temps]
    with ThreadPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        verifies = list(pool.map(verifier, rapides))
    verifies += [verifier(c) for c in lentes]
    for c in sorted(verifies, key=lambda c: c.ident):
        if c.raison:
            prod.ecarter("efficience", c.ident, c.raison, c.detail)
        else:
            prod.taches.append(ecrire(c, sortie))
    return prod
