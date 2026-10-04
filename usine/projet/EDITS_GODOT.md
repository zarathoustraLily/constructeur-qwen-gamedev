# Langage d'édition Godot (`apply_edits`)

Le LLM ne modifie pas les fichiers : il produit une **liste d'éditions** JSON. Du code
déterministe l'applique, le juge tranche. Pendant de TRAD_04/TRAD_05 côté Unreal.

```python
from usine.projet.decrire import describe_project
from usine.projet.editions import apply_edits

vue = describe_project("D:/GODOT/projet_mario")   # vue["texte"] pour le LLM, vue["ids"] : id → chemin
verdict = apply_edits("D:/GODOT/projet_mario", edits)
```

CLI : `python -m usine.projet describe <projet>`, `python -m usine.projet apply <projet> <edits.json>`,
`python -m usine.projet demo`.

## Cibles

| Cible | Forme | Exemple |
| --- | --- | --- |
| nœud | `<alias de scène>:<chemin du nœud>` ; la racine : `<alias>` | `main:Coins/Coin1`, `coin` |
| script | chemin `res://….gd` | `res://scripts/hero.gd` |
| ressource | `res://….tres`, ou `<id de nœud>#<propriété>` pour la ressource que porte cette propriété | `coin:CollisionShape2D#shape` |

L'alias d'une scène est le nom de son fichier sans `.tscn` (le chemin sans extension si deux
scènes portent le même nom). `describe_project` affiche ces id ; ils sont stables tant que le
nœud ne change ni de nom ni de parent. Un id inconnu refuse l'édit.

## Opérations

Les valeurs suivent le codage JSON de `usine/scene/SPEC_SCENE.md` (`{"Vector2": [x, y]}`,
`{"ExtResource": "res://…"}`…). Une propriété peut aussi recevoir une ressource interne neuve,
écrite en ligne : `{"SubResource": {"type": "RectangleShape2D", "proprietes": {"size": {"Vector2": [4, 6]}}}}`.

| `op` | Champs | Effet |
| --- | --- | --- |
| `add_node` | `parent`, `nom`, `type` **ou** `instance`, `script`?, `proprietes`?, `groupes`? | Ajoute le nœud après le dernier descendant du parent. |
| `del_node` | `noeud` | Retire le nœud, ses descendants, les connexions et `editable` qui les touchent, puis les ressources devenues orphelines. La racine est refusée. |
| `set_property` | `noeud`, `propriete`, `valeur` | Remplace la ligne, ou l'insère : propriété native avant `script`, variable de script en fin. |
| `attach_script` | `noeud`, `script`, `contenu`? | Pose `script = ExtResource(…)`. Avec `contenu`, crée d'abord le fichier (qui ne doit pas exister). |
| `connect` | `source`, `signal`, `cible`, `methode`, `binds`?, `unbinds`?, `flags`? | Ajoute `[connection …]` en fin de bloc. Source et cible dans la même scène. |
| `disconnect` | `source`, `signal`, `cible`, `methode` | Retire cette connexion. |
| `add_signal` | `script`, `signal`, `arguments`? (`[{"nom", "type"}]` ou `["nom: Type"]`) | Ajoute `signal …` après le dernier signal (sinon après `class_name`/`extends` et la doc `##`). |
| `add_function` | `script`, `code` (une fonction complète) | Ajoute la fonction en fin de fichier, deux lignes vides avant. |
| `replace_function` | `script`, `fonction`, `corps` **ou** `code` | `corps` : remplace le corps et garde la signature. `code` : remplace la fonction entière (même nom). La doc `##` au-dessus est gardée. |
| `set_resource_value` | `ressource`, `propriete`, `valeur` | Change une propriété d'une ressource interne de scène ou du `[resource]` d'un `.tres`. |

Le code GDScript fourni est **réindenté** selon le fichier : tabulations ou espaces, niveaux
relatifs conservés (GDScript refuse un mélange des deux).

## Contrôles avant écriture (déterministes, sans LLM)

Comme pour la spec de scène, tout vient d'`extension_api.json` et des scripts réels :

- types natifs (et héritage de `Node` ou `Resource`) ; propriétés natives, dynamiques reconnues
  ou déclarées par le script du nœud (chaîne `extends`, script de la racine d'une instance) ;
- forme des valeurs selon le type déclaré ; un entier pour un flottant s'écrit `2.0` ;
- script : il existe et sa classe de base est compatible avec le nœud ;
- connexion : signal existant, méthode existante (script ou native), arité compatible
  (`arguments du signal − unbinds + binds`), pas de doublon ;
- signal ou fonction ajoutés : nom libre (script, scripts parents, classe native) ; types
  d'arguments connus (intégrés, classes natives, `class_name` du projet) ;
- noms de nœud valides et uniques entre frères.

## Tout ou rien

1. Les éditions s'appliquent **en mémoire**, dans l'ordre : un édit peut viser un nœud ou une
   fonction créés par un édit précédent. Au **premier refus**, rien n'est écrit et le verdict
   indique l'édit fautif (`edit` = son rang à partir de 0) ; les suivants ne sont pas examinés.
2. Les fichiers modifiés sont écrits dans une **copie de travail** du projet (hors `.godot`),
   jugée par le juge commun : `import → check_script → load_scene → run_tests` (les tests
   seulement si le projet a un dossier `tests/`).
3. Juge en échec : la copie est jetée, le projet n'est pas touché.
4. Juge vert : chaque fichier modifié est écrit dans un fichier temporaire voisin puis remplacé
   par `os.replace` (atomique par fichier, y compris sous Windows). Avant, on vérifie que le
   fichier n'a pas changé depuis la lecture (sinon : refus, étape `ecriture`). Si un
   remplacement échoue au milieu, ceux déjà faits sont restaurés.

Leçon d'Unreal (règle 7) : on ne laisse jamais un projet à moitié modifié.

## Respect de l'existant

Les fichiers sont édités en place, pas régénérés : `.tscn`/`.tres` sont découpés en sections
qui gardent leur texte d'origine (`usine/scene/texte.py`), et seule la ligne ou la section visée
change. Les fins de ligne (LF ou CRLF) sont conservées. Seuls ajustements hors de la zone
éditée : la ligne vide qui sépare deux sections quand on en insère ou retire une, et
`load_steps` dans l'en-tête s'il existe (fichiers antérieurs à Godot 4.7), recalculé.

## Verdict

Le format du verdict commun, étendu (champs ajoutés, rien de retiré) :

```json
{"ok": false, "applique": false, "etape": "validation", "duree_s": 0.02,
 "erreurs": [{"edit": 1, "op": "set_property", "fichier": "res://scenes/main.tscn", "ligne": null,
              "categorie": "id_inconnu",
              "message": "édit 1 (set_property) refusé : id inconnu : 'main:Coins/Coin9' (…)"}],
 "tests": {"total": 0, "passes": 0, "echecs": []},
 "fichiers": []}
```

`etape` : `validation` (édit refusé), une étape du juge (`check_script`, `run_tests`…), ou
`ecriture` (conflit ou échec disque). `fichiers` liste les fichiers modifiés (`res://`).
Catégories ajoutées : `id_inconnu`, `vocab_inconnu`, `valeur_invalide`.

## Exemples

`usine/projet/exemples/` : `demo_reference.json` (les 10 opérations, PASS sur une copie de
`godot/reference`), `faux_id_reference.json` (refus à la validation) et
`faux_juge_reference.json` (refus par les tests). `python -m usine.projet demo` les rejoue sur
une copie jetable et affiche l'empreinte du projet avant et après chacun.
