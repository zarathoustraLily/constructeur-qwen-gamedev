"""Famille de paires « écrire une fonction de shader d'après son commentaire » (création ; shaders, étape D1 du
suivi, demande de laurent du 2026-10-28 : « il faut que tu reconstruises cette part »).

Les shaders du cours des bâtiments procéduraux (`.gdshader`, `.gdshaderinc`), étape par étape : une fonction de premier
niveau documentée (lignes `//` juste au-dessus), hors fonctions d'entrée (`vertex`, `fragment`, `light`…), dont le
corps est retiré. Juge : l'image de la visite en Compatibilité (`godot.rendre`, `--shot` ; un shader ne se compile
qu'au rendu, règle 5.4), comparée à celle du cours par `usine/observation/visuel.comparer` (mêmes seuils que le juge
visuel d'O1). Gardée seulement si :
- l'image du cours se rend deux fois identique (rendu déterministe) ;
- au corps vidé (valeur nulle du type de retour), le rendu reste propre (le shader compile) et l'image change de façon
  visible : l'image dépend vraiment de la fonction ;
- avec la fonction d'origine, c'est l'état du cours, dont l'image est la référence.

La demande montre le commentaire et la signature, et ce que la fonction emploie (uniformes, constantes, signatures
des fonctions appelées, `#include` compris) ; la réponse écrit la fonction, puis lance la visite en Compatibilité et
le test de l'étape (sortie non écrite, règle 7.2). Écrire le corps d'une fonction de shader n'engage aucune convention
du plan : palier 1 sans le plan (section 3) quand la paire tient en 1 024 jetons, sinon palier 2 avec le plan.

Rend des images : à lancer quand la carte est libre (pas pendant un entraînement).

    python -m usine.paires shader_fonction [--par-etape N] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from usine.paires import creation as cf
from usine.paires import format as fmt

FAMILLE = "creation_shader"
SHADERS = (".gdshader", ".gdshaderinc")
DOSSIERS = ("6_assets/Shader/Procedural/",)
SIGNATURE = re.compile(r"^(void|float|int|uint|bool|[biu]?vec[234]|mat[234])\s+(\w+)\s*\(([^)]*)\)\s*\{\s*$")
ENTREES = {"vertex", "fragment", "light", "start", "process", "sky", "fog"}
CORPS_MIN, CORPS_MAX = 1, 25
TROU = "\t// À écrire."


@dataclass
class Fonction:
    nom: str
    retour: str
    doc: int        # première ligne `//` du commentaire
    ligne: int      # ligne de la signature
    fin: int        # ligne de l'accolade fermante

    def texte(self, lignes: list[str]) -> str:
        return "\n".join(lignes[self.ligne:self.fin + 1])


def fonctions(texte: str) -> list[Fonction]:
    """Les fonctions de premier niveau d'un shader, avec leur commentaire `//` juste au-dessus (vide s'il n'y en a
    pas : doc == ligne)."""
    lignes = texte.split("\n")
    sortie = []
    for k, l in enumerate(lignes):
        m = SIGNATURE.match(l)
        if not m:
            continue
        profondeur, fin = 0, None
        for j in range(k, len(lignes)):
            code = lignes[j].split("//", 1)[0]
            profondeur += code.count("{") - code.count("}")
            if profondeur == 0:
                fin = j
                break
        if fin is None:
            continue
        doc = k
        # Le commentaire, ses lignes de séparation (« // ---- ») comprises : le fichier les montre ainsi.
        while doc > 0 and lignes[doc - 1].lstrip().startswith("//"):
            doc -= 1
        sortie.append(Fonction(m[2], m[1], doc, k, fin))
    return sortie


def defaut(retour: str) -> str:
    """La valeur nulle d'un type de retour de shader."""
    if retour in ("float", "int"):
        return {"float": "0.0", "int": "0"}[retour]
    if retour == "uint":
        return "0u"
    if retour == "bool":
        return "false"
    if retour.startswith("mat"):
        return f"{retour}(1.0)"
    nul = {"b": "false", "i": "0", "u": "0u"}.get(retour[0], "0.0")
    return f"{retour}({nul})"


def vider(texte: str, f: Fonction) -> str:
    lignes = texte.split("\n")
    corps = [] if f.retour == "void" else [f"\treturn {defaut(f.retour)};"]
    return "\n".join(lignes[:f.ligne + 1] + corps + lignes[f.fin:])


def candidates(texte: str) -> list[Fonction]:
    return [f for f in fonctions(texte) if f.nom not in ENTREES and f.doc < f.ligne
            and CORPS_MIN <= f.fin - f.ligne - 1 <= CORPS_MAX]


def contexte(rel: str, f: Fonction, apres: dict[str, str]) -> str:
    """Ce que la fonction emploie : les uniformes, constantes et `#define` du fichier qu'elle nomme, puis la signature
    et le commentaire des fonctions qu'elle appelle (de ce fichier ou des `.gdshaderinc` du projet), puis son propre
    commentaire et sa signature, corps à écrire."""
    lignes = apres[rel].split("\n")
    corps = "\n".join(l.split("//", 1)[0] for l in lignes[f.ligne + 1:f.fin])
    nomme = lambda nom: re.search(rf"\b{re.escape(nom)}\b", corps) is not None  # noqa: E731
    blocs: list[str] = []
    decl = [l for l in lignes[:f.doc] if (m := re.match(r"^\s*(?:uniform|const|global uniform)\s.*?\b(\w+)\s*(?:[:=;]|$)", l))
            and nomme(m[1])]
    decl += [l for l in lignes[:f.doc] if (m := re.match(r"^#define\s+(\w+)", l)) and nomme(m[1])]
    if decl:
        blocs.append("\n".join(decl))
    for autre_rel in [rel] + sorted(r for r in apres if r.endswith(".gdshaderinc") and r != rel):
        autres = apres[autre_rel].split("\n")
        for g in fonctions(apres[autre_rel]):
            if (autre_rel, g.nom) == (rel, f.nom) or not re.search(rf"\b{re.escape(g.nom)}\s*\(", corps):
                continue
            entete = f"// (de res://{autre_rel})\n" if autre_rel != rel else ""
            blocs.append(entete + "\n".join(autres[g.doc:g.ligne + 1]) + "\n\t…\n}")
    blocs.append("\n".join(lignes[f.doc:f.ligne + 1]) + f"\n{TROU}\n}}")
    return "\n\n".join(blocs) + "\n"


def rendu(projet: Any, png: Path) -> tuple[Any, bool]:
    """L'image de la visite de l'étape, copiée dans `png` ; (sortie, rendu propre et image écrite)."""
    from usine.cours.base import godot, profil
    s = godot.rendre(projet.chemin, png)
    return s, profil.rendu_propre(s.code, s.texte) and godot.image_enregistree(s) is not None and png.is_file()


def paire(projet: Any, rel: str, f: Fonction, reference: Path, dossier: Path, commande_test: str,
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    from usine.observation import visuel
    original = projet.apres[rel]
    png = dossier / f"sans_{f.nom}.png"
    projet.remettre()
    try:
        projet.ecrire(rel, vider(original, f))
        s, ok = rendu(projet, png)
        if not ok:
            return None, "au corps vidé, le rendu n'est pas propre (le shader ne compile plus ?)"
        c = visuel.comparer(reference, png, Path(projet.chemin))
        if not visuel.visible(c):
            return None, "l'image ne change pas sans le corps : rien ne juge cette fonction"
    finally:
        projet.remettre()
    lignes = original.split("\n")
    fonction = f.texte(lignes)
    demande = (f"Projet Godot 4.7.2. Dans `res://{rel}`, écris le corps de `{f.nom}` d'après son commentaire. "
               f"La visite de l'étape le montre ; un shader ne se compile qu'au rendu. Ce que la fonction emploie :\n"
               f"```glsl\n{contexte(rel, f, projet.apres)}```")
    reponse = [f"**Écrire.** `{f.nom}`, d'après son commentaire :", f"```glsl\n{fonction}\n```", "",
               "**Tester.** Un shader ne se compile qu'au rendu : je lance la visite en Compatibilité, puis le test "
               "de l'étape :", f"```\n$ {s.commande}\n$ {commande_test}\n```"]
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": f.nom, "image_reference": True,
              "rendu_propre_sans_corps": True, "image_change_sans_corps": True, "part_changee": c.get("part"),
              "image_identique_avec": True, "commande_rendu": s.commande, "commande_test": commande_test}
    courte = fmt.paire(FAMILLE, sujet, "création", demande, "\n".join(reponse), dict(preuve, palier=1))
    if courte["jetons"] <= cf.PLAFOND_COURT:
        return courte, ""
    longue = fmt.paire(FAMILLE, sujet, "création", demande, "\n".join(reponse), dict(preuve, palier=2),
                       systeme=fmt.plan())
    if longue["jetons"] > cf.PLAFOND:
        return None, f"trop longue ({longue['jetons']} jetons)"
    return longue, ""


def generer(par_etape: int = 30, graine: int = 1, etapes: list[int] | None = None, donnees: Path | None = None,
            journal: Callable[[str], None] = print) -> dict[str, Any]:
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.observation import visuel
    from usine.paires.execution import _sujet
    chemins.configurer(cours="batiments_proceduraux")
    sortie = fmt.dossier(FAMILLE, donnees)
    images = sortie / "images"
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = []
            for rel in sorted(apres):
                if not rel.endswith(SHADERS) or not rel.startswith(DOSSIERS):
                    continue
                lignes = apres[rel].split("\n")
                for f in candidates(apres[rel]):
                    cle = (fmt.commun(rel), fmt.commun(f.texte(lignes)))
                    if cle not in vues:
                        dispo.append((rel, f, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            dossier = images / f"{ville}_{n:03d}"
            if dossier.exists():
                shutil.rmtree(dossier)
            dossier.mkdir(parents=True)
            projet = sessions.Projet(ville, n, apres)
            ref, ref2 = dossier / "reference.png", dossier / "reference_bis.png"
            _, ok = rendu(projet, ref)
            _, ok2 = rendu(projet, ref2)
            if not (ok and ok2) or not visuel.identique(visuel.comparer(ref, ref2, Path(projet.chemin))):
                rejets.append(f"{ville}-{n:03d} : image de référence absente ou non déterministe")
                continue
            t = projet.lancer("test")
            if t.code != 0 or "SCRIPT ERROR" in t.texte:
                rejets.append(f"{ville}-{n:03d} : le test de l'étape ne passe pas")
                continue
            gardees = essais = 0
            for rel, f, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 2:
                    break
                essais += 1
                q, raison = paire(projet, rel, f, ref, dossier, t.commande, _sujet(ville, n, rel))
                if q is None:
                    rejets.append(f"{ville}-{n:03d} {rel} {f.nom} : {raison}")
                    continue
                paires.append(q)
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    fmt.ecrire(paires, sortie / "paires_batiments_proceduraux.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": "batiments_proceduraux", "paires": len(paires),
                             "rejets": rejets, "par_sujet": {}, "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / "bilan_batiments_proceduraux.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False),
                                                             encoding="utf-8")
    return bilan
