"""Catalogue de morceaux de code du RAG : manifeste, code rangé comme dans le plan, projet de vérification, index."""

from usine.rag import catalogue, morceaux, nos_sources

SOURCES = ("mesuré", "godot-docs", "référence des classes", "principe", "règle")


def test_chaque_morceau_a_son_code_son_rangement_et_des_pieges_sources():
    entrees = morceaux.manifeste()
    assert len(entrees) >= 9
    for ident, entree in entrees.items():
        exemple = morceaux.DOSSIER / ident / "exemple"
        assert (exemple / "exemple.gd").is_file(), ident
        assert {"titre", "fait", "quand", "rangement", "pieges"} <= set(entree), ident
        assert catalogue.fichiers_de_code(exemple) or entree.get("project_godot"), f"{ident} : aucun code à montrer"
        for rel in entree.get("socle", []):
            assert (catalogue.SOCLE / rel).is_file(), f"{ident} : {rel} absent du socle"
        for piege in entree["pieges"]:
            assert any(s in piege for s in SOURCES), f"{ident} : piège sans source : {piege}"


def test_le_code_garde_son_chemin_du_plan_dans_le_projet(tmp_path):
    entree = morceaux.manifeste()["etat_etourdi"]
    catalogue.preparer(morceaux.CATALOGUE, "etat_etourdi", entree, tmp_path)
    assert (tmp_path / "3_entities/robot/states/robot_stunned.gd").is_file()
    assert (tmp_path / "5_data/actors/robot.tres").is_file()
    assert (tmp_path / "1_core/state_machine/state_machine.gd").is_file()  # copié du socle
    assert sorted(p.name for p in (tmp_path / "exemple").iterdir()) == ["exemple.gd", "main.tscn"]
    assert "[debug]" in (tmp_path / "project.godot").read_text(encoding="utf-8")


def test_l_extrait_de_project_godot_entre_dans_le_projet_et_dans_la_fiche(tmp_path):
    entree = morceaux.manifeste()["entrees_manette"]
    catalogue.preparer(morceaux.CATALOGUE, "entrees_manette", entree, tmp_path)
    assert "InputEventJoypadMotion" in (tmp_path / "project.godot").read_text(encoding="utf-8")
    texte = morceaux.fiche("entrees_manette", entree, "mesure")
    assert "## Le code (`project.godot`, extrait vérifié)" in texte and "InputEventJoypadButton" in texte


def test_les_fiches_de_morceaux_sont_indexees_sans_doublon_de_code():
    fr, compte = nos_sources.fragments_morceaux()
    assert compte["morceaux"] >= 9 and compte["scripts"] >= 9
    assert any(f.genre == "morceau" and "Inventaire" in f.titre for f in fr)
    assert any(f.genre == "exemple" and f.source.startswith(
        "rag/morceaux/inventaire_piles/exemple/1_core/components/inventory_component.gd") for f in fr)
    assert not any(f.genre == "morceau" and ("› Le code" in f.titre or "› L'employer" in f.titre) for f in fr)
