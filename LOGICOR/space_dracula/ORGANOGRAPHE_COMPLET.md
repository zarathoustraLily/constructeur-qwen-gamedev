# ORGANIGRAMME COMPLET - Space Dracula

Généré automatiquement depuis le graphe Hades II (16706 nœuds, 10531 arêtes)

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
- CorruptedEgg
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
- CrawlerRam

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
- miniboss-004-lvl_2Slam
- CrawlerRush
- miniboss-004-lvl_2Rush
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

- `lua:NonCombat` → `lua:enemi-002-lvl_1`
- `lua:NonCombat` → `lua:enemi-004-lvl_1`
- `lua:NonCombat` → `lua:enemi-005-lvl_1`
- `lua:NonCombat` → `lua:enemi-006-lvl_1_Elite`
- `lua:NonCombat` → `lua:enemi-001-lvl_1`
- ... et 110 autres

### unit_uses_weapon (519 arêtes)
*Utilisation d'arme (unité → arme)*

- `lua:IsNeutral` → `lua:EliteRushRipple`
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

- `boss-001-lvl_1Stage3` → `boss-001-lvl_1MeleeCombo1`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1Melee1`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1Split2`
- `boss-001-lvl_1Stage3` → `boss-001-lvl_1RangedTorchesRing`
- `boss-001-lvl_1Stage4` → `boss-001-lvl_1Polymorph`
- ... et 85 autres

### applies_effect (564 arêtes)
*Applique effet (action → effet)*

- `boss-002-lvl_2Notes` → `HeroOnHitStun`
- `arme-008` → `RushWeaponInvulnerable` (INVULNERABLE)
- `arme-008` → `RushWeaponImmuneToForce`
- `arme-008` → `DashAttackQueue`
- `arme-008` → `RushWeaponInvulnerableCharge` (INVULNERABLE)
- ... et 559 autres

### fires_projectile (75 arêtes)
*Tire projectile (arme → projectile)*

- `enemi-056-lvl_8Melee` → `enemi-056-lvl_8Melee`
- `enemi-025-lvl_4Melee` → `enemi-025-lvl_4Melee`
- `CrawlerRam` → `CrawlerRam`
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

- `lua:OpeningGeneratedN` → `lua:enemi-029-lvl_5_Passive`
- `lua:OpeningGeneratedN` → `lua:enemi-027-lvl_5_Passive`

---

## 4. BOSS ET PHASES

### Boss détectés: 7

#### boss-001-lvl_1

Phases: 5
- Phase: `boss-001-lvl_1Stage1`
- Phase: `boss-001-lvl_1Stage2`
- Phase: `boss-001-lvl_1Stage3`
  - Armes: boss-001-lvl_1MeleeCombo1, boss-001-lvl_1Melee1, boss-001-lvl_1Split2, boss-001-lvl_1RangedTorchesRing
- Phase: `boss-001-lvl_1Stage4`
  - Armes: boss-001-lvl_1Polymorph
- Phase: `boss-001-lvl_1Stage5`
  - Armes: boss-001-lvl_1Teleport, boss-001-lvl_1Split3, boss-001-lvl_1RangedTorchesRing, boss-001-lvl_1RangedTorchesCone

#### boss-002-lvl_2

Phases: 5
- Phase: `boss-002-lvl_2Stage1`
- Phase: `boss-002-lvl_2Stage2`
- Phase: `boss-002-lvl_2Stage3`
  - Armes: boss-002-lvl_2Belt, boss-002-lvl_2Whip, boss-002-lvl_2ClamUp, boss-002-lvl_2Notes, boss-002-lvl_2SpotlightPassive ... (+1)
- Phase: `boss-002-lvl_2Stage4`
- Phase: `boss-002-lvl_2Stage5`
  - Armes: boss-002-lvl_2HeadbangFinisher, boss-002-lvl_2HeadbangFinisherHold

#### boss-003-lvl_3

Phases: 3
- Phase: `boss-003-lvl_3Stage1`
- Phase: `boss-003-lvl_3Stage2`
  - Armes: boss-003-lvl_3Hide
- Phase: `boss-003-lvl_3Stage3`
  - Armes: boss-003-lvl_3PoundCombo, boss-003-lvl_3ForwardBite, boss-003-lvl_3LungeTurn, boss-003-lvl_3TurnSlam, boss-003-lvl_3_C_Breath ... (+3)

#### boss-004-lvl_4

Phases: 6
- Phase: `boss-004-lvl_4Stage1`
- Phase: `boss-004-lvl_4Stage2`
- Phase: `boss-004-lvl_4Stage3`
  - Armes: boss-004-lvl_4Dash, boss-004-lvl_4BannerSummon, boss-004-lvl_4Grind, boss-004-lvl_4MeleeComboSelector, boss-004-lvl_4ScytheThrow ... (+1)
- Phase: `boss-004-lvl_4Stage4`
- Phase: `boss-004-lvl_4Stage5`
  - Armes: boss-004-lvl_4Rush, boss-004-lvl_4SwingRight, boss-004-lvl_4SwingLeft, boss-004-lvl_4ScytheThrow, boss-004-lvl_4CastOrbit2 ... (+4)
- Phase: `boss-004-lvl_4Stage6`
  - Armes: boss-004-lvl_4MeleeComboSelector, boss-004-lvl_4ScytheThrow, boss-004-lvl_4CastOrbit2, boss-004-lvl_4Radial, boss-004-lvl_4Radial2 ... (+1)

#### boss-005-lvl_5

Phases: 3
- Phase: `boss-005-lvl_5Stage1`
- Phase: `boss-005-lvl_5Stage2`
  - Armes: boss-005-lvl_5Leap, boss-005-lvl_5March, boss-005-lvl_5PlayerGrab, boss-005-lvl_5Grab
- Phase: `boss-005-lvl_5Stage3`
  - Armes: boss-005-lvl_5Stomp, boss-005-lvl_5Leap, boss-005-lvl_5Kick, boss-005-lvl_5Slam, boss-005-lvl_5March

#### boss-006-lvl_6

Phases: 5
- Phase: `boss-006-lvl_6Stage1`
- Phase: `boss-006-lvl_6Stage2`
  - Armes: boss-006-lvl_6SpreadFire, boss-006-lvl_6GrenadeCluster01, boss-006-lvl_6Dash, boss-006-lvl_6FlyUp, boss-006-lvl_6SummonSelector
- Phase: `boss-006-lvl_6Stage3`
  - Armes: boss-006-lvl_6SpreadFire, boss-006-lvl_6GrenadeCluster02, boss-006-lvl_6Dash, boss-006-lvl_6FlyUp, boss-006-lvl_6SummonSelector
- Phase: `boss-006-lvl_6Stage4`
  - Armes: boss-006-lvl_6RelocateStrike, boss-006-lvl_6GrenadeCluster03, boss-006-lvl_6Dash, boss-006-lvl_6FlyUp, boss-006-lvl_6SummonSelector2
- Phase: `boss-006-lvl_6Stage5`
  - Armes: boss-006-lvl_6RelocateStrike, boss-006-lvl_6FlyUp, boss-006-lvl_6SummonSelector2, boss-006-lvl_6Snipe3

#### boss-007-lvl_7

Phases: 3
- Phase: `boss-007-lvl_7Stage1`
- Phase: `boss-007-lvl_7Stage2`
  - Armes: boss-007-lvl_7Slam_P2_Starter, boss-007-lvl_7Kick_P2_Starter, boss-007-lvl_7Flurry_P2_Starter, boss-007-lvl_7Uppercut_P2_Starter, boss-007-lvl_7DashBackward ... (+3)
- Phase: `boss-007-lvl_7Stage3`
  - Armes: boss-007-lvl_7Slam_P3_Starter, boss-007-lvl_7Kick_P3_Starter, boss-007-lvl_7Flurry_P3_Starter, boss-007-lvl_7Uppercut_P3_Starter, boss-007-lvl_7DashBackward ... (+2)

---

## 5. ENNEMIS ET ARMES

### Unités avec armes: 68

#### lua:BaseTrap
Armes (28):
- lua:RootsAoE
- lua:SafeZone
- lua:CorruptedSpawns
- lua:FloodTrapWeapon
- lua:SteamTrapWeapon
- lua:MiasmaGeyser
- lua:SpikeTrapClockwork
- lua:BeamTrap
- lua:SlowPuddles
- lua:PuddleTileWeapon
- ... et 18 autres

#### lua:CorruptedShadeLarge
Armes (4):
- lua:CorruptedShadeLVacuum
- lua:CorruptedShadeLNova
- lua:CorruptedShadeLVacuum_Elite
- lua:CorruptedShadeLNova_Elite

#### lua:CorruptedShadeMedium
Armes (1):
- lua:CorruptedShadeMRam

#### lua:CorruptedShadeSmall
Armes (2):
- lua:CorruptedShadeSCast
- lua:CorruptedShadeSCast_Elite

#### lua:Crawler
Armes (5):
- lua:CrawlerRush
- lua:CrawlerBurrow
- lua:CrawlerRush_Miniboss
- lua:miniboss-004-lvl_2Slam
- lua:miniboss-004-lvl_2Summon

#### lua:DespairElemental
Armes (3):
- lua:DespairElementalChase
- lua:DespairElementalRam
- lua:DespairElementalLargeRam

#### lua:Fishenemi-056-lvl_8
Armes (2):
- lua:Fishenemi-056-lvl_8Bite
- lua:Fishenemi-056-lvl_8BiteCombo_Elite

#### lua:IsNeutral
Armes (18):
- lua:EliteRushRipple
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

#### lua:Lycanenemi-056-lvl_8
Armes (4):
- lua:Lycanenemi-056-lvl_8Chomp
- lua:Lycanenemi-056-lvl_8Blink
- lua:Lycanenemi-056-lvl_8Chomp_Elite
- lua:Lycanenemi-056-lvl_8Blink

#### lua:Sheep
Armes (6):
- lua:SheepRam
- lua:SheepExplode
- lua:SheepSickSkip
- lua:SheepSickAura
- lua:SheepSkip
- lua:SheepSkip

#### lua:boss-001-lvl_1
Armes (11):
- lua:boss-001-lvl_1MeleeCombo1
- lua:boss-001-lvl_1Melee1
- lua:boss-001-lvl_1Split1
- lua:boss-001-lvl_1MeleeCombo1
- lua:boss-001-lvl_1Melee1
- lua:boss-001-lvl_1Split2
- lua:boss-001-lvl_1RangedTorchesRing
- lua:boss-001-lvl_1RangedTorchesSpirals
- lua:boss-001-lvl_1RangedTorchesLine
- lua:boss-001-lvl_1RangedTorchesFork
- ... et 1 autres

#### lua:boss-002-lvl_2
Armes (11):
- lua:boss-002-lvl_2Belt
- lua:boss-002-lvl_2ClamUp
- lua:boss-002-lvl_2Spin
- lua:boss-002-lvl_2Whip
- lua:boss-002-lvl_2Notes
- lua:boss-002-lvl_2Belt
- lua:boss-002-lvl_2Whip
- lua:boss-002-lvl_2ClamUp
- lua:boss-002-lvl_2Notes
- lua:boss-002-lvl_2SpotlightPassive
- ... et 1 autres

#### lua:boss-003-lvl_3
Armes (13):
- lua:boss-003-lvl_3Swipe
- lua:boss-003-lvl_3Swipe
- lua:boss-003-lvl_3TurnSlam
- lua:boss-003-lvl_3PoundL
- lua:boss-003-lvl_3PoundR
- lua:boss-003-lvl_3CirclesP1_Intro
- lua:boss-003-lvl_3CircleSelectorP1
- lua:boss-003-lvl_3HowlSummonSelector
- lua:boss-003-lvl_3HowlSummonSelector
- lua:boss-003-lvl_3MiasmaGeyser
- ... et 3 autres

#### lua:boss-004-lvl_4
Armes (20):
- lua:boss-004-lvl_4Dash
- lua:boss-004-lvl_4BannerSummon
- lua:boss-004-lvl_4Grind
- lua:boss-004-lvl_4Rush
- lua:boss-004-lvl_4SwingRight
- lua:boss-004-lvl_4SwingLeft
- lua:boss-004-lvl_4ScytheThrow
- lua:boss-004-lvl_4CastOrbit
- lua:boss-004-lvl_4ScytheThrow
- lua:boss-004-lvl_4Rush
- ... et 10 autres

#### lua:boss-005-lvl_5
Armes (11):
- lua:boss-005-lvl_5Slam
- lua:boss-005-lvl_5Kick
- lua:boss-005-lvl_5Leap
- lua:boss-005-lvl_5PlayerGrab
- lua:boss-005-lvl_5Grab
- lua:boss-005-lvl_5Leap
- lua:boss-005-lvl_5March
- lua:boss-005-lvl_5PlayerGrab
- lua:boss-005-lvl_5PlayerGrab
- lua:boss-005-lvl_5Grab
- ... et 1 autres

#### lua:boss-006-lvl_6
Armes (11):
- lua:boss-006-lvl_6Spray
- lua:boss-006-lvl_6Grenade
- lua:boss-006-lvl_6Dash
- lua:boss-006-lvl_6FlyUp
- lua:boss-006-lvl_6SummonSelector
- lua:boss-006-lvl_6SpreadFire
- lua:boss-006-lvl_6GrenadeCluster01
- lua:boss-006-lvl_6Dash
- lua:boss-006-lvl_6FlyUp
- lua:boss-006-lvl_6SummonSelector
- ... et 1 autres

#### lua:boss-007-lvl_7
Armes (15):
- lua:boss-007-lvl_7Slam_P1
- lua:boss-007-lvl_7Kick_P1
- lua:boss-007-lvl_7Flurry_P1
- lua:boss-007-lvl_7Uppercut_P1
- lua:boss-007-lvl_7DashBackward
- lua:boss-007-lvl_7CastSelector_P1
- lua:boss-007-lvl_7Slam_P2_Starter
- lua:boss-007-lvl_7Kick_P2_Starter
- lua:boss-007-lvl_7Flurry_P2_Starter
- lua:boss-007-lvl_7Uppercut_P2_Starter
- ... et 5 autres

#### lua:enemi-001-lvl_1
Armes (2):
- lua:enemi-001-lvl_1Melee
- lua:enemi-001-lvl_1Melee

#### lua:enemi-002-lvl_1
Armes (5):
- lua:enemi-002-lvl_1Melee
- lua:enemi-002-lvl_1Melee_Elite
- lua:enemi-002-lvl_1Saw
- lua:enemi-002-lvl_1HyperSpin
- lua:enemi-002-lvl_1Ranged

#### lua:enemi-003-lvl_1
Armes (4):
- lua:enemi-003-lvl_1Ranged
- lua:enemi-003-lvl_1Ranged_Elite
- lua:enemi-035-lvl_6Ranged
- lua:enemi-035-lvl_6Ranged_Elite

#### lua:enemi-004-lvl_1
Armes (3):
- lua:enemi-004-lvl_1Melee360
- lua:enemi-004-lvl_1Melee360_Elite
- lua:enemi-004-lvl_1Melee360_AutoFire

#### lua:enemi-005-lvl_1
Armes (3):
- lua:enemi-005-lvl_1Cone
- lua:enemi-005-lvl_1Cone
- lua:enemi-005-lvl_1Vacuum

#### lua:enemi-006-lvl_1
Armes (4):
- lua:enemi-006-lvl_1s
- lua:enemi-006-lvl_1sElite
- lua:enemi-006-lvl_12FastVines
- lua:enemi-006-lvl_12RootVines

#### lua:enemi-007-lvl_1
Armes (2):
- lua:enemi-007-lvl_1Fuse
- lua:enemi-007-lvl_1Fuse

#### lua:enemi-009-lvl_2
Armes (2):
- lua:FishmanImpale
- lua:FishmanImpale_Elite

#### lua:enemi-010-lvl_2
Armes (2):
- lua:enemi-010-lvl_2
- lua:enemi-010-lvl_2_Elite

#### lua:enemi-013-lvl_2
Armes (8):
- lua:enemi-013-lvl_2BounceLob
- lua:enemi-013-lvl_2Hide
- lua:enemi-013-lvl_2Claw
- lua:enemi-013-lvl_2ClawRush
- lua:enemi-013-lvl_2BounceLobElite
- lua:enemi-013-lvl_2Hide
- lua:enemi-013-lvl_2Claw
- lua:enemi-013-lvl_2ClawRush

#### lua:enemi-014-lvl_2
Armes (17):
- lua:enemi-014-lvl_2Spit
- lua:enemi-014-lvl_2Swipe
- lua:enemi-014-lvl_2Lob
- lua:enemi-014-lvl_2Dive
- lua:enemi-014-lvl_2Dive
- lua:enemi-014-lvl_2Fidget
- lua:enemi-014-lvl_2Swipe
- lua:enemi-014-lvl_2SpitElite
- lua:enemi-014-lvl_2Lob
- lua:enemi-014-lvl_2Dive
- ... et 7 autres

#### lua:enemi-015-lvl_3
Armes (4):
- lua:enemi-015-lvl_3Slam
- lua:enemi-015-lvl_3Slam
- lua:enemi-015-lvl_3Spit_Elite
- lua:enemi-015-lvl_3Slam_Elite

#### lua:enemi-017-lvl_3
Armes (9):
- lua:enemi-017-lvl_3SkyCast
- lua:enemi-017-lvl_3Shockwave
- lua:enemi-017-lvl_3SkyCast_Elite
- lua:enemi-017-lvl_3Shockwave
- lua:enemi-017-lvl_3SkyCast_Support
- lua:enemi-017-lvl_3Shockwave
- lua:enemi-017-lvl_3SkyCast_Miniboss
- lua:enemi-017-lvl_3Shockwave_Miniboss
- lua:enemi-017-lvl_3Miasma

#### lua:enemi-018-lvl_3
Armes (6):
- lua:enemi-018-lvl_3Ground
- lua:enemi-018-lvl_3Overhand
- lua:enemi-018-lvl_3Ground_Elite
- lua:enemi-018-lvl_3Launcher_Elite
- lua:enemi-018-lvl_3Ground
- lua:enemi-018-lvl_3Launcher

#### lua:enemi-019-lvl_3
Armes (4):
- lua:enemi-019-lvl_3Pounce
- lua:enemi-019-lvl_3HowlSummons
- lua:enemi-019-lvl_3Pounce_Elite
- lua:enemi-019-lvl_3HowlSummons_Elite

#### lua:enemi-020-lvl_3
Armes (14):
- lua:enemi-020-lvl_3Rampage
- lua:enemi-020-lvl_3Rampage
- lua:enemi-020-lvl_3Rampage
- lua:enemi-020-lvl_3Rampage
- lua:enemi-020-lvl_3Scream
- lua:enemi-020-lvl_3Rampage_Elite
- lua:enemi-020-lvl_3Rampage_Elite
- lua:enemi-020-lvl_3Rampage_Elite
- lua:enemi-020-lvl_3Rampage_Elite
- lua:enemi-020-lvl_3Scream
- ... et 4 autres

#### lua:enemi-021-lvl_4
Armes (4):
- lua:ThugShove
- lua:ThugSwipe
- lua:ThugSwipe_Elite
- lua:ThugShove_Elite

#### lua:enemi-022-lvl_4
Armes (6):
- lua:enemi-022-lvl_4Beam
- lua:enemi-022-lvl_4Beam_Elite
- lua:enemi-022-lvl_4Beam_MiniBoss
- lua:enemi-022-lvl_4Sky
- lua:enemi-022-lvl_4Ground
- lua:enemi-022-lvl_4Beam_Elite

#### lua:enemi-023-lvl_4
Armes (25):
- lua:enemi-023-lvl_4Thrust
- lua:enemi-023-lvl_4Throw
- lua:enemi-023-lvl_4BackDash
- lua:enemi-023-lvl_4StrafeRight
- lua:enemi-023-lvl_4StrafeLeft
- lua:enemi-023-lvl_4Thrust_Elite
- lua:enemi-023-lvl_4Throw_Elite
- lua:enemi-023-lvl_4BackDash
- lua:enemi-023-lvl_4StrafeRight
- lua:enemi-023-lvl_4StrafeLeft
- ... et 15 autres

#### lua:enemi-024-lvl_4
Armes (11):
- lua:enemi-024-lvl_4Summon
- lua:enemi-024-lvl_4Cast
- lua:enemi-024-lvl_4Melee
- lua:enemi-024-lvl_4Summon_Elite
- lua:enemi-024-lvl_4Cast_Elite
- lua:enemi-024-lvl_4Melee
- lua:enemi-024-lvl_4Summon_Miniboss
- lua:enemi-024-lvl_4Cast_Miniboss
- lua:enemi-024-lvl_4Melee_Miniboss
- lua:enemi-024-lvl_4Spell
- ... et 1 autres

#### lua:enemi-026-lvl_4
Armes (2):
- lua:enemi-026-lvl_4Orbit
- lua:enemi-026-lvl_4Orbit_Elite

#### lua:enemi-027-lvl_5
Armes (2):
- lua:enemi-027-lvl_5Sweep
- lua:enemi-027-lvl_5Sweep_Elite

#### lua:enemi-028-lvl_5
Armes (5):
- lua:enemi-028-lvl_5StraightThrow
- lua:enemi-028-lvl_5Shove
- lua:enemi-028-lvl_5StraightThrow_Elite
- lua:enemi-028-lvl_5Shove_Elite
- lua:enemi-028-lvl_5EyeExplode

#### lua:enemi-029-lvl_5
Armes (6):
- lua:enemi-029-lvl_5Melee
- lua:enemi-029-lvl_5Melee_Elite
- lua:enemi-029-lvl_5Melee
- lua:enemi-029-lvl_5Melee_Elite
- lua:enemi-048-lvl_7Melee
- lua:enemi-048-lvl_7Melee_Elite

#### lua:enemi-030-lvl_5
Armes (8):
- lua:enemi-030-lvl_5Stab
- lua:enemi-030-lvl_5LateralDash
- lua:enemi-030-lvl_5LateralDash
- lua:enemi-030-lvl_5Stalk
- lua:enemi-030-lvl_5Stab_Elite
- lua:enemi-030-lvl_5LateralDash
- lua:enemi-030-lvl_5LateralDash
- lua:enemi-030-lvl_5Stalk

#### lua:enemi-031-lvl_5
Armes (4):
- lua:enemi-031-lvl_5Toss
- lua:enemi-031-lvl_5Shove
- lua:enemi-031-lvl_5Toss_Elite
- lua:enemi-031-lvl_5Shove_Elite

#### lua:enemi-032-lvl_5
Armes (4):
- lua:enemi-032-lvl_5Summon
- lua:enemi-032-lvl_5Wait
- lua:enemi-032-lvl_5Summon_Elite
- lua:enemi-032-lvl_5Wait

#### lua:enemi-033-lvl_6
Armes (9):
- lua:enemi-033-lvl_6Stab
- lua:enemi-033-lvl_6SwingLeft
- lua:enemi-033-lvl_6SwingRight
- lua:enemi-033-lvl_6SwingLeft
- lua:enemi-033-lvl_6SwingRight
- lua:enemi-033-lvl_6Barrel
- lua:enemi-033-lvl_6Stab_Elite
- lua:enemi-033-lvl_6SwingLeft_Elite
- lua:enemi-033-lvl_6SwingRight_Elite

#### lua:enemi-034-lvl_6
Armes (22):
- lua:HarpySlice
- lua:HarpyFlap
- lua:HarpyDashRight
- lua:HarpyDashLeft
- lua:HarpySlice
- lua:HarpyFlap_Elite
- lua:HarpyDashRight
- lua:HarpyDashLeft
- lua:HarpySlice2
- lua:HarpyFlapFast
- ... et 12 autres

#### lua:enemi-036-lvl_6
Armes (4):
- lua:enemi-036-lvl_6SlashLeft
- lua:enemi-036-lvl_6SlashRight
- lua:enemi-036-lvl_6SlashLeft
- lua:enemi-036-lvl_6SlashRight

#### lua:enemi-037-lvl_6
Armes (4):
- lua:enemi-037-lvl_6Throw
- lua:enemi-037-lvl_6Leap
- lua:enemi-037-lvl_6Throw_Elite
- lua:enemi-037-lvl_6LeapCombo

#### lua:enemi-038-lvl_6
Armes (2):
- lua:enemi-038-lvl_6Swing
- lua:enemi-038-lvl_6Swing_Elite

#### lua:enemi-039-lvl_6
Armes (4):
- lua:enemi-039-lvl_6Bite
- lua:enemi-039-lvl_6Fidget
- lua:enemi-039-lvl_6Bite_Elite
- lua:enemi-039-lvl_6Fidget

#### lua:enemi-040-lvl_7
Armes (6):
- lua:AutomatonBeamForward
- lua:AutomatonBeamForward
- lua:AutomatonBeamForward
- lua:enemi-040-lvl_7Scan
- lua:AutomatonBeamForward_Elite
- lua:enemi-040-lvl_7Scan

#### lua:enemi-041-lvl_7
Armes (6):
- lua:enemi-041-lvl_7Slash
- lua:enemi-041-lvl_7Whirlwind
- lua:enemi-041-lvl_7Slash_AmbientBattle
- lua:enemi-041-lvl_7Slash_Elite
- lua:enemi-041-lvl_7Whirlwind_Elite
- lua:enemi-041-lvl_7Slash_AmbientBattle

#### lua:enemi-042-lvl_7
Armes (16):
- lua:enemi-042-lvl_7Breath
- lua:enemi-042-lvl_7TailWhip
- lua:enemi-042-lvl_7Glide
- lua:enemi-042-lvl_7Breath
- lua:enemi-042-lvl_7TailWhip
- lua:enemi-042-lvl_7Glide
- lua:enemi-042-lvl_7Breath_MiniBoss
- lua:enemi-042-lvl_7TailWhip_Miniboss
- lua:enemi-042-lvl_7Glide_Miniboss
- lua:enemi-042-lvl_7WhirlLeft
- ... et 6 autres

#### lua:enemi-046-lvl_7
Armes (8):
- lua:enemi-046-lvl_7BackDash
- lua:enemi-046-lvl_7Melee
- lua:enemi-046-lvl_7Rocket
- lua:enemi-046-lvl_7Lob
- lua:enemi-046-lvl_7BackDash
- lua:enemi-046-lvl_7Melee
- lua:enemi-046-lvl_7Rocket_Elite
- lua:enemi-046-lvl_7Lob

#### lua:enemi-047-lvl_7
Armes (6):
- lua:enemi-047-lvl_7Burst
- lua:enemi-047-lvl_7Vent
- lua:enemi-047-lvl_7Burst_AmbientBattle
- lua:enemi-047-lvl_7Burst_Elite
- lua:enemi-047-lvl_7Vent
- lua:enemi-047-lvl_7Burst_AmbientBattle

#### lua:enemi-050-lvl_8
Armes (11):
- lua:enemi-050-lvl_8Ranged
- lua:enemi-050-lvl_8Cluster
- lua:enemi-050-lvl_8Dive
- lua:BloodlessReposition
- lua:enemi-050-lvl_8Dive
- lua:BloodlessReposition
- lua:BloodlessReposition
- lua:BloodlessPitch
- lua:BloodlessPitchCurve
- lua:BloodlessPitch
- ... et 1 autres

#### lua:enemi-051-lvl_8
Armes (4):
- lua:BloodlessMelee
- lua:BloodlessMeleeBerserkerCombo1
- lua:enemi-054-lvl_8Weapon
- lua:enemi-054-lvl_8WeaponElite

#### lua:enemi-056-lvl_8
Armes (3):
- lua:enemi-056-lvl_8Melee
- lua:enemi-025-lvl_4Melee
- lua:enemi-025-lvl_4Melee_Elite

#### lua:enemi-057-lvl_2
Armes (20):
- lua:enemi-057-lvl_2BeatOpener
- lua:enemi-057-lvl_2BeatConeIn
- lua:enemi-057-lvl_2BeatConeOut
- lua:enemi-057-lvl_2BeatClawClose
- lua:enemi-057-lvl_2BeatClawMid
- lua:enemi-057-lvl_2BeatClawFar
- lua:enemi-057-lvl_2BeatCoralClose
- lua:enemi-057-lvl_2BeatCoralFar
- lua:enemi-057-lvl_2SpotlightPassive
- lua:enemi-057-lvl_2SpotlightCombo
- ... et 10 autres

#### lua:enemi-058-lvl_2
Armes (8):
- lua:enemi-058-lvl_2Powerslide
- lua:enemi-058-lvl_2BounceBalls
- lua:enemi-058-lvl_2SpotlightPassive
- lua:enemi-058-lvl_2SpotlightCombo
- lua:enemi-058-lvl_2Powerslide
- lua:enemi-058-lvl_2Shred
- lua:enemi-058-lvl_2BounceBalls
- lua:enemi-058-lvl_2Dive

#### lua:enemi-061-lvl_7
Armes (4):
- lua:enemi-061-lvl_7RollLeft
- lua:enemi-061-lvl_7Rush_Fast
- lua:enemi-061-lvl_7Rush_Fast
- lua:enemi-061-lvl_7RollRight

#### lua:miniboss-001-lvl_1
Armes (16):
- lua:miniboss-001-lvl_1RangedSpray
- lua:miniboss-001-lvl_1RangedRoots
- lua:miniboss-001-lvl_1TailSpawn
- lua:miniboss-001-lvl_1Melee
- lua:miniboss-001-lvl_1RangedSpray
- lua:miniboss-001-lvl_1RangedRoots
- lua:miniboss-001-lvl_1TailSpawn_Shadow
- lua:miniboss-001-lvl_1Melee
- lua:miniboss-001-lvl_1TailBurrow
- lua:miniboss-001-lvl_1TailSwipe
- ... et 6 autres

#### lua:miniboss-002-lvl_1
Armes (5):
- lua:miniboss-002-lvl_1Sweep
- lua:miniboss-002-lvl_1Slam
- lua:miniboss-002-lvl_1Sweep
- lua:miniboss-002-lvl_1Slam
- lua:enemi-016-lvl_3Sweep

#### lua:miniboss-005-lvl_3
Armes (8):
- lua:miniboss-005-lvl_3Cast
- lua:miniboss-005-lvl_3Swipe
- lua:miniboss-005-lvl_3Teleport
- lua:miniboss-005-lvl_3Uppercut
- lua:miniboss-005-lvl_3Combo
- lua:miniboss-005-lvl_3Cast
- lua:miniboss-005-lvl_3Swipe
- lua:miniboss-005-lvl_3Teleport

#### lua:miniboss-009-lvl_5
Armes (7):
- lua:miniboss-009-lvl_5ShieldedBolt
- lua:miniboss-009-lvl_5ShieldRush
- lua:miniboss-009-lvl_5FadeBolt
- lua:enemi-044-lvl_7ShieldedBolt
- lua:enemi-044-lvl_7ShieldRush
- lua:enemi-044-lvl_7ShieldedBolt
- lua:enemi-044-lvl_7ShieldRush

#### lua:miniboss-010-lvl_6
Armes (4):
- lua:miniboss-010-lvl_6SpitSmall
- lua:enemi-060-lvl_6Slap
- lua:enemi-060-lvl_6Spike
- lua:enemi-060-lvl_6Burrow

#### lua:miniboss-011-lvl_7
Armes (7):
- lua:miniboss-011-lvl_7ShieldThrow
- lua:miniboss-011-lvl_7Magnet
- lua:miniboss-011-lvl_7Spin
- lua:miniboss-011-lvl_7Sprint
- lua:miniboss-011-lvl_7ShieldThrowLeft
- lua:miniboss-011-lvl_7ShieldThrowRight
- lua:miniboss-011-lvl_7Spin_Shadow

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

### arme-007Dash
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

### arme-010Dash
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

### arme-029Dash
- → arme-029
- → arme-029Charged

---

## 7. SALLES ET RENCONTRES

### Salles avec rencontres: 10

### lua:BaseF
Rencontres légales (19):
- lua:OpeningEmpty
- lua:OpeningGeneratedF
- lua:FCastTutorialFight
- lua:OpeningGeneratedF
- lua:FCastTutorialFight
- lua:OpeningGeneratedF
- lua:FCastTutorialFight
- lua:MiniBossminiboss-001-lvl_1
- lua:MiniBossminiboss-001-lvl_1_Shrine
- lua:MiniBossminiboss-002-lvl_1
- ... et 9 autres

### lua:BaseG
Rencontres légales (10):
- lua:Shop
- lua:Bossboss-002-lvl_201
- lua:Empty
- lua:Empty
- lua:Shop
- lua:MiniBossenemi-014-lvl_2
- lua:MiniBossCrawler
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
- lua:MiniBossminiboss-005-lvl_3
- lua:MiniBossenemi-017-lvl_3
- ... et 3 autres

### lua:BaseI
Rencontres légales (9):
- lua:Empty
- lua:Empty
- lua:Bossboss-004-lvl_401
- lua:Empty
- lua:Shop
- lua:HealthRestore
- lua:MiniBossRatCatcher
- lua:MiniBossenemi-022-lvl_4
- lua:Story_pnj-008_01

### lua:BaseN
Rencontres légales (10):
- lua:OpeningEmpty
- lua:OpeningGeneratedN
- lua:PreHubGeneratedN
- lua:Empty
- lua:Shop
- lua:Shop
- lua:Bossboss-005-lvl_501
- lua:Empty
- lua:MiniBossminiboss-009-lvl_5
- lua:Story_pnj-012_01

### lua:BaseO
Rencontres légales (8):
- lua:Empty
- lua:Shop
- lua:Shop
- lua:Bossboss-006-lvl_601
- lua:Empty
- lua:MiniBossminiboss-010-lvl_6
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
- lua:PIntroCombat_enemi-042-lvl_7Quad
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

### lua:Bossboss-003-lvl_301
Ennemis (5):
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1
- lua:SpawnPointsPhase1

### lua:FishmanIntro
Ennemis (23):
- lua:enemi-009-lvl_2
- lua:enemi-008-lvl_2
- lua:enemi-013-lvl_2
- lua:enemi-014-lvl_2
- lua:miniboss-005-lvl_3
- lua:enemi-019-lvl_3
- lua:enemi-020-lvl_3
- lua:enemi-017-lvl_3
- lua:enemi-018-lvl_3
- lua:enemi-028-lvl_5
- lua:enemi-032-lvl_5
- lua:enemi-031-lvl_5
- lua:enemi-030-lvl_5
- lua:enemi-036-lvl_6
- lua:enemi-034-lvl_6
- ... et 8 autres

### lua:GeneratedFInvasion
Ennemis (3):
- lua:miniboss-001-lvl_12
- lua:enemi-005-lvl_12
- lua:enemi-038-lvl_6

### lua:MiniBossenemi-014-lvl_2
Ennemis (9):
- lua:miniboss-003-lvl_2
- lua:miniboss-003-lvl_2
- lua:miniboss-005-lvl_3
- lua:miniboss-006-lvl_3
- lua:miniboss-009-lvl_5
- lua:miniboss-007-lvl_4
- lua:miniboss-008-lvl_4
- lua:miniboss-012-lvl_7
- lua:enemi-043-lvl_7_MiniBoss

### lua:NonCombat
Ennemis (12):
- lua:enemi-002-lvl_1
- lua:enemi-004-lvl_1
- lua:enemi-005-lvl_1
- lua:enemi-006-lvl_1_Elite
- lua:enemi-001-lvl_1
- lua:enemi-002-lvl_1
- lua:miniboss-001-lvl_1
- lua:miniboss-001-lvl_1_Shadow
- lua:miniboss-002-lvl_1_Elite
- lua:miniboss-002-lvl_1_Shadow
- lua:LightRanged
- lua:LightRanged

### lua:OpeningGeneratedN
Ennemis (60):
- lua:enemi-023-lvl_4
- lua:enemi-037-lvl_6
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-029-lvl_5_Passive
- lua:enemi-030-lvl_5
- lua:enemi-028-lvl_5
- lua:enemi-028-lvl_5
- lua:enemi-032-lvl_5
- lua:enemi-032-lvl_5
- ... et 45 autres

### lua:TestFight
Ennemis (3):
- lua:enemi-003-lvl_1
- lua:BaseSpawner
- lua:enemi-027-lvl_5

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
