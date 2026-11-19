"""Plomberie de projet (décision 24) : le projet généré et ses fautes, sans Godot."""

import re

from usine.paires import plomberie_fautes as pf, plomberie_projet as pp


def test_chaque_faute_est_un_remplacement_unique_et_reversible():
    for graine in range(1, 60):
        th = pp.theme(graine)
        sain = pp.fichiers(th)
        genres = set()
        for x in pf.fautes(th):
            faux = x.poser(sain)
            assert faux[x.fichier] != sain[x.fichier]
            assert faux[x.fichier].count(x.faux) == 1
            assert faux[x.fichier].replace(x.faux, x.juste, 1) == sain[x.fichier]
            genres.add(x.genre)
        assert len(genres) == len(pf.fautes(th))


def test_le_projet_suit_le_plan_et_les_reglages_stricts():
    th = pp.theme(7)
    f = pp.fichiers(th)
    assert "gdscript/warnings/untyped_declaration=2" in f["project.godot"]
    assert all(not rel.startswith("5_data/") or rel.endswith(".tres") for rel in f)
    for rel, texte in f.items():
        if rel.endswith(".gd") and not rel.startswith("7_tests/"):
            # Aucune déclaration sans type ; aucun chiffre d'équilibrage dans un script (principe 2 du plan).
            assert not re.search(r"^\s*var \w+ = ", texte, re.M), rel
            assert not re.search(r"(max_health|points|enemy_count|spacing)\s*[:=][^=\n]*\b[1-9]\d*\b", texte), rel
    assert f"max_health = {th.vie}" in f[pp.chemins(th)["donnees"]]


def test_l_arbre_et_le_projet_montre_sans_son_bloc_debug():
    th = pp.theme(3)
    f = pp.fichiers(th)
    arbre = pp.arbre(f)
    assert all(rel in arbre for rel in f)
    montre = pp.sans_debug(f["project.godot"])
    assert "[autoload]" in montre and "untyped_declaration" not in montre
