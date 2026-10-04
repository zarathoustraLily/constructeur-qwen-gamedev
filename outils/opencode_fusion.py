"""Ajoute l'usine au opencode.json d'un projet Godot, sans toucher au reste.

    python outils/opencode_fusion.py <dossier du projet> [--proxy] [--fournisseur <id>] [--retirer]

Ce que fait la fusion, dans `<projet>/opencode.json` seulement (la config globale n'est jamais
écrite : un script de l'utilisateur la régénère) :
- `mcp.usine-godot` : serveur MCP local lancé par OpenCode
  (`python <dépôt>/mcp_serveur/serveur.py --projet <projet>`) ;
- `skills.paths` : ajoute `<dépôt>/skills` (les chemins déjà présents sont gardés) ;
- avec --proxy : surcharge `provider.<id>.options.baseURL` vers le proxy de capture
  (http://127.0.0.1:<[capture].port_proxy>/v1). OpenCode fusionne la config du projet par-dessus
  la config globale (la dernière source gagne) : seul ce projet passe par le proxy, le reste
  de la définition du fournisseur (modèles, clé) vient toujours de la config globale.
  L'id du fournisseur est celui de la config globale dont la baseURL vise llama-server
  (`[llm].url`) ; --fournisseur l'impose si la détection échoue ou hésite.
- --retirer : enlève ces trois entrées (et elles seules).

`godot-ai` et toute autre entrée restent intacts. Avant toute écriture, l'ancien fichier est
copié en `opencode.json.sauvegarde-<horodatage>`. Le fichier est réécrit en JSON indenté :
un `opencode.json` avec commentaires (JSONC) est refusé plutôt que de perdre les commentaires.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import tempfile
import time
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

RACINE = Path(__file__).resolve().parent.parent
if str(RACINE) not in sys.path:
    sys.path.insert(0, str(RACINE))

from usine import config as cfg  # noqa: E402

NOM_MCP = "usine-godot"
DELAI_MCP_MS = 120000


class ErreurFusion(RuntimeError):
    pass


def lire_json(chemin: Path) -> dict[str, Any]:
    if not chemin.is_file():
        return {}
    texte = chemin.read_text(encoding="utf-8-sig")
    if not texte.strip():
        return {}
    try:
        donnees = json.loads(texte)
    except json.JSONDecodeError as exc:
        raise ErreurFusion(f"{chemin} n'est pas du JSON strict ({exc}) ; commentaires (JSONC) ? "
                           "Le corriger ou ajouter les entrées à la main (voir VERIFIER_EN_LOCAL.md).") from exc
    if not isinstance(donnees, dict):
        raise ErreurFusion(f"{chemin} : objet JSON attendu")
    return donnees


def lire_jsonc(chemin: Path) -> dict[str, Any]:
    """Lecture tolérante (config globale, jamais réécrite) : commentaires // et /* */, virgules finales."""
    if not chemin.is_file():
        return {}
    texte = chemin.read_text(encoding="utf-8-sig")
    sortie, i, dans_chaine = [], 0, False
    while i < len(texte):
        c = texte[i]
        if dans_chaine:
            sortie.append(c)
            if c == "\\":
                sortie.append(texte[i + 1:i + 2])
                i += 1
            elif c == '"':
                dans_chaine = False
        elif c == '"':
            dans_chaine = True
            sortie.append(c)
        elif texte.startswith("//", i):
            while i < len(texte) and texte[i] != "\n":
                i += 1
            continue
        elif texte.startswith("/*", i):
            fin = texte.find("*/", i + 2)
            i = len(texte) if fin < 0 else fin + 2
            continue
        else:
            sortie.append(c)
        i += 1
    propre = re.sub(r",(\s*[}\]])", r"\1", "".join(sortie))
    try:
        return json.loads(propre) if propre.strip() else {}
    except json.JSONDecodeError:
        return {}


def commande_mcp(projet: Path, python: str | None = None) -> list[str]:
    return [python or sys.executable, str(RACINE / "mcp_serveur" / "serveur.py"), "--projet", str(projet)]


def configs_globales(config: dict[str, Any]) -> list[Path]:
    valeur = config.get("opencode", {}).get("config_globale") or "~/.config/opencode/opencode.json"
    base = Path(valeur).expanduser()
    return [base, base.with_suffix(".jsonc")]


def _meme_serveur(url_a: str, url_b: str) -> bool:
    a, b = urlsplit(url_a), urlsplit(url_b)
    hotes_locaux = {"127.0.0.1", "localhost", "::1"}
    meme_hote = a.hostname == b.hostname or {a.hostname, b.hostname} <= hotes_locaux
    return meme_hote and (a.port or 80) == (b.port or 80)


def detecter_fournisseur(globales: list[Path], url_llm: str) -> list[str]:
    """Ids des fournisseurs de la config globale dont la baseURL vise llama-server."""
    ids: list[str] = []
    for chemin in globales:
        for ident, fournisseur in (lire_jsonc(chemin).get("provider") or {}).items():
            url = ((fournisseur or {}).get("options") or {}).get("baseURL") or ""
            if url and _meme_serveur(url, url_llm) and ident not in ids:
                ids.append(ident)
    return ids


def fusionner(donnees: dict[str, Any], projet: Path, proxy_url: str | None = None,
              fournisseur: str | None = None, python: str | None = None) -> dict[str, Any]:
    """Renvoie une copie de `donnees` avec les entrées de l'usine (le reste est inchangé)."""
    d = json.loads(json.dumps(donnees))
    d.setdefault("$schema", "https://opencode.ai/config.json")
    mcp = d.setdefault("mcp", {})
    if not isinstance(mcp, dict):
        raise ErreurFusion("« mcp » n'est pas un objet")
    mcp[NOM_MCP] = {"type": "local", "enabled": True, "command": commande_mcp(projet, python), "timeout": DELAI_MCP_MS}
    skills = d.setdefault("skills", {})
    if not isinstance(skills, dict):
        raise ErreurFusion("« skills » n'est pas un objet")
    chemins = skills.setdefault("paths", [])
    dossier = str(RACINE / "skills")
    if dossier not in chemins:
        chemins.append(dossier)
    if proxy_url:
        if not fournisseur:
            raise ErreurFusion("fournisseur inconnu pour la surcharge du proxy (--fournisseur <id>)")
        p = d.setdefault("provider", {}).setdefault(fournisseur, {})
        p.setdefault("options", {})["baseURL"] = proxy_url
    return d


def retirer(donnees: dict[str, Any], proxy_url: str | None = None) -> dict[str, Any]:
    d = json.loads(json.dumps(donnees))
    (d.get("mcp") or {}).pop(NOM_MCP, None)
    if not d.get("mcp"):
        d.pop("mcp", None)
    chemins = (d.get("skills") or {}).get("paths") or []
    if str(RACINE / "skills") in chemins:
        chemins.remove(str(RACINE / "skills"))
    if d.get("skills") == {"paths": []}:
        d.pop("skills")
    for ident, f in list((d.get("provider") or {}).items()):
        options = (f or {}).get("options") or {}
        if proxy_url and options.get("baseURL") == proxy_url:
            options.pop("baseURL")
            if not options:
                f.pop("options")
            if not f:
                d["provider"].pop(ident)
    if d.get("provider") == {}:
        d.pop("provider")
    return d


def ecrire(chemin: Path, donnees: dict[str, Any]) -> Path | None:
    """Sauvegarde l'ancien fichier, puis écrit le nouveau atomiquement. Renvoie la sauvegarde."""
    sauvegarde = None
    if chemin.is_file():
        sauvegarde = chemin.with_name(f"{chemin.name}.sauvegarde-{time.strftime('%Y%m%d-%H%M%S')}")
        shutil.copy2(chemin, sauvegarde)
    fd, tmp = tempfile.mkstemp(prefix=".opencode.", dir=chemin.parent)
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(donnees, ensure_ascii=False, indent=2) + "\n")
    os.replace(tmp, chemin)
    return sauvegarde


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="opencode_fusion.py")
    parser.add_argument("projet", type=Path)
    parser.add_argument("--proxy", action="store_true", help="faire passer ce projet par le proxy de capture")
    parser.add_argument("--fournisseur", help="id du fournisseur OpenCode à surcharger (sinon : détecté)")
    parser.add_argument("--retirer", action="store_true")
    parser.add_argument("--python", help="interpréteur Python du serveur MCP (défaut : celui-ci)")
    args = parser.parse_args(argv)

    config = cfg.charger_config()
    projet = args.projet.resolve()
    if not (projet / "project.godot").is_file():
        print(f"pas de project.godot dans {projet}", file=sys.stderr)
        return 2
    port = int(config.get("capture", {}).get("port_proxy", 8090))
    proxy_url = f"http://127.0.0.1:{port}/v1"
    cible = projet / "opencode.json"
    try:
        actuel = lire_json(cible)
        if args.retirer:
            nouveau = retirer(actuel, proxy_url)
        else:
            fournisseur = args.fournisseur
            if args.proxy and not fournisseur:
                url_llm = config.get("llm", {}).get("url", "http://127.0.0.1:8080/v1")
                trouves = detecter_fournisseur(configs_globales(config), url_llm)
                if len(trouves) != 1:
                    raise ErreurFusion(f"fournisseur visant {url_llm} dans la config globale : "
                                       f"{trouves or 'aucun'} ; préciser --fournisseur <id>")
                fournisseur = trouves[0]
            nouveau = fusionner(actuel, projet, proxy_url if args.proxy else None, fournisseur, args.python)
    except ErreurFusion as exc:
        print(f"Refus : {exc}", file=sys.stderr)
        return 1
    if nouveau == actuel:
        print(f"{cible} : déjà à jour, rien à écrire.")
        return 0
    sauvegarde = ecrire(cible, nouveau)
    print(f"{cible} : écrit." + (f" Sauvegarde : {sauvegarde.name}" if sauvegarde else ""))
    print(json.dumps({k: nouveau.get(k) for k in ("mcp", "skills", "provider") if k in nouveau},
                     ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
