"""RAG : lecture du rst, index FTS5 (exact d'abord), exemples vérifiés, exclusion des gelés."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from usine.portillon.dedoublonnage import fragments_texte
from usine.portillon.exclusion import Exclusion
from usine.rag import index as rag
from usine.rag.exemples import fragments_script, projets, verifier_projet
from usine.rag.rst import fragments_classe, fragments_guide, nettoyer

CLASSE_RST = """:github_url: hide

.. _class_CharacterBody2D:

CharacterBody2D
===============

**Inherits:** :ref:`PhysicsBody2D<class_PhysicsBody2D>` **<** :ref:`Node<class_Node>`

A 2D physics body specialized for characters moved by script.

.. rst-class:: classref-introduction-group

Description
-----------

Use :ref:`move_and_slide()<class_CharacterBody2D_method_move_and_slide>` to move.

Methods
-------

.. table::

   +------+------+
   | bool | x    |
   +------+------+

.. rst-class:: classref-descriptions-group

Method Descriptions
-------------------

.. _class_CharacterBody2D_method_move_and_slide:

.. rst-class:: classref-method

:ref:`bool<class_bool>` **move_and_slide**\\ (\\ ) :ref:`🔗<class_CharacterBody2D_method_move_and_slide>`

Moves the body based on velocity.

.. rst-class:: classref-item-separator

----

.. _class_CharacterBody2D_method_is_on_floor:

.. rst-class:: classref-method

:ref:`bool<class_bool>` **is_on_floor**\\ (\\ ) |const|

Returns true if the body collided with the floor.
"""

GUIDE_RST = """.. _doc_using:

Using CharacterBody2D
=====================

Introduction
------------

A character body is moved by code with ``move_and_slide()``.

.. tabs::
 .. code-tab:: gdscript GDScript

    extends CharacterBody2D
    func _physics_process(delta):
        move_and_slide()

 .. code-tab:: csharp

    public partial class Joueur : CharacterBody2D {}

.. image:: img/x.png
"""

SCRIPT_DEMO = """extends CharacterBody2D
## Joueur de la démo.

signal saute

const VITESSE = 300.0


## Déplacement.
func _physics_process(delta: float) -> void:
\tvelocity.x = Input.get_axis("ui_left", "ui_right") * VITESSE
\tmove_and_slide()


func sauter() -> void:
\tvelocity.y = -400.0
\tsaute.emit()
"""

SECRET = """func reponse_secrete_du_gel() -> int:
\tvar total_des_points_de_vie_restants := points_de_vie_actuels - degats_recus_pendant_le_dash
\treturn clampi(total_des_points_de_vie_restants, 0, points_de_vie_maximum_du_heros)
"""


def test_nettoyer_retire_le_balisage():
    texte = nettoyer([":ref:`Vector2 <class_Vector2>` et ``delta`` **gras** :doc:`page <../x>`",
                      ".. rst-class:: x", "Fin."])
    assert texte == "Vector2 et delta gras page\nFin."


def test_fragments_classe():
    fr = fragments_classe("classes/class_characterbody2d.rst", CLASSE_RST.splitlines())
    vue = fr[0]
    assert (vue.titre, vue.genre, vue.classe) == ("CharacterBody2D", "classe", "CharacterBody2D")
    assert vue.texte.startswith("Inherits: PhysicsBody2D < Node")
    assert "move_and_slide() to move" in vue.texte and "+------" not in vue.texte
    membres = {f.membre: f for f in fr if f.genre == "membre"}
    assert set(membres) == {"move_and_slide", "is_on_floor"}
    assert membres["move_and_slide"].texte.startswith("méthode de CharacterBody2D\nbool move_and_slide()")
    assert "🔗" not in membres["move_and_slide"].texte


def test_fragments_guide_garde_le_gdscript_et_retire_le_csharp():
    fr = fragments_guide("tutorials/using.rst", GUIDE_RST.splitlines())
    assert [f.titre for f in fr] == ["Using CharacterBody2D › Introduction"]
    assert "move_and_slide()" in fr[0].texte and "extends CharacterBody2D" in fr[0].texte
    assert "public partial class" not in fr[0].texte and "img/x.png" not in fr[0].texte


def test_fragments_script_demo():
    fr = fragments_script("2d/joueur", "res://joueur.gd", SCRIPT_DEMO)
    assert [f.titre for f in fr] == ["2d/joueur › joueur.gd", "2d/joueur › joueur.gd › _physics_process",
                                     "2d/joueur › joueur.gd › sauter"]
    assert all(f.genre == "exemple" and f.classe == "CharacterBody2D" for f in fr)
    assert fr[1].texte.splitlines()[1] == "## Déplacement."  # la doc ## suit la fonction
    assert fr[0].source == "demos/2d/joueur/joueur.gd"


def _docs_et_demos(tmp: Path) -> tuple[Path, Path, dict]:
    docs = tmp / "godot-docs"
    (docs / "classes").mkdir(parents=True)
    (docs / "tutorials" / "physics").mkdir(parents=True)
    (docs / "classes" / "class_characterbody2d.rst").write_text(CLASSE_RST, encoding="utf-8")
    (docs / "tutorials" / "physics" / "using.rst").write_text(GUIDE_RST, encoding="utf-8")
    demos = tmp / "demos"
    for projet, fichiers in {"2d/joueur": {"joueur.gd": SCRIPT_DEMO, "casse.gd": "func (:\n"},
                             "3d/camion": {"camion.gd": "extends VehicleBody3D\n\n" + SECRET}}.items():
        (demos / projet).mkdir(parents=True)
        for nom, texte in fichiers.items():
            (demos / projet / nom).write_text(texte, encoding="utf-8")
    verification = {"revision": "abc", "projets": {
        "2d/joueur": {"scripts": {"res://joueur.gd": True, "res://casse.gd": False}},
        "3d/camion": {"scripts": {"res://camion.gd": True}}}}
    return docs, demos, verification


def _exclusion() -> Exclusion:
    return Exclusion({"competences": {"K2": {"taches": [
        {"id": "k2_secret", "empreinte": "e", "fragments": sorted(fragments_texte(SECRET))}]}}})


def test_index_exact_d_abord_et_exemples(tmp_path):
    docs, demos, verification = _docs_et_demos(tmp_path)
    base = tmp_path / "idx.sqlite"
    r = rag.construire(docs, base, donnees=tmp_path / "donnees", exclusion=Exclusion(None),
                       demos=demos, verification=verification)
    assert r["demos"] == {"projets": 2, "scripts_verifies": 2, "scripts_ecartes": 1}
    idx = rag.IndexDocs(base)
    res = idx.chercher("CharacterBody2D", 5)
    assert (res[0]["titre"], res[0]["trouve_par"]) == ("CharacterBody2D", "exact")
    assert any(x["genre"] == "exemple" for x in res)  # des places pour le code vérifié
    assert idx.chercher("characterbody2d", 1)[0]["titre"] == "CharacterBody2D"
    assert idx.chercher("CharacterBody2D.is_on_floor", 1)[0]["titre"] == "CharacterBody2D.is_on_floor"
    assert idx.chercher("CharacterBody2D is_on_floor", 1)[0]["titre"] == "CharacterBody2D.is_on_floor"
    assert idx.chercher("is_on_floor", 1, "doc")[0]["membre"] == "is_on_floor"
    ex = idx.chercher("move_and_slide", 5, "exemples")
    assert ex and all(x["genre"] == "exemple" for x in ex)
    assert all(x["genre"] != "exemple" for x in idx.chercher("move_and_slide", 5, "doc"))
    assert not any("casse.gd" in x["source"] for x in idx.chercher("func", 10, "exemples"))
    assert "[exemple vérifié" in rag.formater(ex)
    with pytest.raises(ValueError):
        idx.chercher("x", 1, "web")
    idx.fermer()


def test_index_exclut_les_solutions_gelees_et_les_projets_retires(tmp_path):
    docs, demos, verification = _docs_et_demos(tmp_path)
    base = tmp_path / "idx.sqlite"
    r = rag.construire(docs, base, donnees=tmp_path / "donnees", exclusion=_exclusion(),
                       demos=demos, verification=verification)
    assert [(s, t) for s, t, _ in r["exclus"]] == [("demos/3d/camion/camion.gd", "3d/camion › camion.gd › reponse_secrete_du_gel")]
    idx = rag.IndexDocs(base)
    assert idx.verifier_exclusion(_exclusion(), tmp_path / "donnees")["fuites"] == []
    idx.fermer()
    # Index construit sans exclusion : la vérification trouve la fuite.
    rag.construire(docs, base, donnees=tmp_path / "donnees", exclusion=Exclusion(None),
                   demos=demos, verification=verification)
    idx = rag.IndexDocs(base)
    fuites = idx.verifier_exclusion(_exclusion(), tmp_path / "donnees")["fuites"]
    assert [f["tache_id"] for f in fuites] == ["k2_secret"]
    idx.fermer()
    # Projet entier retiré (démo devenue source de tâches gelées).
    r = rag.construire(docs, base, donnees=tmp_path / "donnees", exclusion=Exclusion(None),
                       demos=demos, verification=verification, demos_exclues=["3d/camion"])
    assert r["demos"]["projets"] == 1
    idx = rag.IndexDocs(base)
    assert not any("camion" in x["source"] for x in idx.chercher("VehicleBody3D", 10))
    assert json.loads(idx.meta["demos_exclues"]) == ["3d/camion"]
    idx.fermer()


def test_projets_retenus(tmp_path):
    for p in ("2d/a", "mono/b", "misc/os_test", "mobile/android_iap", "plugins"):
        (tmp_path / p).mkdir(parents=True)
        (tmp_path / p / "project.godot").write_text("", encoding="utf-8")
    assert projets(tmp_path) == ["2d/a", "plugins"]


@pytest.mark.godot
def test_verifier_projet_compile_les_scripts(tmp_path):
    projet = tmp_path / "demo"
    projet.mkdir()
    (projet / "project.godot").write_text('config_version=5\n\n[application]\n\nconfig/name="demo"\n', encoding="utf-8")
    (projet / "bon.gd").write_text(SCRIPT_DEMO, encoding="utf-8")
    (projet / "faux.gd").write_text("extends Node\n\nfunc f() -> void:\n\tvar x: int = \"texte\"\n", encoding="utf-8")
    r = verifier_projet(projet)
    assert r["scripts"] == {"res://bon.gd": True, "res://faux.gd": False}
