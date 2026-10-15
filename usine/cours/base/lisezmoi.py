"""Écrit le LISEZMOI.md de la livraison à partir des contrôles (chiffres tirés de controles.json)."""

from __future__ import annotations

from pathlib import Path

from usine.cours.base.creation import LIMITE_JETONS, MARGE
from usine.cours.base.godot import IMAGE_RENDU


def nb(x: int) -> str:
    """Nombre à la française : espace fine insécable entre les milliers."""
    return f"{x:,}".replace(",", " ")


def aucun(n: int, un: str, plusieurs: str, zero: str = "aucun") -> str:
    return f"{zero} {un}" if n == 0 else f"{n} {un if n == 1 else plusieurs}"


def pc(x: float) -> str:
    return f"{round(100 * x)} %"


def virgule(x: float) -> str:
    return f"{x:.2f}".replace(".", ",")


def un_chiffre(x: float) -> str:
    return f"{x:.1f}".replace(".", ",").removesuffix(",0")


NOMS_GENRES = {
    "godot3_nom": "nom de Godot 3 (méthode ou classe : `rand_range`, `set_shader_param`, `Transform`, `Spatial`…)",
    "godot3_annotation": "`export` ou `onready` sans `@` (faute de syntaxe)",
    "godot3_shader": "nom de Godot 3 dans un shader (`hint_color`, `WORLD_MATRIX`, `INV_CAMERA_MATRIX`…)",
    "shader_litteral": "entier là où un shader attend un `float`",
    "type": "`int` qui reçoit un `float` (conversion avec perte)",
    "appel": "appel à une fonction du script qui n'existe pas (faute de nom)",
    "non_type": "variable sans type (avertissement `UNTYPED_DECLARATION` traité en erreur)",
}
NOMS_VUES = {"analyse": "à l'analyse du script", "rendu": "au rendu des shaders", "test": "à l'exécution du test",
             "recherche": "par la recherche finale (`grep`)"}


def texte(c: dict) -> str:
    st = c["statistiques"]
    j = st["jetons"]
    jt = j["par_type"]
    se = st["sessions"]
    cr = st["creations"]
    roc = st["editions_opencode_rejouees"]
    eq = st["equilibre_par_etape"]
    ap = st["appels_d_outils"]
    repartition = ", ".join(f"{v} à {k} erreur{'s' if int(k) > 1 else ''}" for k, v in se["par_nombre_d_erreurs"].items())
    part_deb = 1 - j["part_creation_reponses"]
    crea_nb = st["par_type"].get("creation", 0)
    parties = cr["etapes_en_plusieurs_parties"]
    appels = ", ".join(f"`{k}` {nb(v)}" for k, v in ap.items())
    t = f"""# Base d'entraînement : bâtiments procéduraux sous Godot 4.7.2, au format d'OpenCode

Une série de prompts d'entraînement, avec leurs réponses, pour apprendre à Qwen 3.8 à créer des bâtiments
procéduraux sous Godot 4.7.2 et à déboguer ce qu'il écrit, **dans OpenCode, son harnais d'usage** (décision 14 de
laurent). Chaque exemple montre le cheminement : lire le code, chercher, coder, tester, vérifier, corriger, puis un
compte rendu, avec les outils d'OpenCode. Produite par `python -m usine.cours.base` à partir du cours
`cours/batiments_proceduraux/` du dépôt.

## Contenu

- **{nb(st['total'])} exemples** : {crea_nb} de création ({aucun(parties, "étape découpée", "étapes découpées", "aucune")} en
  parties qui se compilent chacune) et {nb(se['nombre'])} sessions de débogage, où {nb(se['erreurs'])} erreurs sont
  corrigées en tout.
- **3 villes, 13 étapes chacune** : Paris (immeuble haussmannien), Tokyo (petit immeuble sur parcelle étroite),
  New York (tour de bureaux, quartier d'affaires).
- **Moitié création, moitié débogage, sur ce que le modèle apprend** : l'entraînement ne porte que sur les réponses,
  et dans les réponses la création pèse {pc(j['part_creation_reponses'])} des jetons, le débogage {pc(part_deb)}
  ({nb(jt['creation']['reponses'])} et {nb(jt['debogage']['reponses'])} jetons). L'équilibre est fait étape par étape :
  selon l'étape, le débogage pèse de {virgule(eq['plus_bas'][0][0])} à {virgule(eq['plus_haut'][-1][0])} fois la création
  (médiane {virgule(eq['median'])}).
- **Appels d'outils** : {appels}.
- **Taille, en jetons de Qwen 3.8, gabarit de chat compris** : {nb(j['total'])} en tout, dont {nb(j['prompt_et_outils'])} par
  exemple pour le prompt système d'OpenCode et la définition de ses outils. Le plus long exemple en compte {nb(j['max'])}
  (`{j['plus_long']}`), soit {nb(j['marge_plus_long'])} de moins que les 32 768 de l'entraînement : aucun exemple n'est
  tronqué.
  - création : {nb(jt['creation']['moyenne'])} jetons en moyenne, de {nb(jt['creation']['min'])} à {nb(jt['creation']['max'])} ;
  - sessions de débogage : {nb(jt['debogage']['moyenne'])} jetons en moyenne, de {nb(jt['debogage']['min'])} à {nb(jt['debogage']['max'])}.
- **Comment les jetons sont comptés** : avec le tokenizer de Qwen 3.8 ({j['tokenizer']}) et le gabarit de chat de son
  GGUF (version d'Unsloth), tous deux lus dans le GGUF du modèle de laurent ; les jetons spéciaux (`<|im_start|>`,
  `<think>`, `<tool_call>`, `<tool_response>`…) comptent pour un jeton chacun. Le bloc de réflexion vide que le gabarit
  met devant chaque réponse compte dans le total, pas dans les jetons de réponse : avec `enable_thinking: false`, il
  est dans le prompt.

## Le format d'OpenCode

Tout vient des sessions réelles de laurent avec OpenCode 2.0.6 (session capturée par le proxy de l'usine, base
`opencode.db`) ; rien n'est imaginé.

- **Prompt système** : celui d'OpenCode, entier (catalogue Code Mode et skills compris). Seules changent les lignes
  d'environnement : dossier de travail (le projet de l'étape, dans `D:\\GODOT\\projet_enseingement\\001_Batiments
  proceduraux\\`) et identifiant de session.
- **Outils** : les 12 d'OpenCode, définitions comprises. Les exemples en emploient cinq : `read` (lire par plages),
  `edit` (remplacer un passage unique), `write` (créer un fichier), `shell` (lancer Godot), `grep` (chercher).
- **Godot** est lancé par son chemin complet, comme le dit `D:\\GODOT\\AGENTS.md`. La commande montrée est celle qui a
  tourné, arguments compris ; seul le préfixe propre à la machine qui a produit la base (`xvfb-run` et un rendu
  logiciel, faute d'écran) n'y figure pas. Le rendu enregistre son image dans `{IMAGE_RENDU}` puis quitte (`--shot`,
  après `++`) ; `--quit-after` borne le lancement.
- **Retours d'outils**, aux formes relevées : `shell` rend la sortie puis « Command exited with code N. » ; `read`
  rend « Read file …, lines a-b », les lignes numérotées « n: … », et « [Output truncated. Continue reading with
  offset: n] » s'il reste des lignes ; `edit` rend « Edited … (1 replacement) » ; `write` rend « Created file
  successfully: … » ; `grep` rend « No matches found ».
- **Les sorties de Godot sont entières** (décision 13 de laurent : ne pas raccourcir les résultats d'outils) : rien
  n'est résumé, les piles d'appels sont complètes. En sont seulement retirés, comme le permet la règle 5.1 : les codes
  de couleur, la progression de l'import, l'avertissement V-Sync de l'écran virtuel, celui du cache de shaders à
  reconstruire et la ligne du pilote graphique. Une sortie qu'OpenCode n'aurait rendue qu'en aperçu (plus de 50 ko)
  écarte l'exemple.
- **Le texte des réponses est gardé** devant chaque appel d'outil (section 3 des règles qui priment) : un message
  assistant porte son texte, puis ses appels.

### Création ({crea_nb} exemples)

- **Demande** : ce qu'on doit obtenir et pouvoir essayer, et la liste des fichiers du projet. Pas d'extrait de code :
  la réponse lit elle-même le code, par plages (`read`), là où l'étape intervient. Jamais la solution.
- **Réponse** : le but et les fichiers, la lecture du code ; puis **Chercher** (chaque classe et chaque membre Godot
  employés, avec leur signature exacte et la phrase de la référence officielle ; des passages de la documentation de
  Godot ; les sources de métier quand l'étape en dépend) et **Coder** (ce qu'on fait, point par point), puis chaque
  changement par un appel `edit` ou `write`, un par message.
- **Tester** : une commande par message, lancée par `shell` : l'import du projet, l'analyse de chaque script modifié
  (avertissements traités en erreurs), le test de l'étape, une image en Compatibilité quand un shader change. Chaque
  réponse lit la sortie précédente avant de lancer la suivante.
- **Dernier message** : **Vérifier** (ce que confirme chaque ligne du test et le rendu, et une liste de contrôle à
  faire dans l'éditeur pour ce que le test ne voit pas), **Corriger** et le **compte rendu**.
- Un exemple de création compte {un_chiffre(cr['tours_moyens'])} messages en moyenne, {cr['tours_max']} au plus.

### Débogage ({nb(se['nombre'])} sessions)

- **Demande** : « j'ai modifié tels fichiers ; vérifie que tout passe et corrige ce qui ne va pas ». Qwen lance
  lui-même les commandes, dans l'ordre : analyse des scripts, rendu si un shader a changé, test de l'étape.
- **Chaque correction** : lire les erreurs, lire le code autour des lignes signalées (`read`), chercher la cause avec
  une preuve (API 4.7.2, documentation, table des renommages du moteur), corriger ligne par ligne (`edit`), relancer
  la même commande. Une session compte {un_chiffre(se['tours_moyens'])} messages en moyenne, {se['tours_max']} au plus.
- **Les vagues de Godot**, telles qu'il les montre vraiment :
  - une faute de syntaxe (`export` sans `@`) cache le reste de l'analyse du script : les autres erreurs ne se
    montrent qu'une fois celle-ci corrigée ({se['sessions_avec_vague_de_syntaxe']} sessions) ;
  - l'analyse montre ensuite toutes les erreurs du script d'un coup ;
  - un shader ne se compile qu'au rendu, et il s'arrête à sa première erreur : il faut relancer pour voir la suivante ;
  - certaines erreurs n'apparaissent qu'à l'exécution du test, qui finit pourtant avec le code 0
    ({se['sessions_avec_erreur_d_execution']} sessions) : la réponse apprend à lire chaque ligne au lieu de se fier au code de sortie ;
  - quand le shader contient des `#include`, Godot 4.7.2 affiche le code autour de la flèche `E` décalé d'une ligne
    par `#include` placé au-dessus de l'erreur, alors que la ligne « at: » est juste : la réponse le relève et se fie
    à « at: » ({se['decalages_shader_verifies']} cas, chacun confronté au nombre de `#include` du fichier) ;
  - à la fin, une recherche (`grep`) des mêmes fautes dans tout le projet, pour les lignes que le test n'exécute pas.
- **Nombre d'erreurs par session** : {repartition}. Chaque étape commence par une session à une erreur, d'une sorte
  qui tourne d'une étape à l'autre.
- **Les erreurs**, de sept sortes :
""" + "\n".join(f"  - {NOMS_GENRES[k]} : {nb(v)}" for k, v in se["genres"].items()) + """
- **Où Godot les voit** : """ + ", ".join(f"{NOMS_VUES[k]} ({nb(v)})" for k, v in se["vues"].items()) + f""".
- La faute n'apparaît dans une réponse que comme le texte à remplacer (`oldString` d'un appel `edit`).

## Fichiers

| Fichier | Contenu |
| --- | --- |
| `base_batiments_proceduraux.jsonl` | Format chat d'OpenAI, comme OpenCode l'envoie : une ligne par exemple, `messages` (system, user, assistant avec ses `tool_calls`, tool avec son `tool_call_id`) et `tools` (les 12 définitions d'OpenCode), plus `tache_id`, `competence` (K2 création, K3 débogage), `sujet`, `type`, `ville`, `etape`. Les arguments des appels sont des objets : le gabarit de Qwen 3.8 refuse une chaîne JSON. Pour Unsloth ou tout entraîneur qui applique le gabarit (`enable_thinking=False`). |
| `base_batiments_proceduraux_sharegpt.jsonl` | Pour LLaMA-Factory : `system` (définitions des outils puis prompt d'OpenCode, tels que le gabarit les écrit), `conversations` en `human` / `gpt`. Les appels d'outils sont écrits dans la réponse `gpt` (`<tool_call>…`), les retours dans le tour `human` qui suit (`<tool_response>…`) : un tour `function_call` de LLaMA-Factory perdrait le texte qui précède l'appel. Le texte obtenu est, jeton pour jeton, celui du gabarit (contrôlé pour chaque exemple). |
| `dataset_info.json` | Déclaration du jeu pour LLaMA-Factory (`dataset: base_batiments_proceduraux`), sans colonne `tools`. |
| `echantillon.md` | {len(st['echantillon'])} exemples en version lisible, tels que le modèle les voit. |
| `controles.json` | Les chiffres ci-dessus et la liste des problèmes trouvés par les contrôles ({len(c['problemes'])}). |

**Réglages d'entraînement à reprendre** : `template: qwen3_8` (comme pour t1), `enable_thinking: false` (règle 7.6),
`cutoff_len: 32768`, `train_on_prompt: false` (la perte ne porte que sur les réponses), `mask_history: false` (valeur
par défaut : la perte porte sur chaque réponse, pas seulement la dernière), `packing: false`.

## Comment chaque exemple a été produit

- **Les états du projet** viennent des 39 projets fabriqués à partir du cours : l'état de départ est le projet de
  l'étape précédente, l'état d'arrivée celui de l'étape. Les bandeaux « NOUVEAU » du cours sont retirés. L'outillage
  du cours (visite, caméra et ses entrées, bandeau, réglages de la visite) est donné comme déjà présent ; les outils
  communs (outil de maillage, fonctions de shader partagées) sont écrits dans les exemples de Paris et donnés comme
  présents pour Tokyo et New York. Chaque projet suit le plan d'organisation et passe le juge des règles sans écart.
- **Une étape trop longue pour un exemple** est découpée en parties qui se compilent chacune : les changements sont
  rangés pour qu'une déclaration arrive avant ses emplois (et ce qui ne peut être séparé reste ensemble : une locale
  refaite plus bas, une signature et ses appels, un `#include` et les déclarations qu'il remplace), puis chaque partie
  prend autant de changements qu'elle peut sous 32 768 jetons moins une marge de
  {nb(32768 - LIMITE_JETONS + MARGE)}, d'après une estimation faite avec les sorties de Godot de l'état final. Godot
  tourne ensuite pour de vrai sur chaque partie : celle qui ne se compile pas rejoint la suivante. Chaque partie redit
  le prompt d'OpenCode : le moins de parties possible.
- **Les sessions** : des erreurs sont posées dans le code juste de l'étape (un script, et souvent un shader), puis
  Godot est lancé pour de vrai à chaque tour, sur le projet tel que la session l'a laissé. Une session n'est gardée que
  si Godot (ou la recherche finale) a montré chacune de ses erreurs, et si le projet revient exactement au code de
  l'étape. Les sessions s'ajoutent, étape par étape, tant que leurs jetons de réponse restent en dessous de ceux des
  exemples de création de l'étape de plus d'une demi-session : une session de plus éloignerait alors de l'équilibre.
- **Toutes les sorties citées sont réelles** : Godot 4.7.2 a été lancé pour chacune (import, analyse, test, rendu), et
  `grep` aussi.
- **Les appels `edit` et `write` ont été rejoués** comme OpenCode les applique (passage unique exigé) : les parties de
  création de chacune des {roc['etapes']} étapes, l'une après l'autre, redonnent son code, et chacune des
  {nb(roc['sessions'])} sessions redonne le code juste ({aucun(roc['differences'], 'différence', 'différences', 'aucune')}, lignes vides comprises).
  Chaque passage remplacé a été lu par la réponse (`read`) avant d'être cité.
- **Les preuves citées sont relues dans leur source** :
  - signatures : `extension_api.json` produit par le binaire 4.7.2 ;
  - descriptions : référence des classes du dépôt de Godot, étiquette `4.7.2-stable` ;
  - documentation : dépôt `godot-docs` ;
  - renommages : `editor/project_upgrade/renames_map_3_to_4.cpp` du moteur 4.7.2 ;
  - sources de métier : les notes du cours et ses carnets de recherche (`cours/batiments_proceduraux/recherches/`).

## Limites

- Les sorties de Godot viennent d'une machine Linux : chez laurent, sous Windows et dans PowerShell, les lignes
  finissent par CRLF et la progression de l'import (retirée ici) est en français ; le reste est le même moteur, la
  même version.
- Les explications de « Coder » reprennent le texte des notes du cours.
- Dans une étape découpée, chaque partie annonce les points de la note dont elle fait les changements. Le
  rattachement d'un changement à un point est calculé (lignes des extraits de la note, noms cités, fichier nommé
  dans le titre du point) : il peut se tromper de point, et une partie annoncer un point qu'elle ne fait qu'en partie.
- Les exemples de création finissent {'tous' if cr['rien_a_corriger'] == crea_nb else 'presque tous'} sur « rien à corriger » : les corrections sont dans les sessions de débogage.
- Les erreurs des sessions sont posées par programme et ne sont que de sept sortes : syntaxe, nom, type et appel. Elles
  se répètent d'une session à l'autre, sur d'autres lignes et dans d'autres fichiers. Il n'y a pas d'erreur de logique
  métier (une règle de zonage mal appliquée, par exemple).
- La recherche finale ne trouve {'jamais rien' if se['trouvees_par_la_recherche'] == 0 else 'que rarement quelque chose'} dans cette base : les sessions où Godot ne voyait pas une
  erreur ont été écartées. Le modèle n'y voit donc pas de cas où elle rattrape une faute.
- La liste de contrôle « dans l'éditeur » décrit ce que la demande attend ; aucune machine ne l'a vérifiée.
- Une image n'est rendue que quand un shader change, une seule fois par exemple de création, et l'image n'est pas
  dans l'exemple (texte seul) : le modèle y apprend la commande et la lecture de sa sortie, pas le jugement visuel.
  Les captures multiples par phase (décision 4 de laurent) et le jugement visuel (décision 7) restent à couvrir
  ailleurs.
- Le fichier `D:\\GODOT\\AGENTS.md` (plan à cocher, lecture par plages) n'était pas dans le prompt de la session
  capturée : OpenCode ne l'avait pas chargé. Les exemples n'ont donc pas de `plan.md`.
"""
    return t


def ecrire(controles: dict, chemin: Path) -> Path:
    chemin = Path(chemin)
    chemin.write_text(texte(controles), encoding="utf-8", newline="\n")
    return chemin
