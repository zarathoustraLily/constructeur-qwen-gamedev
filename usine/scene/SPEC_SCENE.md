# Spec de scène (JSON) ↔ `.tscn`

Le LLM ne produit qu'une **spec** ; `scene_write` écrit le fichier, `valider_spec` vérifie le
vocabulaire, le juge (`load_scene`) tranche. Tout est déterministe : même spec, mêmes octets.

```python
from usine.scene import scene_read, scene_write, valider_spec, normaliser_tscn
spec = scene_read(texte_tscn, "res://scenes/coin.tscn")
texte = scene_write(spec, verif)          # verif : usine.projet.index.Verificateur
erreurs = valider_spec(spec, verif)       # [] si tout existe dans extension_api.json / les scripts
```

CLI : `python -m usine.scene lire|ecrire|valider|preuve` (voir `python -m usine.scene -h`).

## Format

```json
{
 "spec": 1,
 "chemin": "res://scenes/piege.tscn",
 "uid": "uid://…",
 "ressources_externes": [{"chemin": "res://scripts/piege.gd", "type": "Script", "uid": "uid://…"}],
 "ressources_internes": [
  {"nom": "forme", "type": "RectangleShape2D", "proprietes": {"size": {"Vector2": [48, 16]}}}
 ],
 "racine": {
  "nom": "Piege", "type": "Area2D", "script": "res://scripts/piege.gd",
  "proprietes": {"collision_layer": 4},
  "groupes": ["pieges"],
  "enfants": [
   {"nom": "Forme", "type": "CollisionShape2D", "proprietes": {"shape": {"SubResource": "forme"}}},
   {"nom": "Hero", "instance": "res://scenes/hero.tscn", "proprietes": {"position": {"Vector2": [64, 64]}}}
  ]
 },
 "connexions": [
  {"signal": "body_entered", "source": ".", "cible": ".", "methode": "_on_body_entered",
   "flags": 3, "binds": [true], "unbinds": 1}
 ],
 "editables": ["Hero"]
}
```

| Champ | Sens | Obligatoire |
| --- | --- | --- |
| `spec` | version du format (1) | non |
| `chemin` | chemin `res://` de la scène ; sert à dériver l'uid et les id internes | conseillé |
| `uid` | uid de la scène. **Absent** : dérivé du chemin. **`null`** : pas d'uid (comme les scènes de `godot/reference`) | non |
| `ressources_externes` | `[{chemin, type, uid?}]`. Facultatif : toute `{"ExtResource": "res://…"}` rencontrée est ajoutée ; le type est déduit de l'extension (`.gd` → Script, `.tscn` → PackedScene, images → Texture2D…). Obligatoire pour un `.tres` | non |
| `ressources_internes` | `[{nom, type, proprietes}]`, référencées par `{"SubResource": "<nom>"}` ; l'ordre d'écriture place une ressource après celles qu'elle utilise | non |
| `racine` | nœud racine | oui |
| `connexions` | `source` et `cible` sont des chemins de nœud relatifs à la racine (`.` = racine) | non |
| `editables` | chemins des nœuds instanciés dont les enfants sont éditables | non |

**Nœud** : `nom` ; `type` (classe native) **ou** `instance` (scène `res://…`) ; `script` ; `proprietes` ;
`groupes` ; `enfants`. Préservés tels quels s'ils existent dans le fichier lu : `unique_id`
(Godot 4.6+), `index`, `owner`, `instance_placeholder`, `node_paths`, `attributs_bruts`.
Un nœud sans `type` ni `instance` hors de la racine est une **surcharge** d'un nœud d'une scène
instanciée. `implicite: true` marque un parent non déclaré (nœud d'une scène instanciée) : il
n'est pas écrit.

### Valeurs

| Godot | JSON |
| --- | --- |
| `null`, `true`, `3`, `6.0`, `"texte"` | `null`, `true`, `3`, `6.0`, `"texte"` |
| `Vector2(320, 180)`, `Color(1, 0.5, 0, 1)`, `Transform3D(…)`, `PackedVector2Array(…)`… | `{"Vector2": [320, 180]}` : le nom du constructeur et ses arguments à plat |
| `&"nom"`, `NodePath("A/B")` | `{"StringName": "nom"}`, `{"NodePath": "A/B"}` |
| `[1, "a"]`, `Array[String](["a"])` | `[1, "a"]`, `{"Array[String]": ["a"]}` |
| `{"a": 1}`, `Dictionary[String, int]({…})` | `{"Dictionary": [["a", 1]]}`, `{"Dictionary[String, int]": [[…]]}` |
| `ExtResource("1_ab")`, `SubResource("Box_x")` | `{"ExtResource": "res://chemin"}`, `{"SubResource": "<nom>"}` |
| `inf`, `-inf`, `nan` | `{"float": "inf"}`… |
| tout le reste (`Object(…)`, tableau typé par un script) | `{"godot": "<texte brut>"}`, réécrit tel quel |

Un objet JSON a toujours **une seule clé** : le type. Les nombres suivent l'écriture de Godot 4.7 :
un flottant isolé garde sa partie décimale (`6.0`), une composante de constructeur non (`320`).

## Écriture (`scene_write`)

Format natif de Godot 4.7.2 (relevé en faisant sauver une scène par Godot) :

- en-tête `[gd_scene format=3 uid="…"]`, **sans `load_steps`** (Godot 4.7 ne l'écrit plus) ;
- les `ext_resource` en bloc, puis chaque `sub_resource`, puis les nœuds en **ordre préfixe**,
  puis les connexions en bloc, puis les `editable` ; une ligne vide entre les blocs ;
- attributs de nœud dans l'ordre de Godot : `name type parent owner index unique_id node_paths groups instance_placeholder instance` ;
- propriétés d'un nœud : **les natives d'abord** (dans l'ordre de la spec), puis `script`, puis les
  variables du script et les `metadata/…`. C'est l'ordre de Godot, et il compte : une variable de
  script écrite avant `script` serait ignorée au chargement ;
- un entier donné pour une propriété native flottante s'écrit `2.0`.

**Identifiants dérivés** (jamais tirés au hasard) :

| Quoi | Règle |
| --- | --- |
| id d'`ext_resource` | `<rang>_<h5(chemin de la ressource)>`, ex. `1_tqy3y` |
| id de `sub_resource` | `<Type>_<h5(chemin de la scène + "::" + nom d'usage)>` |
| uid de scène | `uid://` + 63 bits de SHA-256(chemin), alphabet de Godot (`a`–`y`, `0`–`8`) |

`h5` = 5 caractères `[a-z0-9]` tirés de SHA-256. Le **nom d'usage** d'une ressource interne vient
de son premier emploi : `<chemin du nœud>:<propriété>` (`CollisionShape2D:shape`, racine
`.:shape`), `<nom du parent>/<propriété>` pour une ressource utilisée par une autre
(`Sol/Maille:mesh/material`), suffixe `[k]` si une propriété en contient plusieurs,
`inutilisee_<n>` sinon. `scene_read` nomme les ressources internes ainsi ; `scene_write` dérive
l'id de ce nom et non du `nom` de la spec. Une scène écrite par `scene_write` redonne donc les
mêmes octets dès la première relecture.

## Validation (`valider_spec`)

Rien n'est inventé (règle 6) : chaque élément est cherché dans `usine/vocab` (extension_api.json)
et dans les scripts réels du projet (`usine/projet/index.py`).

- types de nœud (héritent de `Node`) et de ressource (héritent de `Resource`) ;
- propriétés : natives (héritage compris), variables des scripts (chaîne `extends` comprise,
  y compris le script de la racine d'une scène instanciée), et quelques propriétés dynamiques
  absentes d'extension_api.json : `theme_override_*/…`, `metadata/…`,
  `surface_material_override/N`, `shader_parameter/…`, `tracks/N/…`, `layer_N/…`, `libraries`
  (liste dans `PROPRIETES_DYNAMIQUES_*`, extensible) ;
- forme des valeurs selon le type déclaré (`int`, `float`, `String`, `Vector2` à 2 composantes,
  ressource compatible avec la classe attendue…) ;
- scripts : le fichier existe et sa classe native de base est un ancêtre du type du nœud ;
- connexions : le signal existe sur la source, la méthode sur la cible, et l'**arité** colle
  (`arguments du signal − unbinds + binds` dans `[obligatoires, total]`) ;
- noms de nœud non vides, sans `. : @ / " %`, uniques entre frères ; références internes et
  externes existantes.

Sans projet (`Verificateur(vocab, None)`), les variables de script ne sont pas vérifiables : seules
les propriétés natives passent. Les erreurs ont la forme d'une erreur de verdict ;
catégories employées : `vocab_inconnu`, `valeur_invalide`, `signal_missing`, `invalid_node_path`,
`missing_resource`, `type_error`.

## Normalisation documentée (aller-retour)

`normaliser_tscn` est indépendante de l'écrivain. Elle ne fait que deux choses :

1. retirer `load_steps` de `[gd_scene]` ;
2. renuméroter les id dans l'ordre du fichier (`E1, E2…` pour `ext_resource`, `S1, S2…` pour
   `sub_resource`) et réécrire les `ExtResource("…")` / `SubResource("…")` en conséquence.

Tout le reste (ordre des sections et des propriétés, valeurs, espaces, fins de ligne) doit être
identique. La preuve (`python -m usine.scene preuve`) vérifie en plus le **point fixe** (réécrire
une réécriture redonne les mêmes octets) et compare le `SceneState` que **Godot** charge avant et
après (`gd/etat_scene.gd`), ce qui ne dépend pas de notre lecteur.

Un `.tscn` écrit à la main peut différer après réécriture sur des points que Godot n'écrit
jamais ainsi : ordre non préfixe, script placé avant des propriétés natives, entier pour une
propriété flottante. Le contrôle Godot dit alors si le sens est conservé.
