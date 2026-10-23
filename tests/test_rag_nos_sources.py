"""RAG : glossaire français-anglais, nos sources (notes, code des cours, fiches de plugins), banc de mesure."""

from pathlib import Path

from usine.rag import banc, glossaire, nos_sources

NOTE = """# Kart · étape 005 · Le décor

**Piste : Shader.** L'île se peuple.

## Ce qu'on a fait, dans l'ordre

### 1. Un décor, des scènes réutilisées

Le rocher a une forme exacte (`ConcavePolygonShape3D`) ; le palmier, une capsule.

### 2. Le vent : des paramètres globaux de shader

Les changer change le vent : `RenderingServer.global_shader_parameter_set()`, et `wind_strength`.

## Les tests

- `test_decor.gd` : rochers solides.
"""


def test_les_mots_francais_trouvent_leur_equivalent():
    g = glossaire.groupes("aller vers la cible en évitant les obstacles")
    assert [x[0] for x in g] == ["aller", "vers", "cible", "évitant", "obstacles"]
    assert "target" in g[2] and "avoidance" in g[3] and "NavigationObstacle3D" in g[4]


def test_les_expressions_passent_avant_les_mots():
    g = glossaire.groupes("une machine à états pour l'ennemi")
    assert g[0][0] == "machine à états" and "StateMachine" in g[0]
    assert ["ennemi", "enemy", "mob"] in g
    assert all(x[0] not in ("une", "pour", "l") for x in g)


def test_un_mot_inconnu_reste_seul_et_les_identifiants_aussi():
    assert glossaire.groupes("move_and_slide") == [["move_and_slide"]]
    assert glossaire.groupes("CharacterBody3D saute") == [["CharacterBody3D"], ["saute"]]


def test_les_points_d_une_note_deviennent_des_fragments(tmp_path):
    readme = tmp_path / "kart_etape_005" / "README.md"
    readme.parent.mkdir()
    readme.write_text(NOTE, encoding="utf-8")
    fr = nos_sources.fragments_notes(readme, "kart")
    assert [f.titre for f in fr] == ["Kart · étape 005 · Le décor › 1. Un décor, des scènes réutilisées",
                                     "Kart · étape 005 · Le décor › 2. Le vent : des paramètres globaux de shader"]
    assert all(f.genre == "cours" and f.source == "cours/kart/kart_etape_005/README.md" for f in fr)
    assert "test_decor" not in fr[1].texte  # la section « Les tests » n'appartient pas au point 2


def test_le_banc_attend_les_classes_citees(tmp_path):
    readme = tmp_path / "README.md"
    readme.write_text(NOTE, encoding="utf-8")
    p = banc.points(readme, {"ConcavePolygonShape3D", "RenderingServer"})
    assert p == [{"demande": "Un décor, des scènes réutilisées", "attendues": ["ConcavePolygonShape3D"]},
                 {"demande": "Le vent : des paramètres globaux de shader", "attendues": ["RenderingServer"]}]


def test_seul_le_dernier_projet_de_chaque_cours_donne_son_code(tmp_path):
    for nom in ("kart/projets/kart_etape_013", "kart/projets/kart_etape_014",
                "batiments_proceduraux/projets/building_proceduraux_parisien_etape_013",
                "batiments_proceduraux/projets/building_proceduraux_tokyoiste_etape_012",
                "batiments_proceduraux/projets/building_proceduraux_tokyoiste_etape_013"):
        (tmp_path / "cours" / nom).mkdir(parents=True)
    retenus = [(c, p.name) for c, p in nos_sources.derniers_projets(tmp_path)]
    assert retenus == [("batiments_proceduraux", "building_proceduraux_parisien_etape_013"),
                       ("batiments_proceduraux", "building_proceduraux_tokyoiste_etape_013"),
                       ("kart", "kart_etape_014")]


def test_le_code_des_addons_n_entre_pas(tmp_path):
    projet = tmp_path / "kart_etape_014"
    (projet / "addons" / "gdUnit4").mkdir(parents=True)
    (projet / "addons" / "gdUnit4" / "x.gd").write_text("extends Node\nfunc f() -> void:\n\tpass\n", encoding="utf-8")
    (projet / "6_assets").mkdir()
    (projet / "6_assets" / "eau.gdshader").write_text("shader_type spatial;\n", encoding="utf-8")
    fr = nos_sources.fragments_code(projet, "kart")
    assert [f.source for f in fr] == ["cours/kart/kart_etape_014/6_assets/eau.gdshader"]


def test_les_fiches_de_plugins_sont_indexees():
    fr, compte = nos_sources.fragments_plugins()
    assert compte["plugins"] >= 1
    assert any(f.genre == "plugin" and f.titre.startswith("plugin Phantom Camera") for f in fr)
    assert any(f.genre == "exemple" and f.source == "rag/plugins/phantom_camera/exemple/exemple.gd" for f in fr)
