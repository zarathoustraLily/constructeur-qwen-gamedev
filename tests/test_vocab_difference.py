"""Différences d'API entre deux versions de Godot (usine/vocab/difference.py)."""

from usine.vocab.difference import comparer


def _api(version, classes, builtins=(), fonctions=(), singletons=()):
    return {"header": {"version_full_name": version}, "classes": list(classes), "builtin_classes": list(builtins),
            "utility_functions": list(fonctions), "global_enums": [], "singletons": list(singletons)}


def _methode(nom, args=(), retour=None, **drapeaux):
    m = {"name": nom, "arguments": [dict(a) for a in args], **drapeaux}
    if retour:
        m["return_value"] = {"type": retour}
    return m


ANCIEN = _api("4.7.2", [
    {"name": "Node3D", "inherits": "Node", "api_type": "core",
     "methods": [_methode("look_at", [{"name": "target", "type": "Vector3"}]),
                 _methode("old_thing")],
     "properties": [{"name": "mesh", "type": "Mesh"}, {"name": "speed", "type": "float"}],
     "enums": [{"name": "Flag", "values": [{"name": "FLAG_A", "value": 0}, {"name": "FLAG_MAX", "value": 1}]}]},
])
NOUVEAU = _api("4.8", [
    {"name": "Node3D", "inherits": "Node", "api_type": "core",
     "methods": [_methode("look_at", [{"name": "target", "type": "Vector3"},
                                      {"name": "up", "type": "Vector3", "default_value": "Vector3(0, 1, 0)"}]),
                 _methode("new_thing", retour="int")],
     "properties": [{"name": "mesh", "type": "BoxMesh,SphereMesh"}, {"name": "speed", "type": "int"}],
     "enums": [{"name": "Flag", "values": [{"name": "FLAG_A", "value": 0}, {"name": "FLAG_B", "value": 1},
                                           {"name": "FLAG_MAX", "value": 2}]}]},
    {"name": "Trail3D", "inherits": "Node3D", "api_type": "core", "methods": []},
    {"name": "EditorThing", "inherits": "Object", "api_type": "editor", "methods": []},
], singletons=[{"name": "TextureStreaming"}])


def test_les_differences_sont_classees():
    r = comparer(ANCIEN, NOUVEAU)
    par = {(d["nature"], d["genre"], d["lieu"], d["nom"]): d for d in r["differences"]}
    assert ("retrait", "methode", "Node3D", "old_thing") in par
    assert ("ajout", "methode", "Node3D", "new_thing") in par
    assert ("ajout", "classe", "Trail3D", "Trail3D") in par
    assert par[("ajout", "classe", "EditorThing", "EditorThing")]["editeur"]
    assert ("ajout", "singleton", "TextureStreaming", "TextureStreaming") in par
    assert ("ajout", "valeur", "Node3D", "Flag.FLAG_B") in par


def test_ce_qui_ne_change_rien_pour_gdscript_est_ecarte():
    r = comparer(ANCIEN, NOUVEAU)
    par = {(d["genre"], d["nom"]): d for d in r["differences"]}
    assert par[("valeur", "Flag.FLAG_MAX")]["hors_gdscript"] == "sentinelle"
    assert par[("propriete", "mesh")]["hors_gdscript"] == "indication"
    assert par[("propriete", "speed")]["hors_gdscript"] == ""  # float devenu int : un vrai changement
    assert r["resume"]["compatibles"] == 1  # look_at gagne un argument facultatif
    assert r["resume"]["editeur"] == 1
