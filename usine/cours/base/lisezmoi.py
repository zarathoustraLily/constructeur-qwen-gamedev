"""Écrit le LISEZMOI.md de la livraison à partir des contrôles (chiffres tirés de controles.json)."""

from __future__ import annotations

from pathlib import Path

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
    rej = st["consignes_rejouees"]
    eq = st["equilibre_par_etape"]
    repartition = ", ".join(f"{v} à {k} erreur{'s' if int(k) > 1 else ''}" for k, v in se["par_nombre_d_erreurs"].items())
    part_deb = 1 - j["part_creation_reponses"]
    autre = j.get("total_autre_tokenizer_qwen2")
    if autre is None:
        phrase_autre = "Le second compte (tokenizer de Qwen 1.5 à 3) n'a pas été fait : `[entrainement].vocab_qwen2` absent."
    elif autre == j["total"]:
        phrase_autre = "Les deux donnent exactement le même total sur cette base."
    else:
        phrase_autre = f"Avec celui de Qwen 1.5 à 3, le total est de {nb(autre)}."
    crea_nb = st["par_type"].get("creation", 0)
    parties = cr["etapes_en_plusieurs_parties"]
    t = f"""# Base d'entraînement : bâtiments procéduraux sous Godot 4.7.2

Une série de prompts d'entraînement, avec leurs réponses, pour apprendre à un modèle comme Qwen 3.8 à créer des
bâtiments procéduraux sous Godot 4.7.2, et à déboguer ce qu'il écrit. Chaque exemple montre le cheminement :
chercher, coder, tester, vérifier, corriger, puis un compte rendu. Produite par `python -m usine.cours.base` à partir
du cours `cours/batiments_proceduraux/` du dépôt.

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
- **Taille, en jetons de Qwen, gabarit de chat compris** : {nb(j['total'])} en tout. Le plus long exemple en compte
  {nb(j['max'])} (`{j['plus_long']}`), soit {nb(j['marge_plus_long'])} de moins que les 32 768 de l'entraînement :
  aucun exemple n'est tronqué.
  - création : {nb(jt['creation']['moyenne'])} jetons en moyenne, de {nb(jt['creation']['min'])} à {nb(jt['creation']['max'])} ;
  - sessions de débogage : {nb(jt['debogage']['moyenne'])} jetons en moyenne, de {nb(jt['debogage']['min'])} à {nb(jt['debogage']['max'])}.
- **Comment les jetons sont comptés** : avec le tokenizer de Qwen 3.5, lu dans le fichier de vocabulaire de llama.cpp
  (`models/ggml-vocab-qwen35.gguf`) ; ce compte redonne exactement les jetons de référence de llama.cpp sur ses
  chaînes de test. llama.cpp ne connaît que deux tokenizers Qwen, celui de Qwen 1.5 à 3 et celui de Qwen 3.5, et
  aucun qui soit propre à Qwen 3.6, 3.7 ou 3.8. {phrase_autre} Le bloc de réflexion vide que le gabarit met devant
  chaque réponse compte dans le total, pas dans les jetons de réponse : avec `enable_thinking: false`, il est dans le
  prompt.

### Création ({crea_nb} exemples, en plusieurs tours)

- **Prompt** : la demande de l'étape (ce qu'on doit obtenir et pouvoir essayer), la liste des fichiers du projet et le
  code actuel aux endroits que l'étape touche. Jamais la solution.
- **Premier tour de réponse** :
  1. **Chercher** : chaque classe et chaque membre Godot employés, avec leur signature exacte et la phrase de la
     référence officielle ; des passages de la documentation de Godot ; les sources de métier quand l'étape en dépend
     (zonage de New York, gabarit de Paris, règles de Tokyo…).
  2. **Coder** : ce qu'on fait, point par point, puis les changements fichier par fichier : créer un fichier,
     remplacer un passage exact, ajouter après une ligne, retirer un passage. Chaque passage cité est unique dans le
     fichier au moment où on l'applique (sinon il est élargi aux lignes voisines) : n'importe quel outil d'édition
     peut suivre ces consignes à la lettre.
  3. **Tester** : la réponse lance la première commande, l'import du projet.
- **Puis une commande par tour** : l'analyse de chaque script modifié (avertissements traités en erreurs), le test de
  l'étape, une image en Compatibilité quand un shader change (les shaders ne se compilent qu'au rendu). **La sortie de
  chaque commande arrive dans le tour « user » suivant**, avec son code de sortie ; la réponse la lit, puis lance la
  suivante. Un exemple de création compte {un_chiffre(cr['tours_moyens'])} tours en moyenne, {cr['tours_max']} au plus.
- **Dernier tour** : **Vérifier** (ce que confirme chaque ligne du test, et une liste de contrôle à faire dans
  l'éditeur pour ce que le test ne voit pas), **Corriger** (ce qui reste à reprendre, ou « rien à corriger », selon
  les sorties réelles), et le **compte rendu** : fichiers, commandes lancées et leurs résultats, problèmes restants,
  règles d'architecture concernées (DAT-01, SIM-09, QA-01, COD-02).

### Débogage ({nb(se['nombre'])} sessions, en plusieurs tours)

- **Forme** : une conversation. Le premier tour « user » donne la sortie de Godot, avec son code de sortie, et le code
  autour des lignes signalées. Chaque réponse lit les erreurs, cherche leur cause avec une preuve (API 4.7.2,
  documentation, table des renommages du moteur), corrige, puis demande de relancer la commande ; la sortie réelle
  arrive dans le tour « user » suivant, de la même façon. **La réponse n'écrit jamais une sortie de Godot ou de
  `grep`** : elle apprend à la lire. Une session compte {un_chiffre(se['tours_moyens'])} tours en moyenne, {se['tours_max']} au plus.
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
- La faute n'est jamais écrite comme du code nouveau : la réponse ne la cite que comme le texte à remplacer.

## Fichiers

| Fichier | Contenu |
| --- | --- |
| `base_batiments_proceduraux.jsonl` | Format chat : une ligne par exemple, `messages` (system, puis user et assistant en alternance), plus `tache_id`, `competence` (K2 création, K3 débogage), `sujet`, `type`, `ville`, `etape`. Pour Unsloth (`train_on_responses_only`) ou tout entraîneur au format chat. |
| `base_batiments_proceduraux_sharegpt.jsonl` | Le même contenu au format sharegpt de LLaMA-Factory (`human`, `gpt`, `system`). |
| `dataset_info.json` | Déclaration du jeu pour LLaMA-Factory (`dataset: base_batiments_proceduraux`). |
| `echantillon.md` | {len(st['echantillon'])} exemples en version lisible : deux créations et une session de chaque sorte. |
| `controles.json` | Les chiffres ci-dessus et la liste des problèmes trouvés par les contrôles ({len(c['problemes'])}). |

**Pas encore au format d'OpenCode** : le harnais d'usage est OpenCode (décision 14 de laurent), et ses outils doivent
être ceux des données (règle 7.4). Cette base est neutre : la commande demandée par une réponse et sa sortie dans le
tour suivant jouent le rôle d'un appel d'outil et de son résultat, les éditions sont des consignes en texte. La
conversion en appels d'outils d'OpenCode, texte gardé, se fait à partir de ce qu'OpenCode envoie vraiment (session
enregistrée par le proxy de capture). Comme il n'y a pas de tour `function_call`, l'export sharegpt ne perd aucun texte.

**Réglages d'entraînement à reprendre** : `template: qwen3_8` (comme pour t1), `enable_thinking: false` (règle 7.6),
`cutoff_len: 32768`, `train_on_prompt: false` (la perte ne porte que sur les réponses), `mask_history: false` (valeur
par défaut : la perte porte sur chaque tour de réponse, pas seulement le dernier), `packing: false`.

## Comment chaque exemple a été produit

- **Les états du projet** viennent des 39 projets fabriqués à partir du cours : l'état de départ est le projet de
  l'étape précédente, l'état d'arrivée celui de l'étape. Les bandeaux « NOUVEAU » du cours sont retirés. L'outillage
  du cours (visite, caméra et ses entrées, bandeau, réglages de la visite) est donné comme déjà présent ; les outils
  communs (outil de maillage, fonctions de shader partagées) sont écrits dans les exemples de Paris et donnés comme
  présents pour Tokyo et New York. Chaque projet suit le plan d'organisation et passe le juge des règles sans écart.
- **Les sessions** : des erreurs sont posées dans le code juste de l'étape (un script, et souvent un shader), puis
  Godot est lancé pour de vrai à chaque tour, sur le projet tel que la session l'a laissé. Une session n'est gardée que
  si Godot (ou la recherche finale) a montré chacune de ses erreurs, et si le projet revient exactement au code de
  l'étape. Les sessions s'ajoutent, étape par étape, jusqu'à ce que leurs jetons de réponse égalent ceux des exemples
  de création de l'étape.
- **Toutes les sorties citées sont réelles** : Godot 4.7.2 a été lancé pour chacune (import, analyse, test, rendu), et
  `grep` aussi. En sont retirés : les codes de couleur, les lignes vides, les lignes d'information (version de Godot,
  pilote graphique, progression de l'import) et deux avertissements dus à la machine qui a produit la base : V-Sync
  impossible à régler sur son écran virtuel, et cache de shaders de Godot à reconstruire (« Failed to load cached
  shader, recompiling. »). Une erreur répétée à chaque construction n'est montrée que deux fois, pile d'appels
  raccourcie, avec le nombre de répétitions.
- **Chaque commande montrée est celle qui a tourné**, arguments compris : l'exécutable s'y appelle `godot`, et le
  préfixe propre à la machine qui a produit la base (`xvfb-run` et un rendu logiciel, faute d'écran) n'y figure pas.
  Le rendu enregistre son image dans `{IMAGE_RENDU}` puis quitte (`--shot`) ; `--quit-after` borne le lancement.
- **Les consignes d'édition ont été rejouées** : pour chacune des {rej['etapes']} étapes, les consignes des réponses de
  création, appliquées à la lettre à l'état de départ, redonnent le code de l'étape ({aucun(rej['fichiers_differents'], 'fichier différent', 'fichiers différents')},
  {aucun(rej['consignes_ambigues'], 'consigne ambiguë', 'consignes ambiguës', 'aucune')} ; seules les lignes vides peuvent différer).
- **Les preuves citées sont relues dans leur source** :
  - signatures : `extension_api.json` produit par le binaire 4.7.2 ;
  - descriptions : référence des classes du dépôt de Godot, étiquette `4.7.2-stable` ;
  - documentation : dépôt `godot-docs` ;
  - renommages : `editor/project_upgrade/renames_map_3_to_4.cpp` du moteur 4.7.2 ;
  - sources de métier : les notes du cours et ses carnets de recherche (`cours/batiments_proceduraux/recherches/`).

## Limites

- Format neutre, pas encore celui d'OpenCode (voir plus haut).
- Les explications de « Coder » reprennent le texte des notes du cours.
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
- Le tokenizer de Qwen 3.8 n'a pas pu être lu directement (voir « Comment les jetons sont comptés »).
"""
    return t


def ecrire(controles: dict, chemin: Path) -> Path:
    chemin = Path(chemin)
    chemin.write_text(texte(controles), encoding="utf-8", newline="\n")
    return chemin
