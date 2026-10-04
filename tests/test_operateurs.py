"""Opérateurs de mutation : masquage des chaînes, chaque opérateur, déterminisme."""

from __future__ import annotations

from usine.generateurs.commun import SOURCE_REFERENCE, lire_projet
from usine.generateurs.operateurs import (NOMS_OPERATEURS, OPERATEURS_GD, masque_code, mutants_fichier,
                                          mutants_projet)


def _mutations(nom: str, ligne: str) -> list[str]:
    return list(OPERATEURS_GD[nom](ligne, masque_code(ligne)))


def test_au_moins_dix_operateurs():
    attendus = {"comparaison_inversee", "operateur_arithmetique", "constante_modifiee", "chemin_noeud_casse",
                "connexion_supprimee", "await_retire", "type_exporte", "appel_supprime", "condition_niee",
                "signal_renomme"}
    assert attendus <= set(NOMS_OPERATEURS)
    assert len(NOMS_OPERATEURS) >= 10


def test_chaines_et_commentaires_masques():
    ligne = '\tlabel.text = "a < b + 1" # x > 2'
    code = masque_code(ligne)
    assert len(code) == len(ligne)
    assert "<" not in code and ">" not in code and "1" not in code
    assert _mutations("comparaison_inversee", ligne) == []
    assert _mutations("constante_modifiee", ligne) == []


def test_comparaison_sans_fleche_de_retour():
    assert _mutations("comparaison_inversee", "func f(a: int) -> bool:") == []
    assert _mutations("comparaison_inversee", "\treturn a <= b") == ["\treturn a < b"]
    assert _mutations("comparaison_inversee", "\tif a != b:") == ["\tif a == b:"]


def test_arithmetique_binaire_seulement():
    assert _mutations("operateur_arithmetique", "\tx = -1") == []
    assert _mutations("operateur_arithmetique", "\tx = a - b * c") == ["\tx = a + b * c", "\tx = a - b / c"]
    assert _mutations("operateur_arithmetique", "\tx += 1") == ["\tx -= 1"]


def test_constantes_entieres_et_flottantes():
    assert _mutations("constante_modifiee", "\tx = maxf(y, 0.0) + 2") == ["\tx = maxf(y, 1.0) + 2",
                                                                       "\tx = maxf(y, 0.0) + 3"]
    assert _mutations("constante_modifiee", "\tv = Vector2(x1, 0.5)") == ["\tv = Vector2(x1, 1.0)"]


def test_chemin_type_condition_appel_signal_booleen_await():
    assert _mutations("chemin_noeud_casse", "@onready var h: Node = $Vie/Barre") == ["@onready var h: Node = $Vie/Barre_mut"]
    assert _mutations("type_exporte", "@export var speed: float = 2.0") == ["@export var speed: int = 2.0"]
    assert _mutations("condition_niee", "\telif a > 0:") == ["\telif not (a > 0):"]
    assert _mutations("appel_supprime", "\t\tdied.emit()") == ["\t\tpass"]
    assert _mutations("appel_supprime", "\tvar x := f()") == []
    assert _mutations("appel_supprime", "\tx = f(a == b)") == []
    assert _mutations("signal_renomme", "signal died") == ["signal died_mut"]
    assert _mutations("booleen_inverse", "\treturn true") == ["\treturn false"]
    assert _mutations("await_retire", "\tawait get_tree().process_frame") == ["\tget_tree().process_frame"]
    assert _mutations("connexion_supprimee", "\ta.died.connect(_on_died)") == ["\tpass"]
    assert _mutations("argument_retire", "func f(a: int, b: int) -> void:") == ["func f(a: int) -> void:"]
    assert _mutations("methode_renommee", "func f() -> void:") == ["func f_mut() -> void:"]


def test_scenes_connexion_et_parent():
    texte = ('[node name="A" type="Node2D"]\n\n[node name="B" type="Node" parent="A"]\n\n'
             '[connection signal="ready" from="." to="." method="f"]\n')
    mutants = mutants_fichier("scenes/x.tscn", texte)
    ops = sorted(m.operateur for m in mutants)
    assert ops == ["chemin_noeud_casse", "connexion_supprimee", "signal_renomme"]
    supprime = next(m for m in mutants if m.operateur == "connexion_supprimee")
    assert "[connection" not in supprime.appliquer(texte)


def test_mutant_applique_une_seule_ligne_et_restreint_aux_lignes():
    texte = "func f() -> bool:\n\treturn 1 < 2\n"
    tous = mutants_fichier("a.gd", texte)
    seuls = mutants_fichier("a.gd", texte, lignes={2})
    assert all(m.ligne == 2 for m in seuls) and len(seuls) < len(tous)
    m = next(m for m in seuls if m.operateur == "comparaison_inversee")
    assert m.appliquer(texte) == "func f() -> bool:\n\treturn 1 <= 2\n"


def test_enumeration_deterministe_sur_le_projet_de_reference():
    projet = lire_projet(SOURCE_REFERENCE)
    a = [m.id for m in mutants_projet(projet)]
    b = [m.id for m in mutants_projet(dict(reversed(list(projet.items()))))]
    assert a == b and len(a) > 100
    assert not any(m.startswith("tests/") for m in a)
