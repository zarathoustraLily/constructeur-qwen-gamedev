# Vérification de l'étape <ID> — <titre>

- **Vérifié par** : <session ou nom de l'IA> (autre que le réalisateur), le <date>
- **Branche vérifiée** : `claude/<ID>-<mot>` au commit <hash>
- **Conclusion** : accepté / refusé

## 1. Preuve rejouée
Commande rejouée et sortie obtenue (comparée à celle de la livraison) :

```
<commande>
<sortie>
```
Identique à la livraison : oui / non (différences : …).

## 2. Tests
```
<commande pytest et résultat>
```

## 3. Contrôles de CLAUDE.md
- [ ] Vérification déterministe de chaque exemple, aucun modèle dans les juges (décision 18.1, règle 2)
- [ ] Sorties de Godot réelles, lues ligne par ligne (règles 5.1 et 5.5)
- [ ] Noms Godot vérifiés dans `extension_api.json` 4.7.2 (règle 6)
- [ ] Avertissements en erreurs, typage compris, dans les projets qui suivent le plan (règle 5.3)
- [ ] Jetons comptés avec le tokenizer de Qwen 3.8, plafond respecté, aucune troncature (règles 5.8 et 7.5)
- [ ] Partage 40/40/20 en jetons de réponse (décision 3, règle 7.1)
- [ ] Plan présent, sauf exception de la section 3 (paires de 1 024 jetons sans convention du plan)
- [ ] Aucun texte d'une tâche gelée, rien de Starfox (règle 4)
- [ ] Une faute n'apparaît dans une réponse que comme texte à remplacer (règle 7.3) ; une réponse n'écrit jamais la
      sortie d'une commande (règle 7.2)
- [ ] Code multiplateforme, aucun chemin en dur, commentaires en français (règle 10)
- [ ] Corrections faites dans le générateur, pas dans les données (règle 5)

## 4. Échantillon relu (étapes qui produisent des données)
Tirage au hasard (graine : <n>) de 20 exemples :

| # | Exemple | Faute réelle | Réponse juste | Sortie réelle | Remarque |
| --- | --- | --- | --- | --- | --- |
| 1 | … | oui/non | oui/non | oui/non | … |

## 5. Critère d'acceptation de PLAN.md
- <critère> : atteint / non atteint.

## 6. À corriger (si refusé)
- …
