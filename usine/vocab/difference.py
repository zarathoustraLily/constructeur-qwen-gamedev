"""Différences d'API entre deux versions de Godot, lues dans leurs `extension_api.json`.

Décision 19.7 : la part Godot 4.8 des données porte seulement sur ses différences avec 4.7.2. Cette comparaison les
compte et les liste : classes, méthodes (signature : types des arguments et du retour, statique, constante, nombre
variable d'arguments), propriétés, signaux, énumérations et constantes, des classes du moteur comme des types
intégrés (Vector3, Array…), fonctions globales, énumérations globales et singletons.

Une différence est classée :
- « retrait » : présent dans l'ancienne version, absent de la nouvelle (le code ancien ne compile plus) ;
- « changement » : même nom, signature ou type différents ;
- « ajout » : nouveau dans la nouvelle version.
Les classes de l'éditeur (`api_type` = « editor ») sont comptées à part : elles ne concernent que les plugins. Les
méthodes virtuelles (`is_virtual`) sont marquées : on les redéfinit, on ne les appelle pas. Ce qui ne change rien
pour GDScript (valeurs `…_MAX`, indications de type de l'inspecteur, signatures à pointeurs) est écarté du compte
(`hors_gdscript`), et un changement qui n'ajoute que des arguments facultatifs est dit compatible.

    python -m usine.vocab difference ancien.json nouveau.json [--sortie rapport.json]
"""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Any


def _sig_methode(m: dict[str, Any]) -> tuple:
    retour = (m.get("return_value") or {}).get("type") or m.get("return_type")
    args = tuple((a.get("type"), a.get("default_value")) for a in m.get("arguments", []))
    return (retour, args, m.get("is_static", False), m.get("is_const", False), m.get("is_vararg", False))


def _texte_sig(nom: str, m: dict[str, Any]) -> str:
    args = ", ".join(f"{a['name']}: {a.get('type')}" + (f" = {a['default_value']}" if "default_value" in a else "")
                     for a in m.get("arguments", []))
    retour = (m.get("return_value") or {}).get("type") or m.get("return_type")
    prefixe = "static " if m.get("is_static") else ""
    return f"{prefixe}{nom}({args})" + (f" -> {retour}" if retour else "")


def _par_nom(liste: list[dict[str, Any]] | None) -> dict[str, dict[str, Any]]:
    return {e["name"]: e for e in liste or []}


def _comparer_enums(ancien: list | None, nouveau: list | None, lieu: str, ajout) -> None:
    a, n = _par_nom(ancien), _par_nom(nouveau)
    for nom in sorted(a.keys() - n.keys()):
        ajout("retrait", "enum", lieu, nom, f"enum {nom}")
    for nom in sorted(n.keys() - a.keys()):
        ajout("ajout", "enum", lieu, nom, f"enum {nom}")
    for nom in sorted(a.keys() & n.keys()):
        va = {v["name"]: v["value"] for v in a[nom].get("values", [])}
        vn = {v["name"]: v["value"] for v in n[nom].get("values", [])}
        for v in sorted(va.keys() - vn.keys()):
            ajout("retrait", "valeur", lieu, f"{nom}.{v}", f"{nom}.{v} = {va[v]}")
        for v in sorted(vn.keys() - va.keys()):
            ajout("ajout", "valeur", lieu, f"{nom}.{v}", f"{nom}.{v} = {vn[v]}")
        for v in sorted(va.keys() & vn.keys()):
            if va[v] != vn[v]:
                ajout("changement", "valeur", lieu, f"{nom}.{v}", f"{nom}.{v} : {va[v]} → {vn[v]}")


def _comparer_membres(a: dict[str, Any], n: dict[str, Any], lieu: str, ajout, editeur: bool = False) -> None:
    ma, mn = _par_nom(a.get("methods")), _par_nom(n.get("methods"))
    for nom in sorted(ma.keys() - mn.keys()):
        ajout("retrait", "methode", lieu, nom, _texte_sig(nom, ma[nom]), editeur, ma[nom].get("is_virtual", False))
    for nom in sorted(mn.keys() - ma.keys()):
        ajout("ajout", "methode", lieu, nom, _texte_sig(nom, mn[nom]), editeur, mn[nom].get("is_virtual", False))
    for nom in sorted(ma.keys() & mn.keys()):
        if _sig_methode(ma[nom]) != _sig_methode(mn[nom]):
            ajout("changement", "methode", lieu, nom, f"{_texte_sig(nom, ma[nom])} → {_texte_sig(nom, mn[nom])}",
                  editeur, mn[nom].get("is_virtual", False), _ajoute_facultatifs(ma[nom], mn[nom]))
    for cle, genre in (("properties", "propriete"), ("members", "propriete")):
        pa, pn = _par_nom(a.get(cle)), _par_nom(n.get(cle))
        for nom in sorted(pa.keys() - pn.keys()):
            ajout("retrait", genre, lieu, nom, f"{nom}: {pa[nom].get('type')}", editeur)
        for nom in sorted(pn.keys() - pa.keys()):
            ajout("ajout", genre, lieu, nom, f"{nom}: {pn[nom].get('type')}", editeur)
        for nom in sorted(pa.keys() & pn.keys()):
            if pa[nom].get("type") != pn[nom].get("type"):
                ajout("changement", genre, lieu, nom, f"{nom}: {pa[nom].get('type')} → {pn[nom].get('type')}", editeur)
    sa, sn = _par_nom(a.get("signals")), _par_nom(n.get("signals"))
    for nom in sorted(sa.keys() - sn.keys()):
        ajout("retrait", "signal", lieu, nom, f"signal {nom}", editeur)
    for nom in sorted(sn.keys() - sa.keys()):
        ajout("ajout", "signal", lieu, nom, f"signal {nom}", editeur)
    for nom in sorted(sa.keys() & sn.keys()):
        ta = [x.get("type") for x in sa[nom].get("arguments", [])]
        tn = [x.get("type") for x in sn[nom].get("arguments", [])]
        if ta != tn:
            ajout("changement", "signal", lieu, nom, f"signal {nom}({', '.join(map(str, ta))}) → ({', '.join(map(str, tn))})",
                  editeur)
    ca, cn = _par_nom(a.get("constants")), _par_nom(n.get("constants"))
    for nom in sorted(ca.keys() - cn.keys()):
        ajout("retrait", "constante", lieu, nom, f"const {nom}", editeur)
    for nom in sorted(cn.keys() - ca.keys()):
        ajout("ajout", "constante", lieu, nom, f"const {nom}", editeur)
    _comparer_enums(a.get("enums"), n.get("enums"), lieu, lambda *x: ajout(*x, editeur))


def _hors_gdscript(d: dict[str, Any]) -> str:
    """Pourquoi une différence ne change rien pour un script GDScript ("" si elle compte).

    - « sentinelle » : la valeur `…_MAX` d'une énumération, qui compte ses valeurs ;
    - « indication » : le type d'une propriété de ressource écrit comme la liste de ses classes possibles (une
      indication pour l'inspecteur ; le type GDScript reste le même) ;
    - « natif » : une signature à pointeurs (`void*`, `AudioFrame*`), qui ne concerne que les extensions C++.
    """
    if d["genre"] == "valeur" and d["nom"].endswith("_MAX"):
        return "sentinelle"
    if d["genre"] == "propriete" and d["nature"] == "changement":
        avant, _, apres = d["detail"].partition(": ")[2].partition(" → ")
        if "," in apres or "," in avant:
            return "indication"
    if d["genre"] == "methode" and "*" in d["detail"]:
        return "natif"
    return ""


def _compatible(d: dict[str, Any]) -> bool:
    """Un changement de signature qui n'ajoute que des arguments facultatifs à la fin : l'ancien appel reste juste."""
    return bool(d.get("compatible"))


def _ajoute_facultatifs(a: dict[str, Any], n: dict[str, Any]) -> bool:
    """La nouvelle signature garde l'ancienne (retour, drapeaux, arguments) et n'ajoute que des arguments à défaut."""
    sa, sn = _sig_methode(a), _sig_methode(n)
    if sa[0] != sn[0] or sa[2:] != sn[2:] or len(sn[1]) < len(sa[1]) or sn[1][:len(sa[1])] != sa[1]:
        return False
    return all("default_value" in arg for arg in n.get("arguments", [])[len(sa[1]):])


def comparer(ancien: dict[str, Any], nouveau: dict[str, Any]) -> dict[str, Any]:
    differences: list[dict[str, Any]] = []

    def ajout(nature: str, genre: str, lieu: str, nom: str, detail: str, editeur: bool = False,
              virtuelle: bool = False, compatible: bool = False) -> None:
        differences.append({"nature": nature, "genre": genre, "lieu": lieu, "nom": nom, "detail": detail,
                            "editeur": editeur, "virtuelle": virtuelle, "compatible": compatible})

    ca, cn = _par_nom(ancien["classes"]), _par_nom(nouveau["classes"])
    for nom in sorted(ca.keys() - cn.keys()):
        ajout("retrait", "classe", nom, nom, f"class {nom}", ca[nom].get("api_type") == "editor")
    for nom in sorted(cn.keys() - ca.keys()):
        ajout("ajout", "classe", nom, nom, f"class {nom} extends {cn[nom].get('inherits')}",
              cn[nom].get("api_type") == "editor")
    for nom in sorted(ca.keys() & cn.keys()):
        if ca[nom].get("inherits") != cn[nom].get("inherits"):
            ajout("changement", "heritage", nom, nom, f"{nom} : extends {ca[nom].get('inherits')} → "
                  f"{cn[nom].get('inherits')}", cn[nom].get("api_type") == "editor")
        _comparer_membres(ca[nom], cn[nom], nom, ajout, cn[nom].get("api_type") == "editor")
    ba, bn = _par_nom(ancien["builtin_classes"]), _par_nom(nouveau["builtin_classes"])
    for nom in sorted(ba.keys() - bn.keys()):
        ajout("retrait", "classe", nom, nom, f"type {nom}")
    for nom in sorted(bn.keys() - ba.keys()):
        ajout("ajout", "classe", nom, nom, f"type {nom}")
    for nom in sorted(ba.keys() & bn.keys()):
        _comparer_membres(ba[nom], bn[nom], nom, ajout)
    fa, fn = _par_nom(ancien["utility_functions"]), _par_nom(nouveau["utility_functions"])
    for nom in sorted(fa.keys() - fn.keys()):
        ajout("retrait", "fonction", "@GlobalScope", nom, _texte_sig(nom, fa[nom]))
    for nom in sorted(fn.keys() - fa.keys()):
        ajout("ajout", "fonction", "@GlobalScope", nom, _texte_sig(nom, fn[nom]))
    for nom in sorted(fa.keys() & fn.keys()):
        if _sig_methode(fa[nom]) != _sig_methode(fn[nom]):
            ajout("changement", "fonction", "@GlobalScope", nom, f"{_texte_sig(nom, fa[nom])} → {_texte_sig(nom, fn[nom])}",
                  compatible=_ajoute_facultatifs(fa[nom], fn[nom]))
    _comparer_enums(ancien.get("global_enums"), nouveau.get("global_enums"), "@GlobalScope", ajout)
    sa = {s["name"] for s in ancien.get("singletons", [])}
    sn = {s["name"] for s in nouveau.get("singletons", [])}
    for nom in sorted(sa - sn):
        ajout("retrait", "singleton", nom, nom, f"singleton {nom}")
    for nom in sorted(sn - sa):
        ajout("ajout", "singleton", nom, nom, f"singleton {nom}")

    for d in differences:
        d["hors_gdscript"] = _hors_gdscript(d)
    jeu = [d for d in differences if not d["editeur"] and not d["hors_gdscript"]]
    resume = {
        "versions": [ancien["header"]["version_full_name"], nouveau["header"]["version_full_name"]],
        "total": len(differences),
        "jeu": len(jeu),
        "editeur": sum(d["editeur"] for d in differences),
        "hors_gdscript": dict(Counter(d["hors_gdscript"] for d in differences if d["hors_gdscript"])),
        "compatibles": sum(d["nature"] == "changement" and _compatible(d) for d in jeu),
        "par_nature": dict(Counter(d["nature"] for d in jeu)),
        "par_genre": dict(Counter(f"{d['nature']} {d['genre']}" for d in jeu)),
        "virtuelles": sum(d["virtuelle"] for d in jeu),
    }
    return {"resume": resume, "differences": differences}


def comparer_fichiers(ancien: Path, nouveau: Path) -> dict[str, Any]:
    lire = lambda p: json.loads(Path(p).read_text(encoding="utf-8"))  # noqa: E731
    return comparer(lire(ancien), lire(nouveau))
