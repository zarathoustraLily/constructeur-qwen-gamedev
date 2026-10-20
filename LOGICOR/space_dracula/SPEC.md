# SPEC.md — Space Dracula

Ce fichier est la référence complète pour reconstruire le jeu.
Une IA qui lit ce fichier + les JSON de données + le README doit pouvoir coder le jeu.

---

## 1. VUE GLOBALE

Space Dracula est un action-RPG 3D top-down. Le joueur contrôle un héros qui traverse des salles de combat, affronte des ennemis, des mini-bosses et des boss, et progresse sur 8 niveaux (biomes).

### Boucle de jeu

```
Run (Course)
  → Niveau 1 (Biome A)
    → Salle 1 (Combat)
      → Rencontre → Vagues → Ennemis spawnés
      → Joueur combat les ennemis
      → Tous ennemis morts → salle déverrouillée
    → Salle 2 (Mini-Boss)
      → Mini-Boss + Ennemis
    → Salle 3 (Boss)
      → Boss (phases → attaques)
  → Niveau 2 ...
  → Niveau 8 (Boss Final)
```

### Contrôles du héros

| Action | Clé | Effet |
|--------|-----|-------|
| Haut | Z / Flèche haut | Déplacement avant |
| Bas | S / Flèche bas | Déplacement arrière |
| Gauche | Q / Flèche gauche | Déplacement gauche |
| Droite | D / Flèche droite | Déplacement droite |
| Attaque | Espace | Coup de base (dégâts dans un arc devant le héros) |
| Dash | Maj | Esquive rapide dans la direction du mouvement (i-frames pendant la durée) |
| Skill 1 | C | Compétence active (souffle requis) |
| Skill 2 | V | Compétence active (souffle requis) |

### Perspective

- Camera top-down : positionnée au-dessus du héros, orientée vers le bas (rotation X = -90°).
- Le héros est un CharacterBody3D qui se déplace sur le plan XZ.
- Y = hauteur (fixe, le héros est au sol Y=0).

---

## 2. ARCHITECTURE CODE

### Structure des dossiers

```
LOGICOR/
├── project.godot              # Config Godot 4.7
├── acteurs/                   # Les corps (CharacterBody3D)
│   ├── BPC_HerosBase.gd       # Héros : mouvement, attaque, dash
│   ├── BPC_EnnemiBase.gd      # Ennemi : IA, stats, mort
│   ├── BPC_BossBase.gd        # Boss : phases, attaques
│   └── BPC_SalleBase.gd       # Salle : cycle de vie (ATTENTE→COMBAT→COMBAT_FINI→VERROUILLEE)
├── adversaires/               # L'IA des ennemis
│   ├── BPC_AggroSense.gd      # Ciblage : marque la cible si en portée
│   ├── BPC_PhaseManager.gd    # Arbre de décision à 6 états
│   ├── BPC_WeaponManager.gd   # Choix d'arme parmi l'arsenal
│   └── FL_Enemy.gd            # (ancien) Fiche d'ennemi Resource — à supprimer
├── donnees/                   # Les fiches de données (Resource Godot)
│   ├── FicheHeros.gd          # Stats du héros
│   ├── FicheEnnemi.gd         # Stats d'un ennemi (CRT-XXX)
│   ├── FicheBoss.gd           # Stats d'un boss (ANO-XXX) avec phases et attaques
│   ├── FicheArme.gd           # Stats d'une arme (REL-XXX)
│   ├── FicheMiniBoss.gd       # Stats d'un mini-boss (MIN-XXX)
│   ├── FicheSalle.gd          # Paramètres d'une salle
│   └── *.tres                 # 114 fiches de données (61 CRT + 7 ANO + 34 REL + 12 MIN)
├── systemes/                  # Les systèmes de gameplay
│   ├── BPC_Stats.gd           # PV, souffle, i-frames, dernier effort, combo
│   ├── BPC_DegratsPipeline.gd # Pipeline de dégâts (base × modif + additif, crit ×3)
│   ├── BPC_Invuln.gd          # I-frames (activation sous seuil de PV)
│   ├── BPC_DernierEffort.gd   # Dernier effort (soin + réduction de dégâts)
│   └── BPC_DirectorRun.gd     # Directeur de run (génération de salles, encounters)
├── scenes/                    # Les scènes .tscn
│   ├── Heros.tscn             # Scène du héros
│   ├── Ennemi.tscn            # Scène d'un ennemi
│   ├── Boss.tscn              # Scène d'un boss
│   ├── Salle.tscn             # Scène d'une salle (sol, murs, spawn points)
│   └── Jeu.tscn               # Scène principale (caméra, HUD, directeur de run)
├── ui/                        # Les scripts d'interface
│   ├── HUD.gd                 # Barre de PV, souffle, combo
│   └── HUD.tscn               # Scène du HUD
├── preuves/                   # Les tests (scripts SceneTree headless)
│   ├── L_TestOracles.gd
│   ├── L_TestDegrats.gd
│   ├── L_TestInvuln.gd
│   ├── L_TestDernierEffort.gd
│   ├── L_TestDirectorRun.gd
│   └── L_TestChargementFiches.gd
├── space_dracula/             # Données brutes + fiches JSON
│   ├── SPEC.md                # Ce fichier
│   ├── README.md              # Instructions d'assemblage
│   ├── fiches/                # Les fiches JSON (source de vérité)
│   │   ├── FICHES_ENNEMIS_V2.json   # 61 ennemis
│   │   ├── FICHES_BOSSES_V2.json    # 7 bosses, 96 attaques, 30 phases
│   │   ├── FICHES_ARMES_V2.json     # 34 armes
│   │   └── FICHES_MINI_BOSSES_V2.json # 12 mini-bosses, 60 attaques
│   └── ORGANOGRAPHE_COMPLET.md # Organigramme complet (1300 lignes)
└── tools/                     # Les outils Python de génération
    ├── generer_fiches_v2.py
    ├── generer_fiches_armes.py
    ├── convertir_json_tres.py
    └── verifier_tokens_sd.py
```

### Hiérarchie des scènes

```
Jeu.tscn (Node3D)
├── Camera3D (top-down, suit le héros)
├── HUD (CanvasLayer)
├── DirectorRun (Node, script BPC_DirectorRun)
├── Salle (Node, script BPC_SalleBase)
│   ├── Sol (MeshInstance3D)
│   ├── Murs (StaticBody3D × 4)
│   ├── SpawnPoints (Node)
│   │   ├── SpawnPoint_01 (Marker3D)
│   │   ├── SpawnPoint_02 (Marker3D)
│   │   └── ...
│   ├── Ennemis (Node) — les ennemis sont ajoutés ici au spawn
│   └── Porte (Area3D) — déverrouillée quand le combat est fini
└── Heros (CharacterBody3D, script BPC_HerosBase)
```

---

## 3. ENTITÉS

### 3.1 Héros

**Script** : `BPC_HerosBase.gd` (extends CharacterBody3D)
**Fiche** : `FicheHeros.gd` (Resource)

#### Props de la fiche (FicheHeros.gd)

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| vie_max | int | 30 | PV maximum |
| souffle_max | int | 50 | Souffle maximum (ressource des compétences) |
| seuil_invuln | float | 0.25 | Seuil de PV sous lequel les i-frames s'activent |
| degat_min_invuln | int | 15 | Dégâts minimum pour déclencher les i-frames |
| fenetre_cumul | float | 0.6 | Fenêtre de cumul des dégâts pour les i-frames |
| duree_invuln | float | 1.3 | Durée des i-frames en secondes |
| dernier_effort_soin | float | 0.4 | Fraction de PV restaurée par le dernier effort |
| dernier_effort_duree | float | 5.0 | Durée du dernier effort en secondes |
| dernier_effort_modif | float | 0.3 | Réduction de dégâts pendant le dernier effort |
| mode_facile_base | float | 0.8 | Multiplicateur de dégâts subis en mode facile |
| mode_facile_mort | float | -0.02 | Réduction de la vie max en mode facile |
| mode_facile_cap | int | 30 | Plafond de vie en mode facile |
| cout_porte_secrete_base | float | 10.0 | Coût de base de la porte secrète |
| cout_porte_secrete_ramp | float | 0.4 | Augmentation du coût par salle |
| seuil_combo | int | 12 | Nombre de frappes pour un combo |
| dash_duree | float | 0.4 | Durée du dash en secondes |
| buffer_sprint | float | 0.42 | Buffer de temps pour le sprint |

#### Comportement du héros (BPC_HerosBase.gd)

- **Mouvement** : lecture des touches ZQSD/flèches, `velocity` sur l'axe XZ, `move_and_slide()`.
- **Attaque** : sur Espace, vérifier la zone de frappe (arc devant le héros), appliquer des dégâts à chaque ennemi touché via `prendre_degrats()`.
- **Dash** : sur Maj, vitesse ×3 pendant `dash_duree`, i-frames activées pendant le dash.
- **Souffle** : les compétences coûtent du souffle. Le souffle se régénère lentement (1/s) quand on n'utilise pas de compétence.
- **I-frames** : gérées par `BPC_Stats.tick(delta)`.
- **Dernier effort** : quand PV < 25%, le héros entre en mode "dernier effort" (soin + réduction de dégâts).

### 3.2 Ennemi

**Script** : `BPC_EnnemiBase.gd` (extends CharacterBody3D)
**Fiche** : `FicheEnnemi.gd` (Resource)

#### Props de la fiche (FicheEnnemi.gd)

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| id | String | "" | Identifiant (CRT-XXX) |
| nom | String | "" | Nom affiché |
| categorie | String | "ennemi" | Catégorie |
| PV_Max | int | 100 | PV maximum |
| Vitesse | float | 200.0 | Vitesse de déplacement (unités/s) |
| NoteDifficulte | int | 50 | Note de difficulté |
| PoidsPiscine | int | 1 | Poids dans la génération de salles |
| PoidsPlafondActif | int | 0 | Plafond d'ennemis actifs |
| ModificateurCassureEtourdissement | float | 1.0 | Modificateur de cassure |
| ModificateurEffetRalentissement | float | 1.0 | Modificateur de ralentissement |
| IA_PorteeAggro | float | 900.0 | Portée de détection |
| IA_DelaiEveil | float | 0.0 | Délai avant réveil |
| IA_DelaiSetupIA | float | 0.0 | Délai de setup IA |
| IA_MaxAttaquants | int | 1 | Nombre max d'attaquants simultanés |
| IA_DistanceEntourer | float | 0.0 | Distance d'entourage |
| IA_DistanceEntourerRiposte | float | 0.0 | Distance de riposte |
| IA_IntervalleRafraichissementEntourer | float | 0.0 | Intervalle de rafraîchissement |
| IA_FinSeuilPV | float | 0.0 | Seuil de fin de phase |
| IA_TamponRecul | float | 0.0 | Tampon de recul |
| arsenal | Array[String] | [] | Liste d'IDs d'attaques |

#### Comportement de l'ennemi (BPC_EnnemiBase.gd)

- **IA** : utilise `BPC_PhaseManager` (arbre de décision) + `BPC_AggroSense` (ciblage) + `BPC_WeaponManager` (choix d'arme).
- **Cycle de l'IA** :
  1. `BPC_AggroSense` vérifie si le héros est en portée (`IA_PorteeAggro`).
  2. `BPC_PhaseManager.tick()` retourne l'état : `S_ATTENTE`, `S_MARQUER`, `S_AVANCER`, `S_FRAPPER`, `S_REPLI`, `S_MORT`.
  3. Selon l'état :
     - `S_ATTENTE` : ne rien faire.
     - `S_MARQUER` : cibler le héros.
     - `S_AVANCER` : se déplacer vers le héros.
     - `S_FRAPPER` : attaquer (choisir une attaque de l'arsenal via `BPC_WeaponManager`).
     - `S_REPLI` : s'éloigner du héros.
     - `S_MORT` : désactiver.
- **Dégâts** : `prendre_degrats(montant, source, est_crit)` → `BPC_Stats.appliquer_degrats()`. Si PV ≤ 0 → `mourir()`.
- **Mort** : `est_mort = true`, effets de mort (particules, son), retirer de la scène après un délai.

### 3.3 Boss

**Script** : `BPC_BossBase.gd` (extends CharacterBody3D)
**Fiche** : `FicheBoss.gd` (Resource)

#### Props de la fiche (FicheBoss.gd)

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| id | String | "" | Identifiant (ANO-XXX) |
| nom | String | "" | Nom affiché |
| categorie | String | "boss" | Catégorie |
| PV_Max | int | 5000 | PV maximum |
| Vitesse | float | 500.0 | Vitesse |
| NoteDifficulte | int | 0 | Note de difficulté |
| TamponPV | int | 0 | Tampon PV (absorbe les dégâts) |
| IA_PorteeAggro | float | 0.0 | Portée d'aggro |
| IA_DelaiEveil | float | 0.0 | Délai d'éveil |
| IA_DelaiSetupIA | float | 0.0 | Délai de setup |
| IA_MaxAttaquants | int | 0 | Max attaquants |
| IA_DistanceEntourer | float | 0.0 | Distance d'entourage |
| IA_IntervalleRafraichissementEntourer | float | 0.0 | Intervalle de rafraîchissement |
| IA_FinSeuilPV | float | 0.0 | Seuil de fin de phase |
| phases | Array[Dictionary] | [] | Liste des phases |
| attaques | Array[Dictionary] | [] | Liste des attaques |

#### Structure d'une phase

```json
{
  "id": "ANO-001_Phase1",
  "props": {
    "TypeTransition": "SeuilPV",
    "Seuil": 0.75,
    "DureeAnnonce": 1.5
  }
}
```

**Types de transition** :
- `SeuilPV` : la phase change quand le PV du boss passe sous le seuil.
- `SeuilPVGroupe` : la phase change quand le PV du groupe passe sous le seuil.
- `RencontreAppeleeTerminee` : la phase change quand la rencontre appelée est terminée.

#### Structure d'une attaque

```json
{
  "id": "ANO-001_Melee1",
  "props": {
    "IA.AnnonceDuree": 0.8,
    "IA.Duree": 1.2,
    "Degat": 25,
    "IA.Portee": 200.0
  }
}
```

#### Comportement du boss

- **Phases** : `BPC_PhaseManager` gère la transition entre phases selon le PV.
- **Attaques** : dans chaque phase, le boss choisit une attaque de son arsenal via `BPC_WeaponManager`.
- **Annonce** : avant chaque attaque, le boss fait une animation d'annonce (duree = `IA.AnnonceDuree`).
- **PV groupe** : certains boss ont un `TamponPV` qui absorbe les dégâts avant les PV réels.

### 3.4 Mini-Boss

**Script** : `BPC_BossBase.gd` (même que boss, mais avec fiche `FicheMiniBoss.gd`)
**Fiche** : `FicheMiniBoss.gd` (Resource)

#### Props spécifiques (FicheMiniBoss.gd)

En plus des props de `FicheBoss`, le mini-boss a :

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| IA_MaxAttaquants | int | 1 | Max attaquants |
| IA_DistanceEntourer | float | 0.0 | Distance d'entourage |
| IA_IntervalleRafraichissementEntourer | float | 0.0 | Intervalle de rafraîchissement |
| IA_FinSeuilPV | float | 0.0 | Seuil de fin de phase |
| TamponPV | int | 0 | Tampon PV |

### 3.5 Arme

**Fiche** : `FicheArme.gd` (Resource)

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| id | String | "" | Identifiant (REL-XXX) |
| nom | String | "" | Nom affiché |
| categorie | String | "arme" | Catégorie |
| numero | int | 0 | Numéro |
| props | Dictionary | {} | Props libres (buffs/passifs) |

Les 34 armes sont des buffs/passifs sans données de chaîne dans le graphe. Elles modifient les stats du héros.

### 3.6 Salle

**Fiche** : `FicheSalle.gd` (Resource)

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| nom | String | "" | Nom de la salle |
| types | Array | [] | Types (Combat, MiniBoss, Boss, Shop, Story) |
| delai_apparition | float | 0.5 | Délai avant l'apparition des ennemis |
| delai_deverrouillage | float | 0.4 | Délai avant le déverrouillage de la porte |
| delai_fin_combat | float | 0.2 | Délai après la fin du combat |
| encounters | Array | [] | Liste des encounters |
| issues | Array | [] | Liste des issues (portes) |
| cout_combat | float | 0.0 | Coût du combat |
| cout_vie | int | 0 | Coût en vie |

### 3.7 Types de salles

| Type | Description | Contenu |
|------|-------------|---------|
| Combat | Salle de combat standard | Ennemis randomisés (SpawnPools) |
| MiniBoss | Salle de mini-boss | Mini-boss + ennemis |
| Boss | Salle de boss | Boss final du niveau |
| Shop | Salle de boutique | PNJ marchand |
| PreBoss | Salle avant boss | Ennemis + préparation |
| PostBoss | Salle après boss | Récompenses |
| Story | Salle narrative | PNJ + dialogue |

### 3.8 Niveaux (Biomes)

| ID | Nom | Boss |
|----|-----|------|
| SEC-001 | Erebus | ANO-001 |
| SEC-002 | Tartarus | ANO-002 |
| SEC-003 | Asphodel | ANO-003 |
| SEC-004 | Elysium | ANO-004 |
| SEC-005 | Oceanus | ANO-005 |
| SEC-006 | Phlegethon | ANO-006 |
| SEC-007 | Eryx | ANO-007 |
| SEC-008 | Styx | (Final) |

Chaque niveau a 3 salles : Combat → MiniBoss → Boss.

---

## 4. SYSTÈMES

### 4.1 BPC_Stats (Stats)

**Fichier** : `systemes/BPC_Stats.gd` (extends RefCounted)

Gère : PV, souffle, i-frames, dernier effort, combo.

#### Signaux

| Signal | Paramètres | Description |
|--------|------------|-------------|
| mort | cible: Node | Émis quand la cible meurt |
| frappe_appliquee | cible: Node, degats: int, source: Node, est_crit: bool | Émis quand une frappe est appliquée |

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `appliquer_degrats(montant, source, est_crit) -> int` | Applique des dégâts. Retourne les dégâts réels. |
| `regenerer(delta) -> void` | Régénère le PV et le souffle. |
| `tick(delta) -> void` | Tick des i-frames et du dernier effort. |
| `activer_invuln() -> void` | Active les i-frames. |
| `activer_dernier_effort() -> void` | Active le dernier effort. |

#### Règles

- **I-frames** : si PV < `seuil_invuln × vie_max` ET dégâts >= `degat_min_invuln` → i-frames actives pendant `duree_invuln` secondes. Pendant les i-frames, les dégâts sont 0.
- **Dernier effort** : si PV < 25% ET dernier effort non actif → soin de `dernier_effort_soin × vie_max`, réduction de dégâts de `dernier_effort_modif` pendant `dernier_effort_duree` secondes.
- **Combo** : chaque frappe incremente le combo. Si combo >= `seuil_combo` → bonus de dégâts.

### 4.2 BPC_DegratsPipeline (Pipeline de dégâts)

**Fichier** : `systemes/BPC_DegratsPipeline.gd` (extends RefCounted)

#### Formule

```
degats_reels = (degats_base × modificateur) + additif
Si est_crit : degats_reels × 3
degats_reels = max(1, degats_reels)  # minimum 1 dégât
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `calculer(degrats_base, modificateur, additif, est_crit) -> int` | Calcule les dégâts réels. |

### 4.3 BPC_Invuln (I-frames)

**Fichier** : `systemes/BPC_Invuln.gd` (extends RefCounted)

Gère la fenêtre d'invulnérabilité.

| Méthode | Description |
|---------|-------------|
| `activer(duree) -> void` | Active les i-frames. |
| `est_invuln() -> bool` | Renvoie si les i-frames sont actives. |
| `tick(delta) -> void` | Décrémente le timer. |

### 4.4 BPC_DernierEffort (Dernier effort)

**Fichier** : `systemes/BPC_DernierEffort.gd` (extends RefCounted)

Gère le mode "dernier effort".

| Méthode | Description |
|---------|-------------|
| `activer(soin, duree, modif) -> void` | Active le dernier effort. |
| `est_actif() -> bool` | Renvoie si le dernier effort est actif. |
| `tick(delta) -> void` | Décrémente le timer. |

### 4.5 BPC_DirectorRun (Directeur de run)

**Fichier** : `systemes/BPC_DirectorRun.gd` (extends Node)

Gère la génération de salles et des encounters.

#### Props

| Prop | Type | Description |
|------|------|-------------|
| fiche_heros | FicheHeros | Fiche du héros |
| fiches_ennemis | Array | Liste des fiches d'ennemis |
| fiches_salles | Array | Liste des fiches de salles |
| salle_actuelle | FicheSalle | Salle actuelle |
| run_terminé | bool | Le run est-il terminé ? |

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `demarrer_run() -> void` | Démarre un nouveau run. |
| `salle_suivante() -> void` | Passer à la salle suivante. |
| `terminer_run() -> void` | Termine le run. |
| `calculer_difficulte(profondeur, difficulte_base, ramp) -> int` | Calcule la difficulté d'un encounter. |

#### Logique de génération

1. Choisir un type de salle (Combat, MiniBoss, Boss) selon le niveau.
2. Pour une salle de Combat :
   - Tirer aléatoirement des ennemis depuis les `SpawnPools_LvlXX.json` (pondérés).
   - Nombre d'ennemis : entre `MinTypes` et `MaxTypes`.
   - Cap d'ennemis actifs : `ActiveEnemyCapBase` à `ActiveEnemyCapMax`.
   - Vagues : entre `MinWaves` et `MaxWaves`.
   - Intervalle de spawn : entre `SpawnIntervalMin` et `SpawnIntervalMax`.
3. Pour une salle de MiniBoss :
   - Charger la fiche du mini-boss depuis `FICHES_MINI_BOSSES_V2.json`.
   - Spawn des ennemis de soutien selon `ManualWaveTemplates`.
4. Pour une salle de Boss :
   - Charger la fiche du boss depuis `FICHES_BOSSES_V2.json`.

### 4.6 Spawn d'ennemis

**Positions** : les salles ont des `SpawnPoints` prédéfinis (Marker3D dans la scène). Le spawn choisit un point au hasard parmi les SpawnPoints.

**Contraintes** :
- `SpawnRadiusMin` : distance minimale au héros.
- `SpawnRadius` : rayon de recherche.
- `SpawnAngleMin/Max` : contrainte angulaire.
- `PreSpawnMinPlayerDistance` : distance minimale avant l'activation.

**Algorithme de spawn** :
1. Choisir un SpawnPoint aléatoire.
2. Vérifier la distance au héros (>= `PreSpawnMinPlayerDistance`).
3. Si OK, instancier l'ennemi à cette position.
4. Répéter pour chaque ennemi de la vague.

### 4.7 IA des ennemis

**Arbre de décision à 6 états** (BPC_PhaseManager) :

```
ATTENTE → (cible valide) → MARQUER → (dist > 600) → REPLI
    ↑                                    ↓
    │                              AVANCER → (dist < 200) → FRAPPER
    │                                    ↓
    └────────────────────────────── (mort) ← MORT
```

| État | Condition de sortie | Action |
|------|-------------------|--------|
| ATTENTE | cible valide | → MARQUER |
| MARQUER | dist > 600 | → REPLI |
| MARQUER | dist ≤ 600 | → AVANCER |
| AVANCER | dist < 200 | → FRAPPER |
| FRAPPER | attaque terminée | → AVANCER |
| REPLI | dist < 400 | → MARQUER |
| MORT | — | désactiver |

**BPC_AggroSense** :
- `marquer(cible)` : cibler le héros.
- `en_portee(pos_cible, pos_ennemi)` : vérifier la portée.
- `cible_morte()` : vérifier si la cible est morte.

**BPC_WeaponManager** :
- Choisir une attaque de l'arsenal selon les conditions (PV, distance, cooldown).

---

## 5. DONNÉES

### 5.1 Fiches JSON (source de vérité)

| Fichier | Contenu | Nombre |
|---------|---------|--------|
| `FICHES_ENNEMIS_V2.json` | Ennemis (CRT-001 à CRT-061) | 61 |
| `FICHES_BOSSES_V2.json` | Bosses (ANO-001 à ANO-007) | 7 |
| `FICHES_ARMES_V2.json` | Armes (REL-001 à REL-034) | 34 |
| `FICHES_MINI_BOSSES_V2.json` | Mini-bosses (MIN-001 à MIN-012) | 12 |

### 5.2 Données de rencontres et spawn

| Fichier | Contenu |
|---------|---------|
| `EncounterProfiles.json` | 9 profils de rencontre (difficulty, cap, waves, intervals) + mapping niveau→profil |
| `SpawnPools_Lvl01.json` à `SpawnPools_Lvl08.json` | Pools d'ennemis par niveau (Ref, Weight, Elite) |

#### Structure d'un profil de rencontre

```json
{
  "BaseDifficulty": 30,
  "DepthDifficultyRamp": 10,
  "ActiveEnemyCapBase": 2.3,
  "ActiveEnemyCapDepthRamp": 0.35,
  "ActiveEnemyCapMax": 8,
  "MinTypes": 1,
  "MaxTypes": 2,
  "MaxTypesCap": 4,
  "TypeCountDepthRamp": 0.2,
  "MinWaves": 1,
  "MaxWaves": 3,
  "SpawnIntervalMin": 0.175,
  "SpawnIntervalMax": 0.225
}
```

#### Structure d'un spawn pool

```json
{
  "LevelTag": "Level.Lvl1",
  "Level": "lvl_1",
  "EntryCount": 14,
  "Entries": [
    { "Ref": "Enemy.Lvl1.E001", "Weight": 2, "Elite": false },
    { "Ref": "Enemy.Lvl1.E001", "Weight": 2, "Elite": true }
  ]
}
```

#### Mapping niveau → profil

| Niveau | Profil | Difficulté base | Ramp |
|--------|--------|-----------------|------|
| lvl_1 | GeneratedF | 55 | 15 |
| lvl_2 | GeneratedG | 140 | 40 |
| lvl_3 | GeneratedH | 290 | 82 |
| lvl_4 | GeneratedI | 325 | 105 |
| lvl_5 | GeneratedN | 110 | 25 |
| lvl_6 | GeneratedO | 115 | 35 |
| lvl_7 | GeneratedP | 340 | 90 |
| lvl_8 | null | — | — |

### 5.3 Système d'effets

| Fichier | Contenu |
|---------|---------|
| `DT_EffectRegistry.csv` | Registre de tous les effets (8 types) |

#### Les 8 types d'effets

| Type | Description | Exemple |
|------|-------------|---------|
| `SPEED` | Modificateur de vitesse (0.05 = très lent, 1.27 = très rapide) | `Slow` (0.6), `RushChargeSlow` (1.2) |
| `GRIP` | Modificateur de contrôle (0 = gelé, 1 = normal) | `Rooted` (gelé 0.85s), `ImpactGrip` (0.01) |
| `DAMAGE_OUTPUT` | Modificateur de dégâts infligés | `boss-006-lvl_6SelfBuff` (×2) |
| `DAMAGE_TAKEN` | Modificateur de dégâts subis | `PolymorphDamageTaken` (×1.5), `WetCast` (×1.1) |
| `DAMAGE_OVER_TIME` | Dégâts par seconde | `ElectrifiedPuddle` (8s) |
| `INVULNERABLE` | Invulnérabilité | `SprintGracePeriod` (0.05s), `RushWeaponInvulnerable` (0.16s) |
| `PROJECTILE_DEFENSE` | Défense contre les projectiles | — |
| `TAG` | Tag gameplay (pour les conditions) | — |

#### Props d'un effet

| Prop | Type | Description |
|------|------|-------------|
| `EffectId` | String | Identifiant unique de l'effet |
| `Type` | String | Type d'effet (SPEED, GRIP, DAMAGE_OUTPUT, etc.) |
| `Duration` | float | Durée en secondes |
| `DurationFrames` | int | Durée en frames (alternative à Duration) |
| `Modifier` | float | Valeur du modificateur |
| `Trigger` | String | Déclencheur (Charging, Fire, FireEnd, null) |
| `HaltOnEnd` | bool | Arrêt complet à la fin |
| `Cancelable` | bool | Peut être annulé |
| `CanAffectInvulnerable` | bool | Affecte les cibles invulnérables |
| `Active` | bool | Actif par défaut |
| `DisableAttack` | bool | Désactive les attaques |
| `DisableMove` | bool | Désactive les déplacements |
| `NoUnitCollision` | bool | Pas de collision avec les unités |

### 5.4 Paramètres de spawn

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `AI.SpawnRadius` | Rayon de recherche du point de spawn | 900 |
| `AI.SpawnRadiusMin` | Distance minimale au héros | 0 |
| `AI.SpawnRadiusMax` | Distance maximale au héros | — |
| `SpawnAngleMin` | Borne basse de l'angle de spawn | — |
| `SpawnAngleMax` | Borne haute de l'angle de spawn | — |
| `SpawnOffset` | Décalage de position | — |
| `SpawnIntervalMin` | Intervalle minimum entre deux spawns | — |
| `SpawnIntervalMax` | Intervalle maximum entre deux spawns | — |
| `AI.SpawnsPerBurstMin` | Nombre min d'unités par salve | — |
| `AI.SpawnsPerBurstMax` | Nombre max d'unités par salve | — |
| `AI.SpawnBurstDelay` | Délai entre deux salves | — |
| `AI.SpawnRate` | Taux de spawn (probabilité) | 0.3 |
| `AI.Spread` | Dispersion angulaire des tirs (degrés) | — |

### 5.5 Paramètres d'attaque

| Paramètre | Description |
|-----------|-------------|
| `AI.PreAttackDuration` | Durée de l'annonce avant l'attaque |
| `AI.PreAttackEndDuration` | Durée de fin d'annonce |
| `AI.FireDuration` | Durée du tir |
| `AI.PostAttackDuration` | Durée après l'attaque |
| `AI.PostAttackCooldown` | Cooldown après l'attaque |
| `AI.AttackDistance` | Distance d'attaque |
| `AI.AttackDistanceScaleY` | Échelle Y de la distance d'attaque |
| `AI.FireProjectileStartDelay` | Délai avant le premier projectile |
| `AI.NumProjectiles` | Nombre de projectiles |
| `AI.Spread` | Dispersion angulaire (degrés) |
| `AI.ProjectileAngleInterval` | Intervalle angulaire entre projectiles |
| `AI.ProjectileInterval` | Intervalle entre projectiles |
| `AI.FireInterval` | Intervalle entre tirs |
| `AI.FireTicks` | Nombre de ticks de tir |
| `AI.FireSelfVelocity` | Vitesse de recul du tireur |
| `AI.FireRotationDampening` | Amortissement de rotation pendant le tir |
| `AI.PreAttackRotationDampening` | Amortissement de rotation pendant l'annonce |
| `AI.PreAttackAnimationSpeed` | Vitesse d'animation de l'annonce |
| `AI.PreAttackEndFlashFraction` | Fraction de flash en fin d'annonce |
| `AI.LoSBuffer` | Buffer de line-of-sight |
| `AI.BarrelLength` | Longueur du canon |
| `AI.MoveWithinRangeTimeout` | Timeout pour se déplacer dans la portée |
| `Damage` | Dégâts |
| `DamageRadius` | Rayon des dégâts |
| `Range` | Portée |
| `Cooldown` | Cooldown |

### 5.2 Format d'une fiche ennemie

```json
{
  "id": "CRT-001",
  "nom": "Auto-Blinder",
  "categorie": "ennemi",
  "PV_Max": 150,
  "Vitesse": 200.0,
  "NoteDifficulte": 50,
  "PoidsPiscine": 1,
  "PoidsPlafondActif": 0,
  "ModificateurCassureEtourdissement": 1.0,
  "ModificateurEffetRalentissement": 1.0,
  "IA_PorteeAggro": 900.0,
  "IA_DelaiEveil": 0.0,
  "IA_DelaiSetupIA": 0.0,
  "IA_MaxAttaquants": 1,
  "IA_DistanceEntourer": 0.0,
  "IA_DistanceEntourerRiposte": 0.0,
  "IA_IntervalleRafraichissementEntourer": 0.0,
  "IA_FinSeuilPV": 0.0,
  "IA_TamponRecul": 0.0,
  "arsenal": ["CRT-001_Melee1", "CRT-001_Ranged1"]
}
```

### 5.3 Format d'une fiche boss

```json
{
  "id": "ANO-001",
  "nom": "Cyara",
  "categorie": "boss",
  "PV_Max": 6550,
  "Vitesse": 500.0,
  "NoteDifficulte": 100,
  "TamponPV": 0,
  "IA_PorteeAggro": 0.0,
  "IA_DelaiEveil": 0.0,
  "IA_DelaiSetupIA": 0.0,
  "IA_MaxAttaquants": 0,
  "IA_DistanceEntourer": 0.0,
  "IA_IntervalleRafraichissementEntourer": 0.0,
  "IA_FinSeuilPV": 0.0,
  "phases": [
    {
      "id": "ANO-001_Phase1",
      "props": { "TypeTransition": "SeuilPV", "Seuil": 0.75 }
    },
    {
      "id": "ANO-001_Phase2",
      "props": { "TypeTransition": "SeuilPV", "Seuil": 0.4 }
    }
  ],
  "attaques": [
    {
      "id": "ANO-001_Melee1",
      "props": { "IA.AnnonceDuree": 0.8, "IA.Duree": 1.2, "Degat": 25 }
    },
    {
      "id": "ANO-001_Ranged1",
      "props": { "IA.AnnonceDuree": 1.0, "IA.Duree": 2.0, "Degat": 15 }
    }
  ]
}
```

### 5.4 Format d'une fiche arme

```json
{
  "id": "REL-001",
  "nom": "Lame de Cyara",
  "categorie": "arme",
  "numero": 1,
  "props": {}
}
```

### 5.5 Format d'une fiche mini-boss

Même format que le boss, avec `categorie: "mini-boss"`.

### 5.6 Fiches .tres (Godot Resources)

Les 114 fiches sont converties en fichiers `.tres` dans `donnees/` :
- 61 × `CRT-XXX.tres`
- 7 × `ANO-XXX.tres`
- 34 × `REL-XXX.tres`
- 12 × `MIN-XXX.tres`

Chaque `.tres` référence le script `.gd` correspondant (FicheEnnemi, FicheBoss, FicheArme, FicheMiniBoss).

### 5.7 Mapping de renommage

**Fichier** : `MAPPING_SPACE_DRACULA.json` (371 tokens)

Mappe chaque token Hades II original vers son équivalent Space Dracula :

```json
{
  "Aphrodite": { "nom_sd": "ENT-007", "categorie": "dieu", "nom_affiche": "Aphrodite" },
  "AutomatonBeamer": { "nom_sd": "CRT-040", "categorie": "ennemi", "nom_affiche": "Auto-Watcher" },
  "BiomeB": { "nom_sd": "SEC-008", "categorie": "niveau", "nom_affiche": "Asphodel" }
}
```

---

## 6. RÈGLES DU MOTEUR

### 6.1 Cycle de vie d'une salle

```
ATTENTE → (délai_apparition) → COMBAT → (tous ennemis morts) → COMBAT_FINI → (délai_fin_combat) → VERROUILLEE
```

- **ATTENTE** : les ennemis apparaissent après `delai_apparition` secondes.
- **COMBAT** : le combat est en cours. La porte est verrouillée.
- **COMBAT_FINI** : tous les ennemis sont morts. La porte se déverrouille après `delai_deverrouillage`.
- **VERROUILLEE** : la salle est terminée. Le joueur peut passer à la salle suivante.

### 6.2 Cycle de vie d'un ennemi

```
SPAWN → ATTENTE → MARQUER → AVANCER → FRAPPER → (mort) → MORT
```

- **SPAWN** : l'ennemi apparaît dans un SpawnPoint.
- **ATTENTE** : l'ennemi attend (délai d'éveil).
- **MARQUER** : l'ennemi cible le héros.
- **AVANCER** : l'ennemi se déplace vers le héros.
- **FRAPPER** : l'ennemi attaque.
- **MORT** : l'ennemi meurt, effets de mort, retrait de la scène.

### 6.3 Cycle de vie d'un boss

```
SPAWN → PHASE_1 → (seuil PV) → PHASE_2 → ... → PHASE_N → MORT
```

- Chaque phase a un seuil de PV. Quand le PV passe sous le seuil, la phase change.
- Dans chaque phase, le boss choisit des attaques de son arsenal.
- Le boss a une animation d'annonce avant chaque attaque.

### 6.4 Dégâts

```
degats_reels = (degats_base × modificateur) + additif
Si est_crit : degats_reels × 3
degats_reels = max(1, degats_reels)
```

### 6.5 I-frames

- Activées quand PV < `seuil_invuln × vie_max` ET dégâts >= `degat_min_invuln`.
- Durée : `duree_invuln` secondes.
- Pendant les i-frames, les dégâts sont 0.

### 6.6 Dernier effort

- Activé quand PV < 25% ET dernier effort non actif.
- Soin : `dernier_effort_soin × vie_max`.
- Réduction de dégâts : `dernier_effort_modif` pendant `dernier_effort_duree` secondes.

---

## 7. CONSIGNES DE CODAGE

### 7.1 Langue

- **GDScript** pour le code Godot.
- **Python** pour les outils de génération.
- **JSON** pour les données.

### 7.2 Conventions

- Les noms de variables et de fonctions sont en **français**.
- Les noms de fichiers sont en **français** ou en **anglais** (selon le contexte).
- Les commentaires sont en **français**.

### 7.3 Types

- Toujours utiliser le typage statique : `var x: int = 5`, `func f(a: int) -> int:`.
- Les Resources sont des `class_name` qui extends `Resource`.

### 7.4 Signaux

- Les signaux sont déclarés avec `signal nom(param: Type)`.
- Les signaux sont émis avec `emit_signal("nom", param)` ou `nom.emit(param)`.

### 7.5 Scènes

- Les scènes `.tscn` sont créées dans l'éditeur Godot.
- Les scripts `.gd` sont attachés aux nœuds dans les scènes.

### 7.6 Tests

- Les tests sont des scripts `SceneTree` qui peuvent être exécutés headless :
  ```bash
  D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestOracles.gd
  ```

### 7.7 Génération des fiches

- Les fiches sont générées depuis la carte Hades II via des scripts Python :
  ```bash
  python -X utf8 tools/generer_fiches_v2.py      # Ennemis + Bosses
  python -X utf8 tools/generer_fiches_armes.py   # Armes
  python -X utf8 tools/verifier_tokens_sd.py     # Vérification des tokens
  ```

### 7.8 Interdits

- **Ne pas** utiliser de tokens Hades II originaux dans le code ou les données.
- **Ne pas** commit les fichiers du repo sans autorisation explicite.
- **Ne pas** supprimer les fichiers de données existants sans vérification.

---

## 8. CE QUI EST FAIT

### 8.1 Données

- [x] 114 fiches .tres générées et vérifiées (61 CRT + 7 ANO + 34 REL + 12 MIN)
- [x] 4 fiches JSON v2 (ennemis, bosses, armes, mini-bosses)
- [x] Mapping de renommage (371 tokens)
- [x] Organigramme complet (1300 lignes)

### 8.2 Systèmes

- [x] BPC_Stats (PV, souffle, i-frames, dernier effort, combo)
- [x] BPC_DegratsPipeline (pipeline de dégâts)
- [x] BPC_Invuln (i-frames)
- [x] BPC_DernierEffort (dernier effort)
- [x] BPC_DirectorRun (directeur de run)

### 8.3 Acteurs

- [x] BPC_HerosBase.gd (squelette, pas de mouvement)
- [x] BPC_EnnemiBase.gd (squelette, pas d'IA)
- [x] BPC_SalleBase.gd (machine à états, pas de spawn)

### 8.4 IA

- [x] BPC_AggroSense.gd (ciblage)
- [x] BPC_PhaseManager.gd (arbre de décision)
- [x] BPC_WeaponManager.gd (choix d'arme)

### 8.5 Tests

- [x] 6 tests Godot headless passent

---

## 9. CE QUI RESTE À FAIRE

### 9.1 Données

- [ ] Générer `FICHES_SALLES_V2.json` depuis `EncounterProfiles.json` + `SpawnPools_Lvl01..08.json`
- [ ] Convertir en `.tres`

### 9.2 Code Godot — Boucle de jeu

- [ ] Mouvement du héros (clavier + collision) dans `BPC_HerosBase.gd`
- [ ] Attaque du héros (arc de frappe, dégâts)
- [ ] Dash du héros
- [ ] Intégration de l'IA ennemie (BPC_AggroSense, BPC_PhaseManager, BPC_WeaponManager) dans `BPC_EnnemiBase.gd`
- [ ] Boss : gestion des phases dans `BPC_BossBase.gd`
- [ ] Créer les scènes `.tscn` (Heros, Ennemi, Boss, Salle, Jeu)
- [ ] Camera top-down
- [ ] HUD (barre de PV, souffle, combo)
- [ ] Spawn d'ennemis dans les salles
- [ ] Boucle de jeu complète (run → niveaux → salles → rencontres → mort/victoire)

### 9.3 Tests de gameplay

- [ ] Test de combat complet avec les fiches chargées
- [ ] Test de la génération de run avec les salles
- [ ] Test du cycle de vie d'une salle

---

## 10. RÉFÉRENCES

- `space_dracula/ORGANOGRAPHE_COMPLET.md` : Organigramme complet du jeu (1300 lignes, 9 sections)
- `space_dracula/fiches/FICHES_ENNEMIS_V2.json` : 61 ennemis
- `space_dracula/fiches/FICHES_BOSSES_V2.json` : 7 bosses, 96 attaques, 30 phases
- `space_dracula/fiches/FICHES_ARMES_V2.json` : 34 armes
- `space_dracula/fiches/FICHES_MINI_BOSSES_V2.json` : 12 mini-bosses, 60 attaques
- `space_dracula/donnees/MAPPING_SPACE_DRACULA.json` : 371 tokens renommés
- `ETAT_CONSTRUCTION.md` : État actuel de la construction
- `PLAN_CONSTRUCTION_GODOT.md` : Plan de construction Godot
