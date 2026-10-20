# Carnet d'instruction — Ajouter à l'usine un « Entraîneur d'optimisation stricte »

> **Destinataire** : le constructeur de l'usine de génération (`D:\constructeur-qwen-gamedev`).
> **Objet** : lui donner les indications pour construire une nouvelle compétence d'entraînement
> qui forme le modèle à écrire du code GDScript **ultra-performant, capable de tourner sur un
> Pentium II ~350 MHz + GPU ATI Rage (1999), SANS dégrader la qualité graphique**
> (même résolution 640×360, mêmes lumières, mêmes effets).
>
> **Ce document n'est pas du code** : ce sont des indications de construction, les contraintes à
> respecter, les points à valider, et les pièges à éviter. Le constructeur choisit l'implémentation.
>
> **Note d'intégration (2026-10-04)** : les noms de fichiers et l'architecture ci-dessous sont
> des **suggestions cohérentes** avec le code existant — le constructeur peut les adapter. Les
> points **fonctionnels** (ce que mesurer, les seuils, les conditions de PASS, les raisons de
> rejet) sont **contraignants**. Les noms ne le sont pas.

---

## 1. Ce que l'usine doit apprendre au modèle (la compétence)

Le modèle doit apprendre à **reconnaître un anti-pattern d'efficience dans un jeu Godot 2D et le
corriger SANS dégrader le comportement ni le rendu**. Concrètement, les anti-patterns cibles :

1. **Allocations dans la boucle de jeu** — `instantiate()` / `queue_free()` / `new()` dans
   `_process` ou `_physics_process` (projectiles, ennemis, particules) → **object pool**.
2. **Draw calls en excès** — N `Sprite2D` avec des textures/matériaux séparés, pas de batching →
   **atlas de textures / `MultiMeshInstance2D` / matériaux partagés**.
3. **Logique coûteuse dans la boucle** — parcours `O(N²)` (distances brutes entre toutes les
   entités), recalculs inutiles chaque frame → structures adaptées, calcul à la fréquence dont on a besoin.

**Ce que le modèle ne doit PAS apprendre** : baisser la résolution, couper les lumières ou les
effets de post-processing, tricher sur le fillrate. Le **rendu est verrouillé** (voir §4,
condition « rendu intact »). L'optimisation est donc **stricte** : elle doit venir du code, pas
du rendu.

---

## 2. Principe directeur des seuils : RELATIFS À LA RÉFÉRENCE

- **Proscrit** : les seuils absolus (« ≤ 3 ms/frame », « ≤ 50 draw calls »). Ils empêchent la
  génération procédurale de tâches de complexités variables et cassent au passage
  Cloud (CI headless) ↔ machine hôte locale.
- **Retenu** : chaque métrique du candidat est comparée à **la mesure de la solution de
  référence optimisée**, avec une **marge de tolérance** pour absorber le bruit de mesure.

Conséquence directe sur le **format de tâche** : une tâche d'optimisation contient
**deux versions du même jeu** :

- `depart/` — la version **non optimisée** (l'anti-pattern volontaire : pas de pooling,
  draw calls en excès, `O(N²)`). C'est ce que le modèle doit améliorer.
- `reference/` — la version **optimisée** (pool, batching, même comportement, même rendu).
  C'est le **plafond de performance** : le modèle doit faire **≤ référence**.

Les deux versions doivent être **comportementalement identiques** (mêmes tests) et
**graphiquement identiques** (même scène, mêmes paramètres de rendu). La seule différence
autorisée est l'efficience. C'est ce qui rend les seuils relatifs cohérents.

**Format de `tache.json`** — la tâche d'optimisation est **d'abord une tâche classique** du
format existant (`donnees/taches/<C>/<id>/tache.json`) : mêmes champs obligatoires
(`id`, `competence`, `consigne`, `empreinte`, `gelee`, `origine`, `generateur`). Deux
ajouts spécifiques :

1. `competence` vaut la nouvelle compétence (ex. `"E"`), et l'`id` suit la convention
   existante (`<competence>_<nom>`).
2. Un champ `mesure_efficience` (chemin ou contenu) qui pointe sur le fichier
   `mesure_efficience.json` : la **vérité terrain des métriques de la référence**
   (les agrégats `draw_calls` / `objets` / `temps_cpu` de `reference/`), exactement comme
   les compétences existantes embarquent leur vérité terrain dans `tache.json`.

> **Point que le constructeur doit trancher** : comment générer procéduralement des paires
> `depart`/`reference` garanties identiques en comportement et en rendu, mais différentes en
> efficience. (Suggestion : partir d'un gabarit de jeu existant dans `usine/generateurs/gabarits.py`,
> produire une variante « naïve » et une variante « optimisée », puis **vérifier à la génération**
> que les deux passent les mêmes tests et que leurs paramètres de rendu sont identiques ;
> écartez la paire sinon, comme les `ecartes_a_la_generation` existantes.)
>
> **La consigne doit dire explicitement** que l'optimisation est stricte : le code doit être
> rendu plus efficace **sans changer le comportement ni le rendu** (les tests comportementaux
> doivent continuer à passer, aucun paramètre graphique à modifier). C'est la consigne qui
> fait apprendre au modèle la distinction « optimiser » vs « tricher sur le rendu ».

---

## 3. Les trois métriques d'efficience (décision arrêtée : les deux volets, CPU + GPU)

Pour chaque tâche, le juge exécute le projet sous **Godot headless `--fixed-fps 60`** pendant
**180 frames** :

- **Frames 0–59** : warm-up (instanciation initiale, allocation du pool). **Aucune mesure.**
- **Frames 60–180** : fenêtre d'échantillonnage.

### A. Volet GPU — Draw calls (contrainte ATI Rage : fillrate & state changes)

- **Métrique** : `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)`
  (ou `RenderingServer.get_total_draw_calls_in_last_frame()`), **médiane** des frames 60–180.
- **Règle** : `draw_calls_candidat ≤ draw_calls_reference × 1,05`
- **Comportement attendu du modèle** : `MultiMeshInstance2D`, atlas de textures, matériaux
  partagés, absence de sur-découpage de canvas.

> ⚠️ **POINT À VALIDER PAR LE CONSTRUCTEUR (bloquant pour le volet GPU)** : en `--headless`,
> Godot peut **désactiver le rendu** → la métrique vaudrait 0 pour tout le monde et serait
> inutilisable. **Le constructeur DOIT vérifier** que `RENDER_TOTAL_DRAW_CALLS_IN_FRAME > 0`
> en headless sur une scène avec des sprites.
> - Si **> 0** : la métrique GPU telle que spécifiée fonctionne. ✅
> - Si **= 0** : **plan B** — mesurer les draw calls **structurellement** (compteur entier de
>   `CanvasItem` à texture distincte + `MultiMesh` vs sprites individuels, dans l'arbre de la
>   scène — le sous-juge `load_scene` décrit déjà les nœuds, c'est exploitable). C'est moins
>   fidèle au GPU réel mais **déterministe** et fonctionnel en headless. **Le constructeur
>   choisit le plan B si la validation échoue**, et le documente.

### B. Volet CPU — Churn d'allocations (contrainte Pentium II : cache L2 & RAM)

- **Métrique** : `Δ objets = max(OBJECT_COUNT[60..180]) − min(OBJECT_COUNT[60..180])`
  (`Performance.get_monitor(Performance.OBJECT_COUNT)` ou `OS.get_object_count()`).
- **Règle** : `Δ objets_candidat == 0`  **(seuil absolu, pas relatif)**
- **Comportement attendu du modèle** : **interdiction** de `instantiate()` / `queue_free()` /
  `new()` dans `_process` / `_physics_process` ; **object pool obligatoire** pour projectiles,
  ennemis, particules.

> Le seuil est **absolu** (== 0) car le churn est un compteur binaire : soit le code alloue dans
> la boucle (Δ > 0), soit non (Δ = 0). C'est le critère le plus déterministe des trois.
>
> ⚠️ **À valider** : que `OBJECT_COUNT` monte bien avec `instantiate()` et redescend avec
> `queue_free()` en headless, et que le GC de Godot ne bruite pas le `delta`.

### C. Volet CPU — Temps d'exécution relatif

- **Métrique** : temps cumulé des ticks de la boucle de jeu sur les frames 60–180
  (`OS.get_ticks_usec()` / `Time.get_ticks_usec()` en début/fin de `_process` d'un nœud de mesure).
  Prendre la **médiane** des frames, puis la **médiane sur 3 exécutions** (règle n°2 de
  `CLAUDE.md` : résultat identique 3 fois sur 3).
- **Règle** : `temps_candidat ≤ temps_reference × 1,15`
  (tolérance de 15 % pour absorber le jitter 10–25 % d'une VM cloud partagée).
- **Comportement attendu du modèle** : éviter la logique `O(N²)`, ne recalculer que ce qui change,
  `_physics_process` pour la physique (pas `_process`).

> C'est la métrique **la plus bruitée** des trois. La double médiane (frames × exécutions) +
> plafond 1,15× est la protection. Le constructeur doit documenter que ce seuil est le plus
> sensible à la machine hôte.

---

## 4. Format du verdict JSON du juge d'efficience

S'intègre au **format commun** existant (`usine/juge/verdict.py` → `nouveau_verdict`).
Nouvelle étape `mesure_efficience` :

```json
{
  "ok": true,
  "etape": "mesure_efficience",
  "duree_s": 3.1,
  "metriques": {
    "draw_calls":            { "valeur": 3,   "reference": 3, "ok": true },
    "allocations_actives_apres_warmup": { "delta_objets": 0, "ok": true },
    "temps_cpu_relatif":     { "ratio": 0.94, "plafond": 1.15, "ok": true }
  },
  "tests": { "total": 6, "passes": 6, "echecs": [] }
}
```

---

## 5. Conditions de validation finale d'une tâche d'optimisation (PASS)

Une tâche est **PASS** si et seulement si, **sur 3 exécutions consécutives** (règle n°2) :

1. **Comportement intact** — 100 % des tests fonctionnels GdUnit4 passent (le jeu fonctionne à
   l'identique).
2. **Rendu intact** — aucun paramètre de résolution, d'environnement ou d'effet n'a été dégradé
   (vérifié par **inspection déterministe** de `project.godot` et des scènes : sections
   `[display]`/`[rendering]`, propriétés de rendu des `CanvasItem`/`Light2D`, `WorldEnvironment`).
   → Si un paramètre graphique a été modifié, **rejet `rendu_degrade` même si les métriques
   d'efficience sont bonnes** (on interdit de tricher en coupant le rendu).
3. **Efficience validée** — les trois sous-critères (§3 A/B/C) sont au vert.

### Nouvelles raisons de rejet à ajouter dans `usine/portillon/regles.py` (`RAISONS`)

| Raison | Déclenchement |
|---|---|
| `efficience_draw_calls` | `draw_calls_candidat > draw_calls_ref × 1,05` |
| `efficience_allocations` | `Δ objets_candidat > 0` |
| `efficience_temps` | `temps_candidat > temps_ref × 1,15` |
| `rendu_degrade` | un paramètre graphique a été modifié vs la référence |

> Les raisons existantes (`depart_pas_rouge`, `reference_pas_verte`, `instable`,
> `score_mutation_insuffisant`, `doublon_gele`, `doublon_candidat`, `format_invalide`)
> s'appliquent **en plus** : une tâche d'optimisation doit d'abord être une tâche valide au
> format classique (départ rouge, référence verte, tests cachés qui tuent les mutants).

---

## 6. Pièges que le constructeur DOIT éviter

1. **Draw calls = 0 en headless** (§3 A, point à valider). C'est le seul point qui peut
   invalider le volet GPU. **Valider avant de coder le reste.**
2. **Ne pas confondre « optimiser » et « tricher sur le rendu »** : la condition « rendu intact »
   (§5.2) est **non négociable**. Sans elle, le modèle apprendrait à baisser la résolution.
3. **Le churn d'objets absolu (== 0)** peut être trop strict si le GC de Godot n'est pas
   déterministe en headless. Si des faux positifs apparaissent, le constructeur peut admettre
   `Δ ≤ 1` (un objet résiduel) plutôt que `== 0`, **en le documentant**.
4. **Générer des paires départ/référence non identiques** : si `depart` et `reference` ne sont
   pas comportementalement/graphiquement identiques, les seuils relatifs sont sans sens. La
   vérification à la génération (§2, point à trancher) est **obligatoire**.
5. **Ne pas mesurer le temps en wall-clock brut** sans double médiane : le jitter de la VM cloud
   (10–25 %) fausserait le verdict.

---

## 7. Ce que le constructeur doit produire (livrables)

1. **Sous-juge de mesure** `usine/juge/efficience.py` + script Godot
   `usine/juge/gd/mesurer_efficience.gd` (180 frames, warm-up 60, échantillonnage 60–180,
   agrégats médiane/churn/temps).
2. **Sous-juge statique** `usine/juge/rendu_intact.py` (inspection `project.godot` + scènes).
3. **Extension du portillon** `usine/portillon/regles.py` : 3 nouvelles raisons de rejet
   (§5) + intégration des 3 sous-critères dans `Decision` + condition « rendu intact ».
4. **Générateur** `usine/generateurs/efficience.py` : paires `depart`/`reference` +
   `mesure_efficience.json` (vérité terrain des métriques de la référence).
5. **Branchement** dans `usine/generateurs/produire.py` (nouvelle compétence, ex. `E`) et
   `usine/portillon/chaine.py`.
6. **Tests** du sous-juge : une tâche optimisée est acceptée ; une tâche qui alloue dans la
   boucle est rejetée (`efficience_allocations`) ; une tâche qui dégrade le rendu est rejetée
   (`rendu_degrade`) ; une tâche `O(N²)` est rejetée (`efficience_temps` ou
   `efficience_draw_calls`).
7. **Vérification 3/3 reproductible** sur au moins une tâche d'exemple (règle n°2 de `CLAUDE.md`).

---

## 8. Ordre de construction recommandé

1. **Valider les 2 points Godot** (§3 A « draw calls en headless », §3 B « object count en
   headless ») — 2 scripts courts. **Bloquant** : détermine si le volet GPU est mesurable tel
   quel ou si le plan B (mesure structurelle) est nécessaire.
2. Écrire le sous-juge de mesure + les 3 agrégats.
3. Écrire le sous-juge `rendu_intact`.
4. Étendre le portillon (raisons + `Decision`).
5. Écrire le générateur de paires.
6. Brancher + tester + vérifier 3/3.

---

## Résumé en une phrase

> Construire une **compétence d'optimisation stricte** où le modèle part d'un jeu Godot 2D
> **non optimisé**, doit le rendre **≤ une référence optimisée** sur 3 métriques (draw calls,
> churn d'allocations = 0, temps CPU relatif), **sans toucher au comportement ni au rendu**,
> avec des **seuils relatifs à la référence** et une **validation 3/3 reproductible** — le tout
> mesuré en **Godot headless `--fixed-fps 60`** sur 180 frames (warm-up 60).
