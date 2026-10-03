# Session 2 — Traducteurs déterministes

Modèle conseillé : Opus 5.5. Lis d'abord `CLAUDE.md` et `ETAT.md`.

## Objectif

Construire le pendant Godot du traducteur Unreal (TRAD_02, TRAD_04, TRAD_05) :

- le LLM ne produit qu'une spec ou une liste d'éditions ;
- du code déterministe écrit les fichiers ;
- le juge tranche.

## Livrables

1. **Format « spec de scène »** en JSON, documenté dans `usine/scene/SPEC_SCENE.md` :
   - nœuds (nom, type, propriétés, enfants) ;
   - ressources externes et internes ;
   - scripts attachés, connexions, groupes.

   Chaque type et chaque propriété est vérifié par `usine/vocab`.
2. **`scene_write(spec) → .tscn` et `scene_read(.tscn) → spec`**, déterministes : même entrée, mêmes octets. Les identifiants (uid, id de ressource) sont stables, dérivés du chemin.
3. **`describe_project(projet)`** : une vue compacte et stable pour un LLM.
   - Arbre des scènes, scripts avec signatures, signaux, autoloads.
   - Un id lisible par nœud, et une table id → chemin.
4. **Le langage d'édition `usine/projet/EDITS_GODOT.md` et `apply_edits(projet, edits)`.**
   - Opérations : `add_node`, `del_node`, `set_property`, `attach_script`, `connect`, `disconnect`, `add_signal`, `add_function`, `replace_function` (remplace le corps d'une fonction GDScript désignée par son nom), `set_resource_value`.
   - Id inconnu → l'édit est refusé et renvoyé comme erreur, sans rien casser.
   - **Tout ou rien** : les éditions s'appliquent sur une copie de travail, remplacée de façon atomique seulement si le juge passe ; sinon la copie est jetée.
5. **Respect de l'existant** : les fichiers modifiés gardent leur ordre et leur formatage hors de la zone éditée.

## Preuve de fin

- Aller-retour `.tscn → spec → .tscn` identique, après la normalisation documentée, sur toutes les scènes de `godot/reference` et sur 5 scènes générées.
- Une liste d'éditions de démonstration, appliquée à une copie de la référence, donne un verdict PASS.
- Un édit volontairement faux est refusé, et le projet reste intact : son empreinte est identique avant et après.
- `pytest` est vert.

## À livrer aussi

`VERIFIER_EN_LOCAL.md`, complété avec ces commandes sous Windows.

## Fin de session

Mettre à jour `ETAT.md`, puis committer et pousser.
