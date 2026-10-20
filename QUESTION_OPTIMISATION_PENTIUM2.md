# Question à trancher : quelle métrique d'optimisation pour l'usine de génération

## Contexte

L'usine (`D:\constructeur-qwen-gamedev`) génère des **tâches d'entraînement** pour un modèle :
des mini-jeux Godot 4 (640×360) + des tests GdUnit4. Un **portillon** accepte ou rejette
chaque tâche selon des critères **mesurables et déterministes** (juge Godot headless
`--fixed-fps 60`, vérité terrain dans un `.json`).

Compétences déjà couvertes : correction comportementale (K1, K2, K3, D1, S1, S2) et
mesures déterministes du héros (F1, en frames, physique à 60 images/s).

**Objectif demandé** : que l'usine apprenne au modèle à écrire du code **ultra
performant, capable de tourner sur un Pentium II + GPU ATI ancienne génération
(matériel ~1999), SANS dégrader la qualité graphique** (même résolution, mêmes
lumières, mêmes effets — on n'y touche pas).

## Le problème

« Ultra performant » et « optimisation maximale » ne sont **pas des critères testables**
par un portillon. Il faut une **métrique mesurable avec un seuil**, dans le style de la
compétence F1 existante (mesure en frames, tolérance en px).

Sur du Pentium II / ATI Rage (1999), le goulot réel est :
- **GPU** : fillrate + nombre de **draw calls** (c'est ce qui tue les vieux GPU),
- **CPU** : allocations par frame, temps de la boucle de jeu.

« Ne pas dégrader la qualité graphique » exclut les tricheurs (baisser la résolution,
 couper les lumières/effets). Il ne reste que les optimisations **invisibles**.

## La question

**Quelle métrique d'efficience le portillon doit-il mesurer pour valider que le code
est « assez optimisé pour du Pentium II / ATI, sans dégrader la qualité graphique » ?**

### Option A — Draw calls + fillrate (côté GPU)
- C'est LE goulot réel des GPU 1999.
- Mesurable via les stats Godot (`RenderingServer` / `get_draw_call_in_last_frame()`)
  + en verrouillant la résolution et les effets graphiques.
- Le plus fidèle à la contrainte « Pentium II + ATI ».
- **Inconvénient** : plus dur à mesurer de façon **déterministe** en headless
  (le rendu peut varier selon la machine hôte).

### Option B — Temps CPU par frame + nombre d'allocations
- Le plus facile à mesurer de façon **déterministe** en headless
  (`OS.get_ticks_usec()` sur N frames + compteur d'allocations),
  dans le style exact de la compétence F1 existante.
- Forme bien le modèle à « ne pas allouer dans la boucle de jeu »,
  « `_physics_process` au lieu de `_process` quand c'est de la physique », etc.
- **Inconvénient** : ne capture pas le goulot GPU (draw calls / fillrate).

### Option C — Les deux (budget CPU **et** budget draw calls)
- Le plus complet, le plus proche de « optimisation maximale sans dégrader la qualité ».
- Le modèle apprend à optimiser **à la fois** le CPU et le GPU.
- **Inconvénient** : plus complexe à mettre en place (deux gabarits de juge,
  deux métriques à comparer à la référence).

## Ce que le portillon vérifierait (quel que soit le choix)

Pour toute tâche « optimisation », le verdict combinerait :
1. **Comportement identique** — les tests fonctionnels existants passent toujours
   (on n'a rien cassé).
2. **Qualité graphique identique** — même scène, mêmes paramètres graphiques
   (le juge vérifie qu'aucun réglage de rendu n'a été modifié).
3. **Métrique d'efficience ≤ référence** — la métrique choisie ci-dessus, mesurée
   en conditions déterministes, doit être **inférieure ou égale** à celle de la
   solution de référence optimisée.

Le modèle apprend alors : reconnaître l'anti-pattern d'efficience, le corriger,
**sans dégrader le rendu ni le comportement**.

## À trancher

- [ ] Option A (GPU : draw calls + fillrate)
- [ ] Option B (CPU : temps/frame + allocations)
- [x] **Option C (les deux)** — tranchée le 2026-10-04, voir la décision complète ci-dessous.
- [ ] Autre : ______

## Question bonus (à poser si l'option C est choisie)

Les seuils doivent-ils être **absolus** (« ≤ 3 ms/frame, ≤ 50 draw calls ») ou
**relatifs à la référence** (« ≤ 100 % du temps de la référence optimisée ») ?
Relatif est plus facile à calibrer ; absolu est plus lisible.

**Tranché : RELATIFS À LA RÉFÉRENCE.** L'absolu est proscrit : il empêcherait la
génération procédurale de 100 tâches de complexités variables et casserait au passage
Cloud (CI headless) ↔ machine hôte locale.

## Décision arrêtée (2026-10-04)

> **Option C** — les deux volets (CPU + GPU), seuils relatifs à la référence,
> métriques structurelles discrètes (compteurs entiers) pour le déterminisme CI.

### Les trois métriques du portillon

Le juge exécute le projet sous Godot headless `--fixed-fps 60` pendant **180 frames** :
frames 0–59 = warm-up (aucune mesure), frames 60–180 = fenêtre d'échantillonnage.

| Volet | Métrique | Règle |
|---|---|---|
| GPU — Draw calls | `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)`, médiane des frames 60–180 | `DC_candidat ≤ DC_ref × 1,05` |
| CPU — Churn d'allocations | `Δ objets = max(OBJECT_COUNT[60..180]) − min(OBJECT_COUNT[60..180])` | `Δ objets_candidat == 0` (absolu) |
| CPU — Temps relatif | Temps cumulé des ticks frames 60–180, médiane des frames, médiane sur 3 exécutions | `temps_candidat ≤ temps_ref × 1,15` |

### Points à valider par le constructeur

1. **Draw calls en `--headless`** : si `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` vaut 0 en headless
   (rendu désactivé), passer au **plan B** : mesure structurelle des draw calls (compteur
   entier de `CanvasItem` à texture distincte + `MultiMesh` vs sprites individuels dans l'arbre).
2. **`OBJECT_COUNT` en headless** : vérifier qu'il monte avec `instantiate()` et redescend avec
   `queue_free()`, et que le GC de Godot ne bruit pas le `delta`.

### Conditions de PASS (sur 3 exécutions consécutives)

1. **Comportement intact** — 100 % des tests GdUnit4 passent.
2. **Rendu intact** — aucun paramètre de résolution / environnement / effet modifié
   (inspection déterministe de `project.godot` et des scènes).
3. **Efficience validée** — les 3 sous-critères ci-dessus au vert.

### Suivi

La spécification de construction complète (format de tâche, format de verdict JSON,
nouvelles raisons de rejet, livrables, ordre de construction) est dans
**`SPEC_ENTRAINEUR_OPTIMISATION_STRICTE.md`** (même dossier).
