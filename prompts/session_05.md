# Session 5 — Boucle RFT

Modèle conseillé : Sonnet 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Transformer les tâches en données d'entraînement :

- Qwen résout chaque tâche plusieurs fois ;
- le juge note chaque essai ;
- on garde les réussites et on entraîne ;
- puis on recommence.

C'est un pipeline de production de données, pas un orchestrateur autour de Qwen à l'usage.

## Livrables

1. **`rft/essais`**
   - **Compétences en un appel** : appel direct à llama-server (`/v1/chat/completions`), avec sortie contrainte par schéma JSON, N essais par tâche, et choix du LoRA par requête (champ `lora`).
   - **Compétences agentiques** : lancer OpenCode en mode non interactif via son moteur embarqué (`opencode-cli`). **À confirmer avec l'utilisateur** dans `ETAT.md` : il n'utilise que la GUI au quotidien, et ce mode ne servirait qu'à produire des données.
   - En repli, prévoir un agent minimal maison, avec les mêmes outils MCP. Il servira aussi de deuxième harness.
2. **`rft/filtre`** : le juge note chaque essai ; on garde la solution réussie la plus courte, et les tâches jamais réussies passent au tour suivant.
3. **`rft/export`**
   - Format : JSONL au format chat (`messages`), avec une perte calculée uniquement sur les messages assistant.
   - Compatible LLaMA-Factory (déjà utilisé sur ce poste) et Unsloth.
   - Configurations fournies pour un QLoRA rang 16 sur Qwen3.8-27B, avec le **packing désactivé** : sur cette architecture hybride, rien ne garantit que l'état récurrent est remis à zéro entre exemples empaquetés.
4. **`rft/gguf`**
   - Conversion de l'adaptateur en GGUF (`convert_lora_to_gguf.py` de llama.cpp).
   - Un lanceur `.bat` llama-server avec plusieurs `--lora`, sans `-ngl`, et avec le raisonnement coupé pour OpenCode.
5. **`rft/tour`** : enchaîne essais, filtre et export.
   - Reprise possible après coupure grâce à un registre CSV écrit de façon atomique (fichier temporaire puis remplacement, enregistré après chaque tâche).

## Preuve de fin (dans le cloud)

- Un mini-tour complet contre un faux serveur qui répond juste dans 60 % des cas :
  - le nombre de solutions gardées est celui attendu ;
  - le JSONL est valide ;
  - les configurations se chargent ;
  - après une coupure simulée au milieu, la reprise n'est pas refaite en double.
- `pytest` est vert.

## À livrer aussi

`VERIFIER_EN_LOCAL.md` : un vrai mini-tour sur 20 tâches en un appel, avec mesure du temps par essai. Cette mesure sert à recaler l'hypothèse de 15 s du document de conception.

## Fin de session

Mettre à jour `ETAT.md`, puis committer et pousser.
