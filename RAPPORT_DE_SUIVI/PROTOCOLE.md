# Protocole de travail à plusieurs IA

But : avancer en parallèle sans se marcher dessus, et ne rien compter comme fait tant qu'une **autre** IA ne l'a pas
vérifié en rejouant la preuve. Ce protocole complète `CLAUDE.md` ; en cas de contradiction, `CLAUDE.md` l'emporte.

## 1. Les rôles

- **Réalisateur** : l'IA qui fait une étape.
- **Vérificateur** : une autre IA (autre session), qui n'a pas écrit le code de l'étape. Elle rejoue la preuve et
  contrôle la livraison.
- **laurent** : tranche les désaccords, donne les accords (lancements sur son PC, fusion dans `main`, dépenses), et
  décide de tout ce qui est marqué « ouvert » ou « proposé » dans `CLAUDE.md`.

Une IA ne vérifie jamais sa propre étape.

## 2. Les états d'une étape (dans `TABLEAU.md`)

```
à faire → réservée (par qui, date) → faite (preuve) → vérifiée (par qui, rapport)
                                         └→ refusée (raison) → réservée de nouveau
```

- **à faire** : ses dépendances sont vérifiées ou il n'y en a pas (sinon : « en attente de <ID> »).
- **réservée** : une IA s'en charge. Une réservation sans livraison depuis 48 h peut être reprise par une autre IA,
  avec une ligne dans `journal.md`.
- **faite** : livrée selon `modeles/LIVRAISON.md`, preuve collée.
- **vérifiée** : un rapport `verifications/<ID>.md` conclut « accepté ».
- **refusée** : le rapport conclut « refusé », avec ce qu'il faut corriger.

## 3. Réserver

1. Choisir dans `TABLEAU.md` une étape « à faire ».
2. Mettre son état à « réservée », son nom de session et la date ; ajouter une ligne à `journal.md`.
3. Travailler sur une branche à soi : `claude/<ID>-<mot>` (par exemple `claude/B1-compilation`), partie de la
   branche de travail commune.
4. Ne toucher qu'aux fichiers de l'étape. Un changement d'un fichier partagé (`usine/cours/base/…`,
   `usine/rag/…`, `CLAUDE.md`) se signale dans la livraison et dans `journal.md`.

## 4. Livrer

Remplir `modeles/LIVRAISON.md` dans la section de l'étape (ou dans le message de commit, pour une petite étape) :
- ce qui a été fait, fichiers touchés ;
- la commande de preuve et sa sortie **réelle**, sans rien retirer d'autre que ce que permet la règle 5.1 ;
- les tests ajoutés et leur résultat ;
- ce qui n'a pas été fait ou reste douteux.

Puis : état « faite », commit et push de la branche, ligne dans `journal.md`. Pas de fusion avant vérification.

## 5. Vérifier

Le vérificateur :
1. récupère la branche ;
2. **rejoue la commande de preuve** (sur le PC de laurent pour ce qui demande Godot, avec son accord) et compare sa
   sortie à celle de la livraison ;
3. lance les tests du dépôt touchés (`py -3.12 -m pytest -q tests/…`) ;
4. contrôle la liste de `modeles/VERIFICATION.md` (règles de `CLAUDE.md`, critère d'acceptation de `PLAN.md`) ;
5. tire **au hasard** 20 exemples produits (pour une étape qui produit des données) et relit chacun : la faute est
   réelle, la réponse est juste, la sortie de Godot est réelle, aucune convention du plan dans une paire sans plan,
   aucun texte d'une tâche gelée ni de Starfox ;
6. écrit `verifications/<ID>.md` : accepté ou refusé, avec les sorties rejouées.

Un refus dit précisément quoi corriger. Le réalisateur corrige **le générateur** (règle 5), puis relivre.

## 6. Désaccord

Si le réalisateur conteste un refus : une ligne dans `journal.md` avec les deux positions et leurs preuves, puis
laurent tranche. On n'écrase jamais le travail d'une autre IA sans cette étape.

## 7. Fusion

Une étape vérifiée se fusionne dans la branche de travail commune (`claude/observation-visuelle` à ce jour). La
fusion dans `main` attend l'accord de laurent et la vérification locale (règle de la section 3 de `CLAUDE.md`).

## 8. Le PC de laurent

Une seule 5090 et un seul llama-server : c'est le goulot.
- Les générations (Godot) et les entraînements se réservent comme des étapes, avec l'accord de laurent.
- Jamais deux entraînements, ni un entraînement et une campagne, en même temps.
- Pendant une campagne : ne pas modifier `D:\constructeur-qwen-gamedev` ni `D:\GODOT\projet_starfox`.
