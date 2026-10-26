"""Catalogue d'effets du RAG : manifeste, fiches tirées du code vérifié, indexation."""

import re

from usine.rag import effets, nos_sources

# Un piège est mesuré par l'exemple, cité dans sa source, renvoie au plan, ou est marqué « non mesuré ici ».
SOURCES = ("mesuré", "godot-docs", "référence des classes", "principe")


def test_chaque_effet_du_manifeste_a_son_exemple_et_des_pieges_sources():
    catalogue = effets.manifeste()
    assert len(catalogue) >= 6
    for ident, entree in catalogue.items():
        exemple = effets.DOSSIER / ident / "exemple"
        assert (exemple / "exemple.gd").is_file(), ident
        assert list(exemple.glob("*.gdshader")), ident
        assert {"titre", "fait", "quand", "pieges"} <= set(entree), ident
        for piege in entree["pieges"]:
            assert any(s in piege for s in SOURCES), f"{ident} : piège sans source : {piege}"


def test_les_fonctions_de_pilotage_sont_appelees_par_l_exemple():
    for ident in effets.effets():
        script = (effets.DOSSIER / ident / "exemple" / "exemple.gd").read_text(encoding="utf-8")
        noms = [m.group(1) for m in map(effets.RE_FONCTION_PUBLIQUE.match, script.splitlines()) if m]
        assert noms, f"{ident} : aucune fonction de pilotage"
        for nom in noms:
            appels = len(re.findall(rf"\b{nom}\(", script)) - 1  # la définition elle-même
            assert appels >= 1, f"{ident} : {nom} n'est pas appelée, donc pas vérifiée"


def test_fonctions_publiques_garde_la_documentation_et_ignore_le_reste():
    script = ("extends Node\n\n\nfunc _ready() -> void:\n\tflasher(1.0)\n\n\n"
              "## Le coup.\n## Deux lignes.\nfunc flasher(d: float) -> void:\n\tprint(d)\n\n\tprint(2)\n\n\n"
              "func _aide() -> void:\n\tpass\n")
    assert effets.fonctions_publiques(script) == (
        "## Le coup.\n## Deux lignes.\nfunc flasher(d: float) -> void:\n\tprint(d)\n\n\tprint(2)")


def test_la_fiche_recopie_le_code_verifie_et_la_mesure(tmp_path):
    exemple = tmp_path / "essai" / "exemple"
    exemple.mkdir(parents=True)
    (exemple / "essai.gdshader").write_text("shader_type spatial;\nuniform float flash = 0.0;\n", encoding="utf-8")
    (exemple / "exemple.gd").write_text("extends Node\n\n\n## Régler.\nfunc regler() -> void:\n\tpass\n",
                                        encoding="utf-8")
    entree = {"titre": "Essai", "fait": "Fait.", "quand": "Quand.", "pieges": ["Piège (mesuré)."]}
    texte = effets.fiche("essai", entree, "centre blanc", dossier=tmp_path)
    assert "```glsl\nshader_type spatial;\nuniform float flash = 0.0;\n```" in texte
    assert "```gdscript\n## Régler.\nfunc regler() -> void:\n\tpass\n```" in texte
    assert "`exemple/exemple.gd` : centre blanc." in texte
    assert "- Piège (mesuré)." in texte


def test_un_commentaire_de_documentation_dans_un_bloc_de_code_n_est_pas_un_titre():
    texte = "# Fiche\n\n## Le piloter\n\n```gdscript\n## La force suit la santé.\nfunc f() -> void:\n\tpass\n```\n\n## Pièges\n- a\n"
    morceaux = nos_sources.sections(texte)
    assert [m.partition("\n")[0] for m in morceaux[1:]] == ["Le piloter", "Pièges"]
    assert "## La force suit la santé." in morceaux[1]


def test_les_fiches_d_effets_sont_indexees_sans_doublon_de_code():
    fr, compte = nos_sources.fragments_effets()
    assert compte["effets"] >= 6 and compte["shaders"] >= 6
    assert any(f.genre == "effet" and f.titre.startswith("effet Flash d'impact") for f in fr)
    assert any(f.genre == "exemple" and f.source == "rag/effets/flash_impact/exemple/flash.gdshader" for f in fr)
    assert any(f.genre == "exemple" and f.source.startswith("rag/effets/flash_impact/exemple/exemple.gd") for f in fr)
    assert not any(f.genre == "effet" and "› Le shader" in f.titre for f in fr)
