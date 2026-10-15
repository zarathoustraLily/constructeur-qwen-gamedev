"""Base d'entraînement tirée d'un cours en étapes (cours « bâtiments procéduraux »).

Pour chaque étape du cours, des exemples de création (la demande de l'étape, puis le cheminement : chercher,
coder, tester, vérifier, corriger) et des sessions de débogage à une ou plusieurs erreurs, jusqu'à ce que le
débogage pèse autant que la création en jetons de réponse (décision 3 de laurent). Les exemples sont au format
d'OpenCode, le harnais d'usage (décision 14, règle 7.4) : son prompt système, ses outils, ses retours d'outils.
Toutes les sorties de Godot citées sont réelles (règle 5.1) et arrivent dans le retour de l'outil : une réponse
n'écrit jamais la sortie d'une commande (règle 7.2). Aucun LLM : tout est déterministe (règle 2).

    python -m usine.cours.base generer [--villes …] [--etapes …] [--travailleurs 2] [--refaire]
    python -m usine.cours.base assembler
    python -m usine.cours.base tout [--travailleurs 2]
    python -m usine.cours.base.jetons <vocab.gguf> verifier      (le tokenizer face aux chaînes de test de llama.cpp)
    python -m usine.cours.base.jetons <vocab.gguf> compter <base.jsonl> [sortie.json]

Chemins de la machine (config.toml, ou options en ligne de commande) : `[chemins].docs_godot` (dépôt godot-docs),
`[chemins].source_godot` (dépôt godot à l'étiquette 4.7.2-stable : doc/classes, modules/gdscript/doc_classes,
editor/project_upgrade), `[entrainement].vocab_qwen` (le GGUF de Qwen 3.8, ou son vocabulaire seul),
`[opencode].session_reference` (une session OpenCode capturée par le proxy : prompt système et outils) et
`[opencode].dossier_cours` (le dossier Windows des projets du cours chez laurent).
Sorties dans donnees/cours/batiments_proceduraux/base/ (ignoré par git).
"""
