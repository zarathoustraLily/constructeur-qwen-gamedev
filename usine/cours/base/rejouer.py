"""Rejoue les consignes d'édition écrites dans les exemples, comme le ferait un outil d'édition littéral
(chaque passage cité doit être unique dans le fichier), et compare le résultat au projet de l'étape (règle 5.7).

    python -m usine.cours.base.rejouer        (consignes recalculées pour les 39 étapes)
Depuis l'assembleur : rejouer_exemples(exemples, etats, code)   (consignes telles qu'écrites dans la base)
"""
import re

BLOC = re.compile(r"```\w*\n(.*?)\n```", re.S)
DEBUT = "Les changements, fichier par fichier :\n\n"
FIN = "\n\n### 3. Tester"


def blocs(texte):
    return [b.split("\n") for b in BLOC.findall(texte)]


def trouver(lignes, motif):
    n = len(motif)
    return [s for s in range(len(lignes) - n + 1) if lignes[s:s + n] == motif]


def rejouer(fichiers_avant, texte):
    """Applique les consignes ; rend (fichiers, problèmes)."""
    fichiers = {k: (v.split("\n") if isinstance(v, str) else list(v)) for k, v in fichiers_avant.items()}
    problemes = []
    courant = None
    for c in re.split(r"\n(?=Je crée `|Dans `res://|- )", "\n" + texte):
        c = c.strip("\n")
        if not c:
            continue
        m = re.match(r"Je crée `res://([^`]+)` :", c)
        if m:
            fichiers[m.group(1)] = blocs(c)[0]
            courant = None
            continue
        m = re.match(r"Dans `res://([^`]+)` :$", c)
        if m:
            courant = m.group(1)
            continue
        if courant not in fichiers:
            problemes.append(f"consigne hors fichier : {c[:60]}")
            continue
        lignes = fichiers[courant]
        b = blocs(c)
        if c.startswith("- au début du fichier, j'ajoute"):
            fichiers[courant] = b[0] + lignes
        elif c.startswith("- après ces lignes"):
            pos = trouver(lignes, b[0])
            if len(pos) != 1:
                problemes.append(f"{courant} : passage d'ancrage trouvé {len(pos)} fois")
                continue
            i = pos[0] + len(b[0])
            fichiers[courant] = lignes[:i] + b[1] + lignes[i:]
        elif c.startswith("- après la ligne "):
            m = re.match(r"- après la ligne (\d+) \(", c)
            if m:
                i = int(m.group(1))
            else:
                a = re.match(r"- après la ligne `(.*)`, j'ajoute", c).group(1)
                pos = [k for k, l in enumerate(lignes) if l.strip() == a]
                if len(pos) != 1:
                    problemes.append(f"{courant} : ligne d'ancrage `{a}` trouvée {len(pos)} fois")
                    continue
                i = pos[0] + 1
            fichiers[courant] = lignes[:i] + b[0] + lignes[i:]
        elif c.startswith("- je remplace"):
            pos = trouver(lignes, b[0])
            if len(pos) != 1:
                problemes.append(f"{courant} : passage à remplacer trouvé {len(pos)} fois")
                continue
            i = pos[0]
            fichiers[courant] = lignes[:i] + b[1] + lignes[i + len(b[0]):]
        elif c.startswith("- je retire"):
            pos = trouver(lignes, b[0])
            if len(pos) != 1:
                problemes.append(f"{courant} : passage à retirer trouvé {len(pos)} fois")
                continue
            i = pos[0]
            fichiers[courant] = lignes[:i] + lignes[i + len(b[0]):]
        else:
            problemes.append(f"consigne inconnue : {c[:60]}")
    return fichiers, problemes


def plein(lignes):
    """Les lignes non vides : les lignes vides entre deux blocs ne changent pas le code."""
    return [l for l in lignes if l.strip()]


def comparer(obtenu, apres, code):
    return [rel for rel, t in apres.items() if rel.endswith(code) and plein(obtenu.get(rel, [])) != plein(t.split("\n"))]


def consignes(reponse):
    """Le passage « Les changements, fichier par fichier » d'une réponse de création."""
    if DEBUT not in reponse:
        return None
    return reponse.split(DEBUT, 1)[1].split(FIN, 1)[0]


def rejouer_exemples(exemples, etats, code):
    """Pour chaque étape : rejoue les consignes de ses exemples de création, partie après partie, depuis l'état
    de départ, et compare à l'état d'arrivée. `etats(ville, n)` rend (avant, après)."""
    bilan = {"etapes": 0, "consignes_ambigues": 0, "fichiers_differents": 0, "details": []}
    par_etape = {}
    for e in exemples:
        if e["type"] == "creation":
            par_etape.setdefault((e["ville"], e["etape"]), []).append(e)
    for (ville, n), liste in sorted(par_etape.items()):
        avant, apres = etats(ville, n)
        fichiers = dict(avant)
        for e in sorted(liste, key=lambda x: x["partie"][0]):
            texte = consignes(e["messages"][2]["content"])
            if texte is None:
                bilan["details"].append(f"{e['id']} : pas de consignes d'édition")
                continue
            fichiers, problemes = rejouer(fichiers, texte)
            bilan["consignes_ambigues"] += len(problemes)
            bilan["details"] += [f"{e['id']} : {p}" for p in problemes]
        differents = comparer(fichiers, apres, code)
        bilan["fichiers_differents"] += len(differents)
        bilan["details"] += [f"{ville} {n:03d} : {rel} ne correspond pas à l'étape" for rel in differents]
        bilan["etapes"] += 1
    return bilan


if __name__ == "__main__":
    from usine.cours.base import creation, etat, rattacher
    from usine.cours.base import composer
    total = {"etapes": 0, "consignes_ambigues": 0, "fichiers_differents": 0}
    for ville in ("parisien", "tokyoiste", "newyorkais"):
        for n in range(1, 14):
            avant, apres = creation.etats(ville, n)
            tous = rattacher.decouper(etat.morceaux(avant, apres))
            obtenu, problemes = rejouer(avant, composer.editions(avant, apres, tous))
            total["etapes"] += 1
            total["consignes_ambigues"] += len(problemes)
            for p in problemes[:3]:
                print(ville, n, p)
            for rel in comparer(obtenu, apres, etat.CODE):
                total["fichiers_differents"] += 1
                print(ville, n, "différent :", rel)
    print(total)
