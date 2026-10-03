# Session 6 — Mesure

Modèle conseillé : Sonnet 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Dire, compétence par compétence, où en est réellement Qwen : avant et après le LoRA, avec et sans RAG, et face à un modèle frontière.

## Livrables

1. **`usine/mesure`**
   - Exécute les 4 configurations (base ± RAG, LoRA ± RAG) sur les jeux gelés, avec les mêmes prompts, grammaires et budgets.
   - Score au premier essai, intervalles de Wilson à 95 %.
   - Contrôle de non-régression des 13 compétences entre deux tours.
2. **Référence frontière (optionnelle)** : un script séparé, désactivé par défaut et jamais lancé automatiquement.
   - Il interroge une API externe avec une clé fournie par l'utilisateur, à lancer depuis le mini-PC en ligne.
   - Il porte sur les compétences en un appel, en deux variantes : sans adaptation, et avec le même RAG que Qwen.
3. **Adaptateur GameDevBench** (si les tâches sont publiques) :
   - récupère les tâches de logique de gameplay ;
   - les fait tourner avec leur propre binaire Godot 4.4.1, séparé du 4.7.2 ;
   - produit un score comparable aux scores publiés (environ 70 % pour le meilleur modèle frontière).
4. **Rapport `rapport_mesure.md`**, accompagné d'un CSV. Pour chaque compétence :
   - les 4 scores avec leurs intervalles ;
   - la référence frontière, si elle a été mesurée ;
   - le verdict « victoire / égalité / défaite », selon la règle de `CLAUDE.md`.

## Preuve de fin (dans le cloud)

- Un rapport généré à partir de résultats simulés.
- La règle de victoire testée sur des cas limites (intervalles qui se touchent, qui se chevauchent, frontière absente).
- `pytest` est vert.

## À livrer aussi

`VERIFIER_EN_LOCAL.md` : la mesure réelle des 4 configurations sur une compétence en un appel, avec la durée observée.

## Fin de session

Mettre à jour `ETAT.md`, avec le bilan des 6 sessions et la liste des vérifications locales restantes, puis committer et pousser.
