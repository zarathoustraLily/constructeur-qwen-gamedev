# ORGANIGRAMME COMPLET - Space Dracula

Généré automatiquement depuis le graphe de données source (16706 nœuds, 10531 arêtes)

---

## 1. STRUCTURE GÉNÉRALE

```
RUN (Course)
  │
  ├─→ NIVEAU 1 (Biome A)
  │     ├─→ Salle 1 (Type: Combat)
  │     │     └─→ Rencontre → Vagues → Ennemis
  │     ├─→ Salle 2 (Type: Mini-Boss)
  │     │     └─→ Mini-Boss + Ennemis
  │     └─→ Salle 3 (Type: Boss)
  │           └─→ Boss (Phases → Armes)
  │
  ├─→ NIVEAU 2 (Biome B)
  │     └─→ ...
  │
  └─→ NIVEAU 8 (Biome H)
        └─→ Boss Final
```

---

## 2. ENTITÉS PAR CATÉGORIE

### Ennemis (252 entités)

- 1_BaseEnemy
- CRT-062
- enemi-003-lvl_1
- enemi-003-lvl_1_Elite
- enemi-035-lvl_6
- enemi-035-lvl_6_Elite
- enemi-002-lvl_1
- enemi-002-lvl_1_Elite
- enemi-011-lvl_2
- enemi-011-lvl_2_Elite
- ... et 242 autres

### PNJ (41 entités)

- BaseNPC
- NPC_boss-001-lvl_1_01
- NPC_boss-001-lvl_1_Story_01
- NPC_boss-004-lvl_4_01
- NPC_boss-004-lvl_4_Story_01
- NPC_pnj-017_01
- NPC_pnj-006_01
- NPC_pnj-015_01
- NPC_boss-006-lvl_6_01
- NPC_pnj-013_01
- ... et 31 autres

### Héros (4 entités)

- 1_BasePlayerUnit
- _PlayerUnit
- Playerpnj-008Flashback
- PlayerMelFlashback

### Armes du joueur (72 entités)

- 1_BaseDamagingWeapon
- arme-008
- arme-024
- arme-014
- arme-002
- arme-003
- arme-005
- 1_BaseMagicWeapon
- arme-009
- arme-006
- ... et 62 autres

### Armes ennemies (3 entités)

- 1_BaseEnemyMagicWeapon
- 1_BaseTrapWeapon
- MIN-004_Ram

### Projectiles joueur (155 entités)

- 1_BaseDamagingProjectile
- ProjectileBlink
- ProjectileCast
- dieu-004NarrowCast
- ProjectileCastLob
- ProjectileCastFireball
- ProjectileSprintBall
- ProjectileCastpnj-008
- dieu-004Cast
- dieu-004SingleCastStrike
- ... et 145 autres

### Projectiles ennemis (551 entités)

- 1_BaseEnemyMagicProjectile
- 1_BaseTrapProjectile
- SummonDeathWeapon
- miniboss-004-lvl_2Eff
- MIN-004_A03
- miniboss-004-lvl_2Eff
- BaseCollisionWeapon
- LavaPuddleLarge
- DartTrapWeapon
- ExplosiveBlast
- ... et 541 autres

---

## 3. RELATIONS

### inherits (8603 arêtes)
*Héritage (classe parent → classe enfant)*

- `1_BaseInvulnerableImpassableObstacle` → `1_BaseInvulnerableObstacle`
- `1_BaseDecalObstacle` → `1_BaseInvulnerableObstacle`
- `1_BaseFlyingDecalObstacle` → `1_BaseInvulnerableObstacle`
- `1_BaseInvulnerableLowObstacle` → `1_BaseInvulnerableObstacle`
- `1_BaseInvulnerablePassableObstacle` → `1_BaseInvulnerableObstacle`
- ... et 8598 autres

### spawns (115 arêtes)
*Apparition (rencontre → ennemi)*

- `lua:A??` → `lua:enemi-002-lvl_1`
- `lua:A??` → `lua:enemi-004-lvl_1`
- `lua:A??` → `lua:enemi-005-lvl_1`
- `lua:A??` → `lua:enemi-006-lvl_1_Elite`
- `lua:A??` → `lua:enemi-001-lvl_1`
- ... et 110 autres

### unit_uses_weapon (519 arêtes)
*Utilisation d'arme (unité → arme)*

- `lua:IsNeutral` → `lua:EliteEffRipple`
- `lua:IsNeutral` → `lua:Devotiondieu-001`
- `lua:IsNeutral` → `lua:Devotiondieu-003`
- `lua:IsNeutral` → `lua:Devotiondieu-006`
- `lua:IsNeutral` → `lua:Devotiondieu-004`
- ... et 514 autres

### weapon_chain (48 arêtes)
*Chaîne d'armes (arme → arme suivante)*

- `arme-008` → `arme-024`
- `arme-009` → `arme-009Arm`
- `arme-009Arm` → `arme-009`
- `arme-009Arm` → `arme-009`
- `arme-009Vacuum` → `arme-009`
- ... et 43 autres

### room_has_encounter (119 arêtes)
*Salle a rencontre (salle → rencontre)*

- `lua:BaseRoom` → `lua:Empty`
- `lua:BaseRoom` → `lua:Empty`
- `lua:BaseRoom` → `lua:Empty`
- `lua:BaseRoom` → `lua:Empty`
- `lua:BaseRoom` → `lua:Empty`
- ... et 114 autres

### phase_of (30 arêtes)
*Phase de (phase → boss)*

- `boss-001-lvl_1Stage1` → `boss-001-lvl_1` (≤66% PV)
- `boss-001-lvl_1Stage2` → `boss-001-lvl_1` (fin de sous-encounter)
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1` (≤33% PV)
- `boss-001-lvl_1Stage4` → `boss-001-lvl_1` (fin de sous-encounter)
- `boss-001-lvl_1Stage5` → `boss-001-lvl_1` (≤0% PV)
- ... et 25 autres

### phase_equips (90 arêtes)
*Phase équipe (phase → arme)*

- `boss-001-lvl_1Stage3` → `boss-001-lvl_1Eff1`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1Eff`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1Split2`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1EffRing`
- `boss-001-lvl_1Stage4` → `boss-001-lvl_1Eff`
- ... et 85 autres

### applies_effect (564 arêtes)
*Applique effet (action → effet)*

- `boss-002-lvl_2Notes` → `HeroOnHitStun`
- `arme-008` → `EffWeaponInvulnerable` (INVULNERABLE)
- `arme-008` → `EffWeaponImmuneToForce`
- `arme-008` → `EffAttackQueue`
- `arme-008` → `EffWeaponInvulnerableCharge` (INVULNERABLE)
- ... et 559 autres

### fires_projectile (75 arêtes)
*Tire projectile (arme → projectile)*

- `enemi-056-lvl_8Melee` → `enemi-056-lvl_8Melee`
- `enemi-025-lvl_4Melee` → `enemi-025-lvl_4Melee`
- `MIN-004_Ram` → `MIN-004_Ram`
- `Devotiondieu-003` → `Devotiondieu-003`
- `BaseCollisionWeapon` → `BaseCollisionWeapon`
- ... et 70 autres

### plays_anim (366 arêtes)
*Joue animation (objet → animation)*

- `VisibilityButton` → `GUI\Pause\PauseMenuHighlight` (SelectedGraphic)
- `VisibilityButton` → `GUI\Grey_Node` (SelectedGraphic)
- `enemi-014-lvl_2Lob` → `LobWarningDecalIris` (ReticleGraphic)
- `enemi-042-lvl_7FireLob` → `BlastWarningDecal` (ReticleGraphic)
- `boss-005-lvl_5StompDebris` → `BlastWarningDecal` (ReticleGraphic)
- ... et 361 autres

### uses_enemy_set (2 arêtes)
*Utilise set ennemi (rencontre → set)*

- `rencontre_ouverture_n5` → `CRT-029`
- `rencontre_ouverture_n5` → `CRT-027`

---

## 4. BOSS ET PHASES

### Boss détectés: 7

#### boss-001-lvl_1

Phases: 5
- Phase: `boss-001-lvl_1Stage1`
- Phase: `boss-001-lvl_1Stage2`
- Phase: `boss-001-lvl_1Stage3`
  - Armes: boss-001-lvl_1Eff1, boss-001-lvl_1Eff, boss-001-lvl_1Split2, boss-001-lvl_1EffRing
- Phase: `boss-001-lvl_1Stage4`
  - Armes: boss-001-lvl_1Eff
- Phase: `boss-001-lvl_1Stage5`
  - Armes: boss-001-lvl_1Eff, boss-001-lvl_1Split3, boss-001-lvl_1EffRing, boss-001-lvl_1EffCone

#### boss-002-lvl_2

Phases: 5
- Phase: `boss-002-lvl_2Stage1`
- Phase: `boss-002-lvl_2Stage2`
- Phase: `boss-002-lvl_2Stage3`
  - Armes: boss-002-lvl_2Belt, boss-002-lvl_2Whip, boss-002-lvl_2Eff, boss-002-lvl_2Notes, boss-002-lvl_2EffPassive ... (+1)
- Phase: `boss-002-lvl_2Stage4`
- Phase: `boss-002-lvl_2Stage5`
  - Armes: boss-002-lvl_2EffFinisher, boss-002-lvl_2EffFinisherHold

#### boss-003-lvl_3

Phases: 3
- Phase: `boss-003-lvl_3Stage1`
- Phase: `boss-003-lvl_3Stage2`
  - Armes: boss-003-lvl_3Hide
- Phase: `boss-003-lvl_3Stage3`
  - Armes: boss-003-lvl_3Eff, boss-003-lvl_3Eff, boss-003-lvl_3Eff, boss-003-lvl_3Eff, boss-003-lvl_3_C_Breath ... (+3)

#### boss-004-lvl_4

Phases: 6
- Phase: `boss-004-lvl_4Stage1`
- Phase: `boss-004-lvl_4Stage2`
- Phase: `boss-004-lvl_4Stage3`
  - Armes: boss-004-lvl_4Eff, boss-004-lvl_4Eff, boss-004-lvl_4Eff, boss-004-lvl_4EffSelector, boss-004-lvl_4Eff ... (+1)
- Phase: `boss-004-lvl_4Stage4`
- Phase: `boss-004-lvl_4Stage5`
  - Armes: boss-004-lvl_4Eff, boss-004-lvl_4Eff, boss-004-lvl_4Eff, boss-004-lvl_4Eff, boss-004-lvl_4Eff2 ... (+4)
- Phase: `boss-004-lvl_4Stage6`
  - Armes: boss-004-lvl_4EffSelector, boss-004-lvl_4Eff, boss-004-lvl_4Eff2, boss-004-lvl_4Eff, boss-004-lvl_4Eff2 ... (+1)

#### boss-005-lvl_5

Phases: 3
- Phase: `boss-005-lvl_5Stage1`
- Phase: `boss-005-lvl_5Stage2`
  - Armes: boss-005-lvl_5Leap, boss-005-lvl_5March, boss-005-lvl_5PlayerGrab, boss-005-lvl_5Grab
- Phase: `boss-005-lvl_5Stage3`
  - Armes: boss-005-lvl_5Stomp, boss-005-lvl_5Leap, boss-005-lvl_5Eff, boss-005-lvl_5Eff, boss-005-lvl_5March

#### boss-006-lvl_6

Phases: 5
- Phase: `boss-006-lvl_6Stage1`
- Phase: `boss-006-lvl_6Stage2`
  - Armes: boss-006-lvl_6SpreadFire, boss-006-lvl_6GrenadeCluster01, boss-006-lvl_6Eff, boss-006-lvl_6FlyUp, boss-006-lvl_6Eff
- Phase: `boss-006-lvl_6Stage3`
  - Armes: boss-006-lvl_6SpreadFire, boss-006-lvl_6GrenadeCluster02, boss-006-lvl_6Eff, boss-006-lvl_6FlyUp, boss-006-lvl_6Eff
- Phase: `boss-006-lvl_6Stage4`
  - Armes: boss-006-lvl_6RelocateStrike, boss-006-lvl_6GrenadeCluster03, boss-006-lvl_6Eff, boss-006-lvl_6FlyUp, boss-006-lvl_6Eff2
- Phase: `boss-006-lvl_6Stage5`
  - Armes: boss-006-lvl_6RelocateStrike, boss-006-lvl_6FlyUp, boss-006-lvl_6Eff2, boss-006-lvl_6Snipe3

#### boss-007-lvl_7

Phases: 3
- Phase: `boss-007-lvl_7Stage1`
- Phase: `boss-007-lvl_7Stage2`
  - Armes: boss-007-lvl_7Eff_P2_Starter, boss-007-lvl_7Eff_P2_Starter, boss-007-lvl_7Eff_P2_Starter, boss-007-lvl_7Eff_P2_Starter, boss-007-lvl_7EffBackward ... (+3)
- Phase: `boss-007-lvl_7Stage3`
  - Armes: boss-007-lvl_7Eff_P3_Starter, boss-007-lvl_7Eff_P3_Starter, boss-007-lvl_7Eff_P3_Starter, boss-007-lvl_7Eff_P3_Starter, boss-007-lvl_7EffBackward ... (+2)

---

## 5. ENNEMIS ET ARMES

### Unités avec armes: 68

#### lua:BaseTrap
Armes (28):
- lua:RootsAoE
- lua:SafeZone
- lua:CRT-063
- lua:FloodTrapWeapon
- lua:SteamTrapWeapon
- lua:Eff
- lua:SpikeTrapClockwork
- lua:BeamTrap
- lua:SlowPuddles
- lua:PuddleTileWeapon
- ... et 18 autres

#### lua:CRT-064
Armes (4):
- lua:CRT-064_Vacuum
- lua:CRT-064_Nova
- lua:CRT-064_Vacuum_Elite
- lua:CRT-064_Nova_Elite

#### lua:CRT-065
Armes (1):
- lua:CRT-065_Ram

#### lua:CRT-066
Armes (2):
- lua:CRT-066_Cast
- lua:CRT-066_Cast_Elite

#### lua:MIN-004
Armes (5):
- lua:MIN-004_A03
- lua:MIN-004_Eff
- lua:MIN-004_A03_Miniboss
- lua:MIN-004_A??
- lua:MIN-004_A??

#### lua:CRT-049
Armes (3):
- lua:CRT-049Chase
- lua:CRT-049_Ram
- lua:CRT-049_LargeRam

#### lua:A??
Armes (2):
- lua:A??
- lua:A??

#### lua:IsNeutral
Armes (18):
- lua:EliteEffRipple
- lua:Devotiondieu-001
- lua:Devotiondieu-003
- lua:Devotiondieu-006
- lua:Devotiondieu-004
- lua:Devotiondieu-002
- lua:Devotiondieu-005
- lua:Devotiondieu-007
- lua:Devotiondieu-008
- lua:LightningStorm
- ... et 8 autres

#### lua:LightRanged
Armes (4):
- lua:LightRangedBolt
- lua:LightRangedBolt_Elite
- lua:SpreadShotBolt
- lua:SpreadShotBolt_Elite

#### lua:A??
Armes (4):
- lua:A??
- lua:A??
- lua:A??
- lua:A??

#### lua:Sheep
Armes (6):
- lua:SheepRam
- lua:SheepExplode
- lua:SheepSickSkip
- lua:SheepSickAura
- lua:SheepSkip
- lua:SheepSkip

#### lua:ANO-001_A??
Armes (11):
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- lua:ANO-001_A??
- ... et 1 autres

#### lua:ANO-002_A??
Armes (11):
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- lua:ANO-002_A??
- ... et 1 autres

#### lua:ANO-003_A??
Armes (13):
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- lua:ANO-003_A??
- ... et 3 autres

#### lua:ANO-004_A??
Armes (20):
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- lua:ANO-004_A??
- ... et 10 autres

#### lua:ANO-005_A??
Armes (11):
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- lua:ANO-005_A??
- ... et 1 autres

#### lua:ANO-006_A??
Armes (11):
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- lua:ANO-006_A??
- ... et 1 autres

#### lua:ANO-007_A??
Armes (15):
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- lua:ANO-007_A??
- ... et 5 autres

#### lua:CRT-001_A??
Armes (2):
- lua:CRT-001_A??
- lua:CRT-001_A??

#### lua:CRT-002_A??
Armes (5):
- lua:CRT-002_A??
- lua:CRT-002_A??
- lua:CRT-002_A??
- lua:CRT-002_A??
- lua:CRT-002_A??

#### lua:CRT-003_A??
Armes (4):
- lua:CRT-003_A??
- lua:CRT-003_A??
- lua:CRT-035_A??
- lua:CRT-035_A??

#### lua:CRT-004_A??
Armes (3):
- lua:CRT-004_A??
- lua:CRT-004_A??
- lua:CRT-004_A??

#### lua:CRT-005_A??
Armes (3):
- lua:CRT-005_A??
- lua:CRT-005_A??
- lua:CRT-005_A??

#### lua:CRT-006_A??
Armes (4):
- lua:CRT-006_A??
- lua:CRT-006_A??
- lua:CRT-006_A??
- lua:CRT-006_A??

#### lua:CRT-007_A??
Armes (2):
- lua:CRT-007_A??
- lua:CRT-007_A??

#### lua:CRT-009_A??
Armes (2):
- lua:CRT-056_Impale
- lua:CRT-056_Impale_Elite

#### lua:CRT-010_A??
Armes (2):
- lua:CRT-010_A??
- lua:CRT-010_A??

#### lua:CRT-013_A??
Armes (8):
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??
- lua:CRT-013_A??

#### lua:CRT-014_A??
Armes (17):
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- lua:CRT-014_A??
- ... et 7 autres

#### lua:CRT-015_A??
Armes (4):
- lua:CRT-015_A??
- lua:CRT-015_A??
- lua:CRT-015_A??
- lua:CRT-015_A??

#### lua:CRT-017_A??
Armes (9):
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??
- lua:CRT-017_A??

#### lua:CRT-018_A??
Armes (6):
- lua:CRT-018_A??
- lua:CRT-018_A??
- lua:CRT-018_A??
- lua:CRT-018_A??
- lua:CRT-018_A??
- lua:CRT-018_A??

#### lua:CRT-019_A??
Armes (4):
- lua:CRT-019_A??
- lua:CRT-019_A??
- lua:CRT-019_A??
- lua:CRT-019_A??

#### lua:CRT-020_A??
Armes (14):
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- lua:CRT-020_A??
- ... et 4 autres

#### lua:CRT-021_A??
Armes (4):
- lua:CRT-021_A01
- lua:CRT-021_A03
- lua:CRT-021_A03_Elite
- lua:CRT-021_A01_Elite

#### lua:CRT-022_A??
Armes (6):
- lua:CRT-022_A??
- lua:CRT-022_A??
- lua:CRT-022_A??
- lua:CRT-022_A??
- lua:CRT-022_A??
- lua:CRT-022_A??

#### lua:CRT-023_A??
Armes (25):
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- lua:CRT-023_A??
- ... et 15 autres

#### lua:CRT-024_A??
Armes (11):
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- lua:CRT-024_A??
- ... et 1 autres

#### lua:CRT-026_A??
Armes (2):
- lua:CRT-026_A??
- lua:CRT-026_A??

#### lua:CRT-027_A??
Armes (2):
- lua:CRT-027_A??
- lua:CRT-027_A??

#### lua:CRT-028_A??
Armes (5):
- lua:CRT-028_A??
- lua:CRT-028_A??
- lua:CRT-028_A??
- lua:CRT-028_A??
- lua:CRT-028_A??

#### lua:CRT-029_A??
Armes (6):
- lua:CRT-029_A??
- lua:CRT-029_A??
- lua:CRT-029_A??
- lua:CRT-029_A??
- lua:CRT-048_A??
- lua:CRT-048_A??

#### lua:CRT-030_A??
Armes (8):
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??
- lua:CRT-030_A??

#### lua:CRT-031_A??
Armes (4):
- lua:CRT-031_A??
- lua:CRT-031_A??
- lua:CRT-031_A??
- lua:CRT-031_A??

#### lua:CRT-032_A??
Armes (4):
- lua:CRT-032_A??
- lua:CRT-032_A??
- lua:CRT-032_A??
- lua:CRT-032_A??

#### lua:CRT-033_A??
Armes (9):
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??
- lua:CRT-033_A??

#### lua:CRT-034_A??
Armes (22):
- lua:HarpySlice
- lua:HarpyFlap
- lua:HarpyEffRight
- lua:HarpyEffLeft
- lua:HarpySlice
- lua:HarpyFlap_Elite
- lua:HarpyEffRight
- lua:HarpyEffLeft
- lua:HarpySlice2
- lua:HarpyFlapFast
- ... et 12 autres

#### lua:CRT-036_A??
Armes (4):
- lua:CRT-036_A??
- lua:CRT-036_A??
- lua:CRT-036_A??
- lua:CRT-036_A??

#### lua:CRT-037_A??
Armes (4):
- lua:CRT-037_A??
- lua:CRT-037_A??
- lua:CRT-037_A??
- lua:CRT-037_A??

#### lua:CRT-038_A??
Armes (2):
- lua:CRT-038_A??
- lua:CRT-038_A??

#### lua:CRT-039_A??
Armes (4):
- lua:CRT-039_A??
- lua:CRT-039_A??
- lua:CRT-039_A??
- lua:CRT-039_A??

#### lua:CRT-040_A??
Armes (6):
- lua:AutomatonBeamForward
- lua:AutomatonBeamForward
- lua:AutomatonBeamForward
- lua:CRT-040_A??
- lua:AutomatonBeamForward_Elite
- lua:CRT-040_A??

#### lua:CRT-041_A??
Armes (6):
- lua:CRT-041_A??
- lua:CRT-041_A??
- lua:CRT-041_A??
- lua:CRT-041_A??
- lua:CRT-041_A??
- lua:CRT-041_A??

#### lua:CRT-042_A??
Armes (16):
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- lua:CRT-042_A??
- ... et 6 autres

#### lua:CRT-046_A??
Armes (8):
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??
- lua:CRT-046_A??

#### lua:CRT-047_A??
Armes (6):
- lua:CRT-047_A??
- lua:CRT-047_A??
- lua:CRT-047_A??
- lua:CRT-047_A??
- lua:CRT-047_A??
- lua:CRT-047_A??

#### lua:CRT-050_A??
Armes (11):
- lua:CRT-050_A??
- lua:CRT-050_A??
- lua:CRT-050_A??
- lua:BloodlessReposition
- lua:CRT-050_A??
- lua:BloodlessReposition
- lua:BloodlessReposition
- lua:BloodlessPitch
- lua:BloodlessPitchCurve
- lua:BloodlessPitch
- ... et 1 autres

#### lua:CRT-051_A??
Armes (4):
- lua:BloodlessMelee
- lua:BloodlessMeleeBerserkerCombo1
- lua:CRT-054_A??
- lua:CRT-054_A??

#### lua:CRT-056_A??
Armes (3):
- lua:CRT-056_A??
- lua:CRT-025_A??
- lua:CRT-025_A??

#### lua:CRT-057_A??
Armes (20):
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- lua:CRT-057_A??
- ... et 10 autres

#### lua:CRT-058_A??
Armes (8):
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??
- lua:CRT-058_A??

#### lua:CRT-061_A??
Armes (4):
- lua:CRT-061_A??
- lua:CRT-061_A??
- lua:CRT-061_A??
- lua:CRT-061_A??

#### lua:MIN-001_A??
Armes (16):
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- ... et 6 autres

#### lua:MIN-002_A??
Armes (5):
- lua:MIN-002_A??
- lua:MIN-002_A??
- lua:MIN-002_A??
- lua:MIN-002_A??
- lua:CRT-016_A??

#### lua:MIN-005_A??
Armes (8):
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??
- lua:MIN-005_A??

#### lua:MIN-009_A??
Armes (7):
- lua:MIN-009_A??
- lua:MIN-009_A??
- lua:MIN-009_A??
- lua:CRT-044_A??
- lua:CRT-044_A??
- lua:CRT-044_A??
- lua:CRT-044_A??

#### lua:MIN-010_A??
Armes (4):
- lua:MIN-010_A??
- lua:CRT-060_A??
- lua:CRT-060_A??
- lua:CRT-060_A??

#### lua:MIN-011_A??
Armes (7):
- lua:MIN-011_A??
- lua:MIN-011_A??
- lua:MIN-011_A??
- lua:MIN-011_A??
- lua:MIN-011_A??
- lua:MIN-011_A??
- lua:MIN-011_A??

---

## 6. CHAINES D'ARMES (JOUEUR)

### Armes avec chaînes: 30

### arme-007
- → arme-0072
- → arme-007Spin

### arme-0072
- → arme-0073
- → arme-007Spin

### arme-0073
- → arme-007Spin

### arme-007Block2
- → arme-007SpecialSwing

### arme-007Eff
- → arme-007

### arme-007Special
- → arme-007SpecialSwing

### arme-007SpecialSwing
- → arme-009
- → arme-009

### arme-007Spin
- → arme-009

### arme-008
- → arme-024

### arme-009
- → arme-009Arm

### arme-009Arm
- → arme-009
- → arme-009

### arme-009Vacuum
- → arme-009

### arme-010
- → arme-0102
- → arme-0105

### arme-0102
- → arme-010MultiStab
- → arme-0105

### arme-0105
- → arme-010Throw
- → arme-010Throw

### arme-010Eff
- → arme-010
- → arme-0105

### arme-010Double
- → arme-0105

### arme-010MultiStab
- → arme-010Double
- → arme-0105

### arme-011Special
- → arme-011
- → arme-011

### arme-0252
- → arme-025

### arme-027
- → arme-028

### arme-028
- → arme-0282
- → arme-0285

### arme-0282
- → arme-0283
- → arme-0285

### arme-0283
- → arme-0285

### arme-0285
- → arme-025
- → arme-025

### arme-029
- → arme-0292
- → arme-029Charged

### arme-0292
- → arme-029
- → arme-029Charged

### arme-0293
- → arme-029
- → arme-029Charged

### arme-029Charged
- → arme-029Ranged
- → arme-029Ranged

### arme-029Eff
- → arme-029
- → arme-029Charged

---

## 7. SALLES ET RENCONTRES

### Salles avec rencontres: 10

### lua:BaseF
Rencontres légales (19):
- lua:OpeningEmpty
- rencontre_ouverture_n1
- lua:FCastTutorialFight
- rencontre_ouverture_n1
- lua:FCastTutorialFight
- rencontre_ouverture_n1
- lua:FCastTutorialFight
- lua:A??
- lua:A??
- lua:A??
- ... et 9 autres

### lua:BaseG
Rencontres légales (10):
- lua:Shop
- lua:A??
- lua:Empty
- lua:Empty
- lua:Shop
- lua:A??
- lua:MIN-004
- lua:MiniBossJellyfish
- lua:HealthRestore
- lua:Story_pnj-014_01

### lua:BaseH
Rencontres légales (13):
- lua:Empty
- lua:Story_pnj-007_01
- lua:Story_pnj-007_01
- lua:Story_pnj-007_01
- lua:Story_pnj-007_01
- lua:BridgeShop
- lua:BridgeShop
- lua:Bridgepnj-015RandomEvent
- lua:A??
- lua:A??
- ... et 3 autres

### lua:BaseI
Rencontres légales (9):
- lua:Empty
- lua:Empty
- lua:A??
- lua:Empty
- lua:Shop
- lua:HealthRestore
- lua:MiniBossRatCatcher
- lua:A??
- lua:Story_pnj-008_01

### lua:BaseN
Rencontres légales (10):
- lua:OpeningEmpty
- rencontre_ouverture_n5
- rencontre_pre_hub_n5
- lua:Empty
- lua:Shop
- lua:Shop
- lua:A??
- lua:Empty
- lua:A??
- lua:Story_pnj-012_01

### lua:BaseO
Rencontres légales (8):
- lua:Empty
- lua:Shop
- lua:Shop
- lua:A??
- lua:Empty
- lua:A??
- lua:HealthRestore
- lua:Story_pnj-005_01

### lua:BaseP
Rencontres légales (25):
- lua:PIntroCombat01
- lua:PIntroCombat02
- lua:PIntroCombat03
- lua:PIntroCombat04
- lua:PIntroCombat05
- lua:PIntroCombat06
- lua:PIntroCombat07
- lua:PIntroCombat08
- lua:PIntroCombat09
- lua:A??
- ... et 15 autres

### lua:BaseRoom
Rencontres légales (9):
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty
- lua:Empty

### lua:Basepnj-003
Rencontres légales (1):
- lua:Empty

### lua:TestDevansh
Rencontres légales (15):
- lua:Empty
- lua:TestFight
- lua:TestNPCs
- lua:CombatTestJosh
- lua:Empty
- lua:Empty
- lua:Empty
- lua:TuningFight
- lua:Empty
- lua:Empty
- ... et 5 autres

---

## 8. APPARITIONS (SPAWNS)

### Rencontres avec spawns: 7

### lua:A??
Ennemis (5):
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1

### lua:CRT-056_Intro
Ennemis (23):
- lua:CRT-009_A??
- lua:CRT-008_A??
- lua:CRT-013_A??
- lua:CRT-014_A??
- lua:MIN-005_A??
- lua:CRT-019_A??
- lua:CRT-020_A??
- lua:CRT-017_A??
- lua:CRT-018_A??
- lua:CRT-028_A??
- lua:CRT-032_A??
- lua:CRT-031_A??
- lua:CRT-030_A??
- lua:CRT-036_A??
- lua:CRT-034_A??
- ... et 8 autres

### invasion_n1
Ennemis (3):
- lua:MIN-001_A??
- lua:CRT-005_A??
- lua:CRT-038_A??

### lua:A??
Ennemis (9):
- lua:MIN-003_A??
- lua:MIN-003_A??
- lua:MIN-005_A??
- lua:MIN-006_A??
- lua:MIN-009_A??
- lua:MIN-007_A??
- lua:MIN-008_A??
- lua:MIN-012_A??
- lua:CRT-043_A??

### lua:NonCombat
Ennemis (12):
- lua:CRT-002_A??
- lua:CRT-004_A??
- lua:CRT-005_A??
- lua:CRT-006_A??
- lua:CRT-001_A??
- lua:CRT-002_A??
- lua:MIN-001_A??
- lua:MIN-001_A??
- lua:MIN-002_A??
- lua:MIN-002_A??
- lua:LightRanged
- lua:LightRanged

### rencontre_ouverture_n5
Ennemis (60):
- lua:CRT-023_A??
- lua:CRT-037_A??
- CRT-029
- CRT-029
- CRT-029
- CRT-029
- CRT-029
- CRT-029
- CRT-029
- CRT-029
- lua:CRT-030_A??
- lua:CRT-028_A??
- lua:CRT-028_A??
- lua:CRT-032_A??
- lua:CRT-032_A??
- ... et 45 autres

### lua:TestFight
Ennemis (3):
- lua:CRT-003_A??
- lua:BaseSpawner
- lua:CRT-027_A??

---

## 9. STATISTIQUES

| Type | Count |
|------|-------|
| Nœuds total | 6174 |
| Arêtes total | 10531 |
| Entités SJSON | 5304 |
| Entités Lua | 870 |

### Arêtes par relation

| Relation | Count |
|----------|-------|
| applies_effect | 564 |
| fires_projectile | 75 |
| inherits | 8603 |
| phase_equips | 90 |
| phase_of | 30 |
| plays_anim | 366 |
| room_has_encounter | 119 |
| spawns | 115 |
| unit_uses_weapon | 519 |
| uses_enemy_set | 2 |
| weapon_chain | 48 |
