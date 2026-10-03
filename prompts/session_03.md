# Session 3 — L'usine à tâches

Modèle conseillé : Opus 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Fabriquer en masse des tâches dont la bonne réponse est connue d'avance, sans jugement humain ni LLM, et les filtrer par un portillon déterministe.

## Livrables

1. **`generateurs/masquage`** : dans un projet testé, vider le corps d'une méthode donne une tâche K2 ; vider tout un script donne une tâche K1. Utiliser le parseur de gdtoolkit s'il gère Godot 4.7, sinon un parseur minimal par indentation, à documenter.
2. **`generateurs/mutation`** : au moins 10 opérateurs (comparaison inversée, opérateur arithmétique, constante modifiée, chemin de nœud cassé, connexion supprimée, `await` retiré, mauvais type exporté, appel supprimé, condition niée, signal renommé).
   - Ils produisent des tâches K3 (test rouge + log, la cible étant l'original).
   - Ils produisent aussi des tâches D1 (log → catégorie + emplacement connus).
3. **`generateurs/aller_retour`** : une scène existante passe en spec (session 2) et devient une tâche S1 ou S2.
   - Le champ `consigne_a_ecrire` est réservé à Qwen pour plus tard.
   - En attendant, une consigne gabarit déterministe sert de base.
4. **`generateurs/mutants`** : calcule le score de mutation d'un fichier de tests, c'est-à-dire combien de mutants de la référence il tue. C'est le critère de qualité pour C2.
5. **`generateurs/inverse`** (pour F1) :
   - simuler en physique déterministe avec des paramètres tirés au hasard (vitesse, durée de dash, i-frames) ;
   - mesurer en frames ;
   - produire la tâche « retrouver les paramètres ».
6. **`generateurs/invention`** : l'entrée par laquelle Qwen proposera des tâches (format attendu et validation). Aucun appel LLM dans cette session ; un exemple fictif sert de test.
7. **`portillon`** : une tâche est acceptée si :
   - ses tests sont rouges au départ et verts sur la référence, 3 fois sur 3 ;
   - ils tuent au moins X % des mutants (X configurable) ;
   - elle n'est pas un doublon des jeux gelés (empreinte et fragments).

   Chaque rejet est journalisé avec sa raison. Ajouter un filtre de difficulté, prévu pour plus tard : garder les tâches que le modèle courant réussit entre 1 et 6 fois sur 8.
8. **Gel** : tirage reproductible (graine fixe) de 50 tâches par compétence disponible.
   - Empreintes dans `donnees/geles/manifeste.json`.
   - Exclusion appliquée partout : entraînement, RAG, invention.

## Preuve de fin

- 100 tâches acceptées sur au moins 6 compétences.
- 0 doublon avec les jeux gelés.
- Statistiques de rejet par raison.
- Résultat identique avec la même graine.
- `pytest` est vert.

## Fin de session

Mettre à jour `ETAT.md`, avec les volumes atteignables par compétence, puis committer et pousser.
