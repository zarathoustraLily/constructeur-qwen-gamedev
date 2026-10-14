"""Ce qu'on cite dans « Chercher » : passages de la doc de Godot (selon ce que l'étape emploie) et sources
de métier (notes d'étape, carnets de recherche de Tokyo et de New York)."""
from __future__ import annotations

import re

from usine.cours.base import chemins

# (numéro d'étape ou None pour toutes, mot qui doit figurer dans le code nouveau, page, titre, texte exact)
DOC = [
    (1, "SurfaceTool", "tutorials/3d/procedural_geometry/surfacetool.rst", "Using the SurfaceTool",
     "The :ref:`SurfaceTool <class_surfacetool>` provides a useful interface for constructing geometry."),
    (2, "shader_type spatial", "tutorials/shaders/shader_reference/spatial_shader.rst", "Spatial shaders",
     "Spatial shaders are used for shading 3D objects. They are the most complex type of shader Godot offers."),
    (None, "MultiMesh", "tutorials/performance/using_multimesh.rst", "Optimization using MultiMeshes",
     "A :ref:`MultiMesh<class_MultiMesh>` is a single draw primitive that can draw up to millions\nof objects in one go."),
    (None, "INSTANCE_CUSTOM", "tutorials/shaders/shader_reference/spatial_shader.rst", "Spatial shaders",
     "For instancing, the ``INSTANCE_CUSTOM`` variable contains the instance custom data."),
    (None, "Label3D", "tutorials/3d/3d_text.rst", "3D text",
     "Godot provides 2 methods to do this: the\nLabel3D node and the TextMesh *resource* for a MeshInstance3D node."),
    (None, "RandomNumberGenerator", "tutorials/math/random_number_generation.rst", "Random number generation",
     "If you use the same seed,\nyou'll get the same sequence of random numbers every run."),
    (11, "RandomNumberGenerator", "tutorials/math/random_number_generation.rst", "Random number generation",
     "RandomNumberGenerator requires more code to use, but allows creating multiple\ninstances, each with their own seed and state."),
    (None, "visibility_range", "tutorials/3d/visibility_ranges.rst", "Visibility ranges (HLOD)",
     "visibility ranges are another tool to improve performance in large,\ncomplex 3D scenes."),
    (None, "OccluderInstance3D", "tutorials/3d/occlusion_culling.rst", "Occlusion culling",
     "In a 3D rendering engine, **occlusion culling** is the process of performing\nhidden geometry removal."),
    (13, "", "tutorials/performance/optimizing_3d_performance.rst", "Optimizing 3D performance",
     "If you have many identical objects in your scene, you can use automatic\ninstancing to reduce the number of draw calls."),
]


def _propre(texte: str) -> str:
    t = re.sub(r":ref:`([^<`]+?)\s*<[^>]+>`", r"\1", texte)
    t = re.sub(r"``([^`]+)``", r"`\1`", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"\1", t)
    t = re.sub(r"\*([^*]+)\*", r"\1", t)
    return re.sub(r"\s+", " ", t).strip()


def doc(etape: int, code_nouveau: str) -> list[tuple[str, str]]:
    sortie = []
    vus = set()
    for numero, mot, chemin, titre, texte in DOC:
        if numero is not None and numero != etape:
            continue
        if mot and mot not in code_nouveau:
            continue
        contenu = (chemins.actuels().docs_godot / chemin).read_text(encoding="utf-8")
        assert texte in contenu, (chemin, texte)
        if texte not in vus:
            vus.add(texte)
            propre = _propre(texte)
            if propre[:1].islower():
                propre = "[…] " + propre
            sortie.append((titre, propre))
    return sortie


VAN_DONGEN = ("Joost van Dongen, « Interior Mapping: A new technique for rendering realistic buildings », "
              "Computer Graphics International, 2008 : la pièce n'est pas modélisée, le shader la calcule derrière la vitre.")
CITE_BALCONS = ("Cité de l'architecture et du patrimoine, fiche de la maquette « L'immeuble 1, boulevard Saint-Michel, 1860 » : "
                "« les lignes de balcons et des séparations d'étages forment des lignes continues d'un immeuble à l'autre », "
                "balcons « aux deuxième et cinquième étages ». "
                "<https://www.citedelarchitecture.fr/sites/default/files/documents/2017-09/fo_boulevardsaintmichel_def.pdf>")
GABARIT_1859 = ("Ville de Paris, document sur le secteur sauvegardé du Marais, chapitre III.6 « Le XXe siècle », p. 260 : "
                "« le règlement de 1859 autorisant le relèvement de la corniche de 17, 54 à 20 mètres ». "
                "<https://cdn.paris.fr/paris/2020/02/26/a4878f9d14006d1dcb7c244500153fa5.pdf>")
DIAGONALE = ("Pour la diagonale à 45° des combles : source de seconde main (Wikipédia, « Règlements d'urbanisme de Paris », "
             "qui cite B. Landau et C. Mignot) ; ce chiffre n'a pas été retrouvé dans un texte d'institution.")
TK_GABARIT = ("Arrondissement d'Ōta, « 建物の高さについての制限 » : gabarit oblique sur rue (道路斜線制限), pente 1,25 dans les "
              "zones d'habitation et 1,5 ailleurs, mesurée depuis la limite opposée de la voie (前面道路の反対側の境界線), "
              "seulement jusqu'à une distance d'application (適用距離) de 20 à 35 m. "
              "<https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/tatemono_tyuuikisei/takasaseigen.html>")
TK_BARREAUX = ("Arrondissement de Nakano, note du 1er septembre 2022 sur les garde-corps (令2条1項6号ハ) : un garde-corps de balcon "
               "à barreaux verticaux, « 見通しがきき、採光通風に影響のないもの », peut ne pas être compté dans la hauteur pour le "
               "gabarit sur rue ; c'est la pratique de cet arrondissement. "
               "<https://www.city.tokyo-nakano.lg.jp/machizukuri/kenchiku/tetsuzuki/kakunin-shinsei/kenchikukijyunho.files/tesuri20220901.pdf>")
TK_GARDE_CORPS = ("Réponse du Cabinet à la Chambre des représentants, n° 48, 8 décembre 2020 : autour des toits-terrasses "
                  "(屋上広場等), un garde-corps d'au moins 1,1 m (règlement d'application, art. 126) ; le cours prend la même "
                  "hauteur pour les balcons, extension non vérifiée dans le texte. "
                  "<https://www.shugiin.go.jp/internet/itdb_shitsumon.nsf/html/shitsumon/b203048.htm>")
TK_ENSEIGNES = ("Bureau des routes nationales de Tokyo, « 占用許可申請の詳細 » : enseignes en drapeau et stores, saillie de 1,0 m "
                "au plus ; enseignes murales, 0,3 m ; bas de l'enseigne à 2,5 m au moins du sol (règles de ce gestionnaire, "
                "pour ses routes). <https://www.ktr.mlit.go.jp/toukoku/toukoku00078.html>")
TK_POLICES = ("Microsoft Learn, « Windows 11 font list » : « Yu Gothic » et « MS Gothic » sont dans la liste de base de "
              "Windows 11 ; « Meiryo » est une police supplémentaire. <https://learn.microsoft.com/typography/fonts/windows_11_font_list>")
TK_LIMITE = ("Code civil japonais, art. 234 : « 建物を築造するには、境界線から50センチメートル以上の距離を保たなければならない。 », "
             "cité par un géomètre-expert. <https://smtrc.jp/useful/qa/kyokaihikai/qa-kyokaihikai_06.html>")
TK_VOIES = ("Arrondissement d'Ōta, « 2項道路 » : une voie fait en principe 4 m au moins ; les ruelles de 1,8 à 4 m sont "
            "réputées voies si l'on recule à 2 m de l'axe. <https://www.city.ota.tokyo.jp/seikatsu/sumaimachinami/kenchiku/k_douro/douro.html>")

EN_PLUS = {
    ("parisien", 5): [VAN_DONGEN], ("tokyoiste", 5): [VAN_DONGEN],
    ("parisien", 6): [CITE_BALCONS], ("parisien", 7): [CITE_BALCONS], ("parisien", 9): [GABARIT_1859, DIAGONALE],
    ("tokyoiste", 7): [TK_GARDE_CORPS], ("tokyoiste", 9): [TK_GABARIT, TK_BARREAUX],
    ("tokyoiste", 10): [TK_ENSEIGNES, TK_POLICES], ("tokyoiste", 12): [TK_LIMITE, TK_VOIES],
}


def metier(ville: str, etape: int, sources_note: list[str]) -> list[str]:
    return list(sources_note) + [s for s in EN_PLUS.get((ville, etape), []) if s not in sources_note]
