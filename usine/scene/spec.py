"""Spec de scène JSON ↔ fichier .tscn, de façon déterministe (format : SPEC_SCENE.md).

    scene_read(texte, chemin)  → spec
    scene_write(spec)          → texte .tscn (mêmes octets pour la même spec)
    valider_spec(spec, verif)  → erreurs (vocabulaire réel, scripts du projet)
    normaliser_tscn(texte)     → forme comparable pour l'aller-retour

Les identifiants sont dérivés, jamais tirés au hasard :
    ext_resource : "<rang>_<h5(chemin de la ressource)>"
    sub_resource : "<Type>_<h5(chemin de la scène :: nom de la ressource interne)>"
    uid de scène : dérivé du chemin de la scène quand la spec n'en donne pas.
"""

from __future__ import annotations

import hashlib
import re
from typing import Any

from usine.scene.texte import (Document, Section, ecrire_valeur, echapper, format_attribut, lire_document,
                               references, remplacer_references, type_cle)

VERSION_SPEC = 1
ALPHABET_H5 = "abcdefghijklmnopqrstuvwxyz0123456789"
CARACTERES_INTERDITS_NOM = set('.:@/"%')
ORDRE_ATTRIBUTS_NOEUD = ["name", "type", "parent", "owner", "index", "unique_id", "node_paths", "groups",
                         "instance_placeholder", "instance"]
TYPES_PAR_EXTENSION = {".gd": "Script", ".tscn": "PackedScene", ".scn": "PackedScene", ".gdshader": "Shader",
                       ".png": "Texture2D", ".jpg": "Texture2D", ".jpeg": "Texture2D", ".webp": "Texture2D",
                       ".svg": "Texture2D", ".wav": "AudioStreamWAV", ".ogg": "AudioStreamOggVorbis",
                       ".mp3": "AudioStreamMP3", ".ttf": "FontFile", ".otf": "FontFile"}


class ErreurSpec(ValueError):
    """Spec de scène incohérente (impossible à écrire)."""


# --------------------------------------------------------------------------- identifiants dérivés

def h5(texte: str) -> str:
    """5 caractères [a-z0-9] dérivés de `texte` (comme les suffixes d'id de Godot, mais stables)."""
    n = int.from_bytes(hashlib.sha256(texte.encode("utf-8")).digest()[:8], "big")
    sortie = []
    for _ in range(5):
        n, r = divmod(n, len(ALPHABET_H5))
        sortie.append(ALPHABET_H5[r])
    return "".join(sortie)


def uid_derive(chemin: str) -> str:
    """uid://… dérivé du chemin (alphabet de ResourceUID::id_to_text : a-y puis 0-8, base 34)."""
    n = int.from_bytes(hashlib.sha256(("uid:" + chemin).encode("utf-8")).digest()[:8], "big") & ((1 << 63) - 1)
    caracteres = []
    while True:
        n, c = divmod(n, 34)
        caracteres.append(chr(ord("a") + c) if c < 25 else chr(ord("0") + c - 25))
        if n == 0:
            break
    return "uid://" + "".join(reversed(caracteres))


def id_externe(rang: int, chemin: str) -> str:
    return f"{rang}_{h5(chemin)}"


def id_interne(type_: str, chemin_scene: str, nom: str) -> str:
    return f"{type_}_{h5(chemin_scene + '::' + nom)}"


def type_par_extension(chemin: str) -> str | None:
    for ext, t in TYPES_PAR_EXTENSION.items():
        if chemin.lower().endswith(ext):
            return t
    return None


def nommer_par_usage(noeuds: list[tuple[str, list[tuple[str, Any]]]],
                     internes: dict[str, list[tuple[str, Any]]]) -> dict[str, str]:
    """Nom stable de chaque ressource interne, d'après son premier usage :
    "<chemin du nœud>:<propriété>" (racine : ".:<propriété>"), "<nom du parent>/<propriété>" si elle
    n'est utilisée que par une autre ressource interne, suffixe "[k]" si une propriété en contient
    plusieurs, "inutilisee_<n>" si rien ne l'utilise.

    noeuds   : [(chemin, [(propriété, valeur)…])…] dans l'ordre du fichier ;
    internes : clé → [(propriété, valeur)…], dans l'ordre du fichier (clé = id ou nom de spec).
    """
    noms: dict[str, str] = {}
    pris: set[str] = set()
    file_attente: list[str] = []

    def nommer(cle: str, nom: str) -> None:
        if cle in noms or cle not in internes:
            return
        base, n = nom, 2
        while nom in pris:
            nom, n = f"{base}~{n}", n + 1
        noms[cle] = nom
        pris.add(nom)
        file_attente.append(cle)

    def depuis(proprietaire: str, sep: str, proprietes: list[tuple[str, Any]]) -> None:
        for prop, valeur in proprietes:
            refs = references(valeur, "SubResource")
            for k, cle in enumerate(refs):
                nommer(cle, f"{proprietaire}{sep}{prop}" + (f"[{k}]" if len(refs) > 1 else ""))

    for chemin, proprietes in noeuds:
        depuis(chemin, ":", proprietes)
    while file_attente:
        cle = file_attente.pop(0)
        depuis(noms[cle], "/", internes[cle])
    for n, cle in enumerate(internes, start=1):
        if cle not in noms:
            nommer(cle, f"inutilisee_{n}")
    return noms


# --------------------------------------------------------------------------- lecture

def _chemin_noeud(section: Section) -> str:
    nom = section.attribut("name")
    parent = section.attribut("parent")
    if parent is None:
        return "."
    return nom if parent == "." else f"{parent}/{nom}"


def scene_read(texte: str, chemin: str | None = None) -> dict[str, Any]:
    """Lit un .tscn et renvoie sa spec (voir SPEC_SCENE.md)."""
    doc = lire_document(texte)
    if not doc.sections or doc.sections[0].balise != "gd_scene":
        raise ErreurSpec("ce n'est pas une scène : [gd_scene] attendu en tête")
    entete = doc.sections[0]
    spec: dict[str, Any] = {"spec": VERSION_SPEC}
    if chemin:
        spec["chemin"] = chemin
    spec["uid"] = entete.attribut("uid")

    # Ressources externes : id → chemin.
    ext_par_id: dict[str, str] = {}
    externes = []
    for s in doc.de_balise("ext_resource"):
        ext_par_id[s.attribut("id")] = s.attribut("path")
        e = {"chemin": s.attribut("path"), "type": s.attribut("type")}
        if s.a_attribut("uid"):
            e["uid"] = s.attribut("uid")
        externes.append(e)
    spec["ressources_externes"] = externes

    def valeur_spec(v: Any) -> Any:
        return remplacer_references(v, "ExtResource", ext_par_id)

    # Ressources internes : nommées d'après leur premier usage.
    subs = {s.attribut("id"): s for s in doc.de_balise("sub_resource")}
    noeuds = doc.de_balise("node")
    noms = nommer_par_usage([(_chemin_noeud(s), [(e.cle, e.valeur) for e in s.proprietes()]) for s in noeuds],
                            {id_: [(e.cle, e.valeur) for e in s.proprietes()] for id_, s in subs.items()})

    def valeur_complete(v: Any) -> Any:
        return remplacer_references(valeur_spec(v), "SubResource", noms)

    spec["ressources_internes"] = [
        {"nom": noms[id_], "type": s.attribut("type"),
         "proprietes": {e.cle: valeur_complete(e.valeur) for e in s.proprietes()}}
        for id_, s in subs.items()
    ]

    # Nœuds : arbre.
    par_chemin: dict[str, dict[str, Any]] = {}
    racine: dict[str, Any] | None = None
    for s in noeuds:
        noeud: dict[str, Any] = {"nom": s.attribut("name")}
        if s.a_attribut("type"):
            noeud["type"] = s.attribut("type")
        instance = s.attribut("instance")
        if isinstance(instance, dict) and "ExtResource" in instance:
            noeud["instance"] = ext_par_id.get(instance["ExtResource"], instance["ExtResource"])
        proprietes = {}
        for e in s.proprietes():
            v = valeur_complete(e.valeur)
            if e.cle == "script" and isinstance(v, dict) and "ExtResource" in v and "script" not in noeud:
                noeud["script"] = v["ExtResource"]
            else:
                proprietes[e.cle] = v
        if proprietes:
            noeud["proprietes"] = proprietes
        if s.a_attribut("groups"):
            noeud["groupes"] = s.attribut("groups")
        for cle, cle_spec in (("unique_id", "unique_id"), ("index", "index"), ("owner", "owner"),
                              ("instance_placeholder", "instance_placeholder"), ("node_paths", "node_paths")):
            if s.a_attribut(cle):
                noeud[cle_spec] = valeur_spec(s.attribut(cle))
        autres = {k: b for k, b in s.attributs if k not in ORDRE_ATTRIBUTS_NOEUD}
        if autres:
            noeud["attributs_bruts"] = autres
        chemin_n = _chemin_noeud(s)
        if chemin_n == ".":
            racine = noeud
        else:
            parent = s.attribut("parent")
            pere = racine if parent == "." else par_chemin.get(parent)
            if pere is None:
                # Parent non déclaré (nœud d'une scène instanciée) : nœuds implicites.
                pere = racine
                cumul = []
                for morceau in parent.split("/"):
                    cumul.append(morceau)
                    c = "/".join(cumul)
                    if c not in par_chemin:
                        implicite = {"nom": morceau, "implicite": True}
                        pere.setdefault("enfants", []).append(implicite)
                        par_chemin[c] = implicite
                    pere = par_chemin[c]
            pere.setdefault("enfants", []).append(noeud)
        par_chemin[chemin_n] = noeud
    if racine is None:
        raise ErreurSpec("scène sans nœud racine")
    spec["racine"] = racine

    connexions = []
    for s in doc.de_balise("connection"):
        c = {"signal": s.attribut("signal"), "source": s.attribut("from"), "cible": s.attribut("to"),
             "methode": s.attribut("method")}
        for cle in ("flags", "unbinds", "binds"):
            if s.a_attribut(cle):
                c[cle] = valeur_complete(s.attribut(cle))
        connexions.append(c)
    if connexions:
        spec["connexions"] = connexions
    editables = [s.attribut("path") for s in doc.de_balise("editable")]
    if editables:
        spec["editables"] = editables
    return spec


# --------------------------------------------------------------------------- parcours

def parcourir(noeud: dict[str, Any], chemin: str = ".", parent: str | None = None):
    """(chemin, chemin du parent, nœud) en ordre préfixe ; la racine a le chemin "."."""
    yield chemin, parent, noeud
    for enfant in noeud.get("enfants", []):
        c = enfant["nom"] if chemin == "." else f"{chemin}/{enfant['nom']}"
        yield from parcourir(enfant, c, chemin)


def _valeurs_spec(spec: dict[str, Any]):
    """Toutes les valeurs de la spec susceptibles de contenir des références, dans l'ordre d'écriture."""
    for _, _, n in parcourir(spec["racine"]):
        if n.get("instance"):
            yield {"ExtResource": n["instance"]}
        yield from n.get("proprietes", {}).values()
        if n.get("script"):
            yield {"ExtResource": n["script"]}
    for r in spec.get("ressources_internes", []):
        yield from r.get("proprietes", {}).values()
    for c in spec.get("connexions", []):
        if "binds" in c:
            yield c["binds"]


# --------------------------------------------------------------------------- écriture

def _trier_internes(internes: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Tri topologique stable : une ressource interne vient après celles qu'elle utilise."""
    par_nom = {r["nom"]: r for r in internes}
    places: list[dict[str, Any]] = []
    vus: set[str] = set()
    en_cours: set[str] = set()

    def placer(r: dict[str, Any]) -> None:
        if r["nom"] in vus:
            return
        if r["nom"] in en_cours:
            raise ErreurSpec(f"cycle entre ressources internes autour de {r['nom']!r}")
        en_cours.add(r["nom"])
        for v in r.get("proprietes", {}).values():
            for dep in references(v, "SubResource"):
                if dep in par_nom:
                    placer(par_nom[dep])
        en_cours.discard(r["nom"])
        vus.add(r["nom"])
        places.append(r)

    for r in internes:
        placer(r)
    return places


def _classer(verif, type_: str | None, nom: str) -> str:
    """'native' (avant le script) ou 'apres' (variables du script, metadata)."""
    if nom.startswith("metadata/"):
        return "apres"
    if not type_:  # nœud instancié ou surcharge : type inconnu ici, ordre de la spec
        return "native"
    existe, _, genre = verif.type_propriete(type_, None, nom)
    return "native" if existe and genre == "native" else "apres"


def _coercer(verif, type_: str | None, nom: str, valeur: Any) -> Any:
    """Un entier pour une propriété native flottante s'écrit 6.0, comme Godot."""
    if verif is None or not type_ or not isinstance(valeur, int) or isinstance(valeur, bool):
        return valeur
    existe, type_decl, genre = verif.type_propriete(type_, None, nom)
    return float(valeur) if existe and genre == "native" and type_decl == "float" else valeur


def scene_write(spec: dict[str, Any], verif=None) -> str:
    """Écrit le .tscn d'une spec. Déterministe : même spec (et même vocabulaire) → mêmes octets.

    verif : un `usine.projet.index.Verificateur` ; par défaut, le vocabulaire seul. Il sert à
    ranger les propriétés natives avant le script (les variables du script après, comme Godot,
    sinon Godot les ignorerait au chargement) et à écrire les flottants natifs avec leur partie
    décimale.
    """
    if "racine" not in spec:
        raise ErreurSpec("spec sans racine")
    if verif is None:
        from usine.projet.index import Verificateur
        from usine.vocab import ouvrir
        verif = Verificateur(ouvrir(), None)
    chemin_scene = spec.get("chemin", "")

    # Propriétés de chaque nœud dans l'ordre d'écriture : natives, script, puis le reste.
    noeuds_ecrits = []
    for chemin, parent, n in parcourir(spec["racine"]):
        if n.get("implicite"):
            continue
        items = list(n.get("proprietes", {}).items())
        natives = [(k, v) for k, v in items if _classer(verif, n.get("type"), k) == "native"]
        autres = [(k, v) for k, v in items if _classer(verif, n.get("type"), k) != "native"]
        script = [("script", {"ExtResource": n["script"]})] if n.get("script") else []
        noeuds_ecrits.append((chemin, parent, n, natives + script + autres))

    # 1. Ressources externes : liste explicite, puis références rencontrées.
    externes: list[dict[str, Any]] = []
    vus: dict[str, dict[str, Any]] = {}
    for e in spec.get("ressources_externes", []):
        if e["chemin"] not in vus:
            vus[e["chemin"]] = dict(e)
            externes.append(vus[e["chemin"]])
    for v in _valeurs_spec(spec):
        for chemin in references(v, "ExtResource"):
            if chemin not in vus:
                vus[chemin] = {"chemin": chemin}
                externes.append(vus[chemin])
    ids_ext: dict[str, str] = {}
    for rang, e in enumerate(externes, start=1):
        if not e.get("type"):
            e["type"] = type_par_extension(e["chemin"])
            if not e["type"]:
                raise ErreurSpec(f"type inconnu pour la ressource externe {e['chemin']!r} : le préciser dans ressources_externes")
        ids_ext[e["chemin"]] = id_externe(rang, e["chemin"])

    # 2. Ressources internes.
    internes = _trier_internes(spec.get("ressources_internes", []))
    if len({r["nom"] for r in internes}) != len(internes):
        raise ErreurSpec("noms de ressources internes en double")
    # L'id dérive du nom d'usage (et non du nom de la spec) : relire puis réécrire redonne les mêmes octets.
    noms_usage = nommer_par_usage([(c, props) for c, _, _, props in noeuds_ecrits],
                                  {r["nom"]: list(r.get("proprietes", {}).items()) for r in internes})
    ids_sub = {r["nom"]: id_interne(r["type"], chemin_scene, noms_usage[r["nom"]]) for r in internes}

    def valeur_fichier(v: Any) -> str:
        for nom in references(v, "SubResource"):
            if nom not in ids_sub:
                raise ErreurSpec(f"ressource interne inconnue : {nom!r}")
        v = remplacer_references(v, "ExtResource", ids_ext)
        return ecrire_valeur(remplacer_references(v, "SubResource", ids_sub))

    morceaux: list[str] = []
    attributs = ["format=3"]
    uid = spec["uid"] if "uid" in spec else (uid_derive(chemin_scene) if chemin_scene else None)
    if uid:
        attributs.append(f"uid={echapper(uid)}")
    morceaux.append("[gd_scene " + " ".join(attributs) + "]\n")

    if externes:
        lignes = []
        for e in externes:
            a = [f"type={echapper(e['type'])}"]
            if e.get("uid"):
                a.append(f"uid={echapper(e['uid'])}")
            a += [f"path={echapper(e['chemin'])}", f"id={echapper(ids_ext[e['chemin']])}"]
            lignes.append("[ext_resource " + " ".join(a) + "]\n")
        morceaux.append("\n" + "".join(lignes))

    for r in internes:
        lignes = [f"[sub_resource type={echapper(r['type'])} id={echapper(ids_sub[r['nom']])}]\n"]
        for cle, v in r.get("proprietes", {}).items():
            lignes.append(f"{cle} = {valeur_fichier(_coercer(verif, r['type'], cle, v))}\n")
        morceaux.append("\n" + "".join(lignes))

    # 3. Nœuds, en ordre préfixe.
    for chemin, parent, n, proprietes in noeuds_ecrits:
        nom = n.get("nom", "")
        attr: dict[str, str] = {"name": echapper(nom)}
        if n.get("type"):
            attr["type"] = echapper(n["type"])
        if parent is not None:
            attr["parent"] = echapper(parent)
        for cle in ("owner", "index", "unique_id", "node_paths"):
            if cle in n:
                attr[cle] = ecrire_valeur(n[cle])
        if n.get("groupes"):
            attr["groups"] = ecrire_valeur(list(n["groupes"]))
        if "instance_placeholder" in n:
            attr["instance_placeholder"] = ecrire_valeur(n["instance_placeholder"])
        if n.get("instance"):
            attr["instance"] = f"ExtResource({echapper(ids_ext[n['instance']])})"
        entete = "[node " + " ".join(f"{k}={attr[k]}" for k in ORDRE_ATTRIBUTS_NOEUD if k in attr)
        for k, brut in n.get("attributs_bruts", {}).items():
            entete += f" {k}={brut}"
        lignes = [entete + "]\n"]
        for cle, v in proprietes:
            lignes.append(f"{cle} = {valeur_fichier(_coercer(verif, n.get('type'), cle, v))}\n")
        morceaux.append("\n" + "".join(lignes))

    if spec.get("connexions"):
        lignes = []
        for c in spec["connexions"]:
            a = [f"signal={echapper(c['signal'])}", f"from={echapper(c['source'])}",
                 f"to={echapper(c['cible'])}", f"method={echapper(c['methode'])}"]
            for cle in ("flags", "unbinds"):
                if cle in c:
                    a.append(f"{cle}={ecrire_valeur(c[cle])}")
            if "binds" in c:
                a.append(format_attribut("binds", valeur_fichier(c["binds"])))
            lignes.append("[connection " + " ".join(a) + "]\n")
        morceaux.append("\n" + "".join(lignes))
    if spec.get("editables"):
        morceaux.append("\n" + "".join(f"[editable path={echapper(p)}]\n" for p in spec["editables"]))
    return "".join(morceaux)


# --------------------------------------------------------------------------- normalisation

def normaliser_tscn(texte: str) -> str:
    """Forme comparable d'un .tscn, indépendante de l'écrivain (règles dans SPEC_SCENE.md) :

    1. l'attribut load_steps de [gd_scene] est retiré (Godot 4.7 ne l'écrit plus) ;
    2. les id de ressources sont renumérotés dans l'ordre du fichier (E1, E2… et S1, S2…),
       et toutes les références ExtResource("…") / SubResource("…") suivent.
    Tout le reste (ordre des sections et des propriétés, valeurs, espaces) doit être identique.
    """
    doc = lire_document(texte)
    table_ext = {s.attribut("id"): f"E{n}" for n, s in enumerate(doc.de_balise("ext_resource"), start=1)}
    table_sub = {s.attribut("id"): f"S{n}" for n, s in enumerate(doc.de_balise("sub_resource"), start=1)}

    def renommer(brut: str) -> str:
        brut = re.sub(r'ExtResource\("([^"]*)"\)', lambda m: f'ExtResource("{table_ext.get(m.group(1), m.group(1))}")', brut)
        return re.sub(r'SubResource\("([^"]*)"\)', lambda m: f'SubResource("{table_sub.get(m.group(1), m.group(1))}")', brut)

    for s in doc.sections:
        if s.balise == "gd_scene" and s.a_attribut("load_steps"):
            s.retirer_attribut("load_steps")
        if s.balise == "ext_resource":
            s.definir_attribut("id", table_ext[s.attribut("id")])
        elif s.balise == "sub_resource":
            s.definir_attribut("id", table_sub[s.attribut("id")])
        s.entete_brut = renommer(s.entete_brut)
        for e in s.entrees:
            e.brut = renommer(e.brut)
    return doc.texte()


# --------------------------------------------------------------------------- validation

def _erreur(lieu: str, message: str, categorie: str = "vocab_inconnu") -> dict[str, Any]:
    return {"fichier": lieu, "ligne": None, "categorie": categorie, "message": message}


def valider_spec(spec: dict[str, Any], verif) -> list[dict[str, Any]]:
    """Vérifie une spec contre le vocabulaire réel (et les scripts du projet si verif.projet).

    Renvoie une liste d'erreurs au format du verdict ; vide si la spec est correcte.
    """
    erreurs: list[dict[str, Any]] = []
    projet = verif.projet
    lieu_scene = spec.get("chemin", "spec")
    internes = {r.get("nom"): r for r in spec.get("ressources_internes", [])}
    types_ext = {e["chemin"]: e.get("type") for e in spec.get("ressources_externes", [])}

    def type_ressource(valeur: dict) -> str | None:
        k = type_cle(valeur)
        if k == "SubResource":
            r = internes.get(valeur[k])
            return r.get("type") if r else None
        chemin = valeur[k]
        return types_ext.get(chemin) or (projet.type_ressource(chemin) if projet else type_par_extension(chemin))

    def verifier_valeur(lieu: str, cle: str, type_decl: str | None, v: Any) -> None:
        for chemin in references(v, "ExtResource"):
            if not isinstance(chemin, str) or not chemin.startswith("res://"):
                erreurs.append(_erreur(lieu, f"{cle} : ExtResource attend un chemin res:// ({chemin!r})", "valeur_invalide"))
            elif projet is not None and not projet.existe(chemin):
                erreurs.append(_erreur(lieu, f"{cle} : ressource absente du projet {chemin}", "missing_resource"))
        for nom in references(v, "SubResource"):
            if nom not in internes:
                erreurs.append(_erreur(lieu, f"{cle} : ressource interne inconnue {nom!r}", "valeur_invalide"))
        try:
            ecrire_valeur(v)
        except (ValueError, TypeError) as exc:
            erreurs.append(_erreur(lieu, f"{cle} : valeur non codable ({exc})", "valeur_invalide"))
            return
        message = verif.valeur_compatible(type_decl, v, type_ressource)
        if message:
            erreurs.append(_erreur(lieu, f"{cle} : {message}", "valeur_invalide"))

    def verifier_proprietes(lieu: str, type_: str | None, script: str | None, proprietes: dict[str, Any]) -> None:
        if type_ is None and script is None:
            return
        for cle, v in proprietes.items():
            existe, type_decl, _ = verif.type_propriete(type_, script, cle)
            if not existe:
                quoi = type_ or "?"
                if script:
                    quoi += f" + {script}"
                erreurs.append(_erreur(lieu, f"propriété inconnue {cle!r} pour {quoi}"))
                continue
            verifier_valeur(lieu, cle, type_decl, v)

    for r in spec.get("ressources_internes", []):
        lieu = f"{lieu_scene}::{r.get('nom')}"
        if not r.get("type") or not verif.classe_existe(r["type"]):
            erreurs.append(_erreur(lieu, f"type de ressource inconnu : {r.get('type')!r}"))
            continue
        if not verif.herite_de(r["type"], "Resource"):
            erreurs.append(_erreur(lieu, f"{r['type']} n'est pas une Resource"))
        verifier_proprietes(lieu, r["type"], None, r.get("proprietes", {}))

    for e in spec.get("ressources_externes", []):
        if projet is not None and not projet.existe(e["chemin"]):
            erreurs.append(_erreur(lieu_scene, f"ressource externe absente : {e['chemin']}", "missing_resource"))
        if e.get("type") and not verif.classe_existe(e["type"]):
            erreurs.append(_erreur(lieu_scene, f"type de ressource externe inconnu : {e['type']!r}"))

    infos: dict[str, tuple[str | None, str | None]] = {}
    for chemin, _, n in parcourir(spec["racine"]):
        lieu = f"{lieu_scene}:{chemin}"
        nom = n.get("nom")
        if not isinstance(nom, str) or not nom or set(nom) & CARACTERES_INTERDITS_NOM:
            erreurs.append(_erreur(lieu, f"nom de nœud invalide : {nom!r}", "invalid_node_path"))
        noms_enfants = [e.get("nom") for e in n.get("enfants", [])]
        for doublon in sorted({x for x in noms_enfants if noms_enfants.count(x) > 1}, key=str):
            erreurs.append(_erreur(lieu, f"deux enfants s'appellent {doublon!r}", "invalid_node_path"))
        if n.get("implicite"):
            infos[chemin] = (None, None)
            continue
        type_, script = n.get("type"), n.get("script")
        if type_ and n.get("instance"):
            type_ = type_  # Godot accepte type + instance ; le type reste vérifié.
        if type_ and not verif.classe_existe(type_):
            erreurs.append(_erreur(lieu, f"type de nœud inconnu : {type_!r}"))
            infos[chemin] = (None, None)
            continue
        if type_ and not verif.herite_de(type_, "Node"):
            erreurs.append(_erreur(lieu, f"{type_} n'est pas un Node"))
        instance = n.get("instance")
        if instance:
            if not instance.startswith("res://") or not instance.endswith((".tscn", ".scn")):
                erreurs.append(_erreur(lieu, f"instance : chemin de scène attendu ({instance!r})", "valeur_invalide"))
            elif projet is not None:
                if not projet.existe(instance):
                    erreurs.append(_erreur(lieu, f"scène instanciée absente : {instance}", "missing_resource"))
                else:
                    t_inst, s_inst = projet.racine_scene(instance)
                    type_ = type_ or t_inst
                    script = script or s_inst
        if not type_ and not instance and chemin != ".":
            # Surcharge d'un nœud d'une scène instanciée : type inconnu ici.
            infos[chemin] = (None, script)
            continue
        if not type_ and not instance:
            erreurs.append(_erreur(lieu, "nœud racine sans type ni instance"))
        if n.get("script"):
            sc = n["script"]
            if not sc.startswith("res://") or not sc.endswith(".gd"):
                erreurs.append(_erreur(lieu, f"script : chemin res://….gd attendu ({sc!r})", "valeur_invalide"))
            elif projet is not None:
                if not projet.existe(sc):
                    erreurs.append(_erreur(lieu, f"script absent : {sc}", "missing_resource"))
                else:
                    _, base = projet.chaine_scripts(sc)
                    if base and type_ and verif.classe_existe(base) and not verif.herite_de(type_, base):
                        erreurs.append(_erreur(lieu, f"le script {sc} étend {base}, incompatible avec {type_}", "type_error"))
            elif n.get("proprietes"):
                # Sans projet, les variables du script ne sont pas vérifiables : seules les natives passent.
                script = None
        groupes = n.get("groupes", [])
        if not isinstance(groupes, list) or not all(isinstance(g, str) and g for g in groupes):
            erreurs.append(_erreur(lieu, "groupes : liste de chaînes attendue", "valeur_invalide"))
        verifier_proprietes(lieu, type_, script if projet is not None else None, n.get("proprietes", {}))
        infos[chemin] = (type_, script if projet is not None else None)

    for k, c in enumerate(spec.get("connexions", [])):
        lieu = f"{lieu_scene}:connexion[{k}]"
        manque = [x for x in ("signal", "source", "cible", "methode") if not c.get(x)]
        if manque:
            erreurs.append(_erreur(lieu, f"champs manquants : {', '.join(manque)}", "valeur_invalide"))
            continue
        if c["source"] not in infos:
            erreurs.append(_erreur(lieu, f"source inconnue : {c['source']!r}", "invalid_node_path"))
            continue
        if c["cible"] not in infos:
            erreurs.append(_erreur(lieu, f"cible inconnue : {c['cible']!r}", "invalid_node_path"))
            continue
        t_src, s_src = infos[c["source"]]
        t_cib, s_cib = infos[c["cible"]]
        nb = None
        if t_src or s_src:
            nb = verif.signal_arguments(t_src, s_src, c["signal"])
            if nb is None:
                erreurs.append(_erreur(lieu, f"signal inconnu {c['signal']!r} sur {c['source']} ({t_src})", "signal_missing"))
                continue
        if t_cib or s_cib:
            arite = verif.methode_arite(t_cib, s_cib, c["methode"])
            if arite is None:
                erreurs.append(_erreur(lieu, f"méthode inconnue {c['methode']!r} sur {c['cible']} ({t_cib})"))
                continue
            if nb is not None:
                n_args = nb - int(c.get("unbinds", 0)) + len(c.get("binds", []))
                mini, maxi = arite
                if n_args < mini or (maxi is not None and n_args > maxi):
                    erreurs.append(_erreur(lieu, f"arité : {c['signal']} fournit {n_args} argument(s), "
                                                 f"{c['methode']} en attend {mini}" + (f" à {maxi}" if maxi != mini else ""),
                                           "type_error"))
    for p in spec.get("editables", []):
        if p not in infos:
            erreurs.append(_erreur(lieu_scene, f"editable : nœud inconnu {p!r}", "invalid_node_path"))
    return erreurs


def document_vers_spec(doc: Document, chemin: str | None = None) -> dict[str, Any]:
    return scene_read(doc.texte(), chemin)
