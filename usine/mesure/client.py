"""Client minimal de chat : llama-server local (OpenAI-compatible) ou API frontière.

Sans dépendance (urllib). Une requête = un essai ; aucune relance automatique : un appel qui
échoue est un échec de l'essai, noté comme tel (même budget pour toutes les configurations).

llama-server :
  - sortie contrainte par schéma : `response_format = {"type": "json_schema", "json_schema": {...}}` ;
  - LoRA par requête : `lora = [{"id": 0, "scale": 1.0}]`. Un adaptateur chargé au démarrage
    s'applique à son échelle par défaut : la configuration « base » envoie donc explicitement
    l'échelle 0 pour chaque adaptateur déclaré.
Protocole « anthropic » (référence frontière seulement) : API Messages, sans contrainte de schéma
(le JSON est demandé dans le prompt et lu dans la réponse).
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Any


class ErreurAppel(RuntimeError):
    pass


@dataclass
class Reglages:
    """Même budget pour toutes les configurations d'une mesure."""
    url: str = "http://127.0.0.1:8080/v1"
    modele: str = "qwen"
    cle: str | None = None
    protocole: str = "openai"          # openai | anthropic
    max_jetons: int = 4096
    temperature: float = 0.0
    graine: int = 1
    delai_s: float = 600.0
    entetes: dict[str, str] = field(default_factory=dict)


@dataclass
class Reponse:
    contenu: str
    duree_s: float
    jetons_entree: int = 0
    jetons_sortie: int = 0
    fin: str | None = None


def _poster(url: str, corps: dict[str, Any], entetes: dict[str, str], delai_s: float) -> dict[str, Any]:
    requete = urllib.request.Request(url, data=json.dumps(corps).encode("utf-8"), method="POST",
                                     headers={"Content-Type": "application/json", **entetes})
    try:
        with urllib.request.urlopen(requete, timeout=delai_s) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:500]
        raise ErreurAppel(f"HTTP {exc.code} : {detail}") from exc
    except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
        raise ErreurAppel(f"appel impossible : {exc}") from exc


def corps_openai(r: Reglages, messages: list[dict[str, Any]], schema: dict[str, Any] | None,
                 lora: list[dict[str, Any]] | None) -> dict[str, Any]:
    corps: dict[str, Any] = {"model": r.modele, "messages": messages, "max_tokens": r.max_jetons,
                             "temperature": r.temperature, "seed": r.graine, "stream": False}
    if schema is not None:
        corps["response_format"] = {"type": "json_schema",
                                    "json_schema": {"name": "reponse", "schema": schema}}
    if lora is not None:
        corps["lora"] = lora
    return corps


def completer(r: Reglages, messages: list[dict[str, Any]], schema: dict[str, Any] | None = None,
              lora: list[dict[str, Any]] | None = None) -> Reponse:
    """Un appel ; renvoie le texte de l'assistant et l'usage. ErreurAppel en cas d'échec."""
    debut = time.monotonic()
    base = r.url.rstrip("/")
    if r.protocole == "openai":
        entetes = dict(r.entetes)
        if r.cle:
            entetes["Authorization"] = f"Bearer {r.cle}"
        donnees = _poster(f"{base}/chat/completions", corps_openai(r, messages, schema, lora), entetes, r.delai_s)
        try:
            choix = donnees["choices"][0]
            contenu = choix["message"].get("content") or ""
        except (KeyError, IndexError, TypeError) as exc:
            raise ErreurAppel(f"réponse inattendue : {str(donnees)[:300]}") from exc
        usage = donnees.get("usage") or {}
        return Reponse(contenu, round(time.monotonic() - debut, 3), int(usage.get("prompt_tokens", 0)),
                       int(usage.get("completion_tokens", 0)), choix.get("finish_reason"))
    if r.protocole == "anthropic":
        systeme = "\n\n".join(m["content"] for m in messages if m["role"] == "system")
        corps = {"model": r.modele, "max_tokens": r.max_jetons, "temperature": r.temperature,
                 "messages": [m for m in messages if m["role"] != "system"]}
        if systeme:
            corps["system"] = systeme
        entetes = {"x-api-key": r.cle or "", "anthropic-version": "2023-06-01", **r.entetes}
        donnees = _poster(f"{base}/messages", corps, entetes, r.delai_s)
        try:
            contenu = "".join(b.get("text", "") for b in donnees["content"] if b.get("type") == "text")
        except (KeyError, TypeError) as exc:
            raise ErreurAppel(f"réponse inattendue : {str(donnees)[:300]}") from exc
        usage = donnees.get("usage") or {}
        return Reponse(contenu, round(time.monotonic() - debut, 3), int(usage.get("input_tokens", 0)),
                       int(usage.get("output_tokens", 0)), donnees.get("stop_reason"))
    raise ErreurAppel(f"protocole inconnu : {r.protocole}")


def extraire_json(texte: str) -> Any:
    """Le JSON de la réponse : tel quel, sinon le premier objet ou tableau complet du texte
    (bloc ```json``` d'un modèle sans contrainte de schéma). ValueError si rien n'est lisible."""
    texte = texte.strip()
    try:
        return json.loads(texte)
    except json.JSONDecodeError:
        pass
    decodeur = json.JSONDecoder()
    for i, c in enumerate(texte):
        if c in "{[":
            try:
                return decodeur.raw_decode(texte, i)[0]
            except json.JSONDecodeError:
                continue
    raise ValueError("aucun JSON lisible dans la réponse")
