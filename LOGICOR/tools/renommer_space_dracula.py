#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
renommer_space_dracula.py
Construit le mapping de renommage complet de Hades II -> Space Dracula.
Tous les tokens Hades II sont renommés en tokens Space Dracula.
"""

import json
from pathlib import Path
import re

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"

# Thème Space Dracula : univers spatial + vampire
# - Hades (enfer) -> Espace (Space)
# - Dieux grecs -> Entités cosmiques (Cosmic Entities)
# - Ennemis infernaux -> Créatures spatiales
# - Boss -> Anomalies cosmiques
# - Armes -> Reliques


def generer_nom_entite(categorie: str, numero: int) -> str:
    """Génère un nom Space Dracula pour une entité."""
    # Préfixes par catégorie
    prefixes = {
        "dieu": "ENT",       # Entité
        "ennemi": "CRT",     # Créature
        "boss": "ANO",       # Anomalie
        "mini-boss": "MIN",  # Minion
        "pnj": "NVA",        # Navigateur
        "compagnon": "COP",  # Co-pilote
        "arme": "REL",      # Relique
        "niveau": "SEC",     # Secteur
    }
    prefix = prefixes.get(categorie, "XXX")
    return f"{prefix}-{numero:03d}"


def construire_mapping(identity: dict) -> dict:
    """Construit le mapping original -> space_dracula."""
    mapping = {}
    
    # D'abord les entités nommées
    for name, info in identity.items():
        categorie = info.get("categorie", "inconnu")
        numero = info.get("numero", 0)
        nom_original = name
        
        # Générer le nom Space Dracula
        nom_sd = generer_nom_entite(categorie, numero)
        
        mapping[nom_original] = {
            "nom_sd": nom_sd,
            "categorie": categorie,
            "nom_affiche": info.get("nom_affiche_origine", name),
        }
    
    # Ajouter les tokens de données (MaxHealth, Weapon*, etc.)
    tokens_donnees = [
        # Paramètres de base
        ("MaxHealth", "PV_Max", "paramètre"),
        ("Speed", "Vitesse", "paramètre"),
        ("Damage", "Degats", "paramètre"),
        ("Range", "Portee", "paramètre"),
        ("Radius", "Rayon", "paramètre"),
        ("Duration", "Duree", "paramètre"),
        ("Cooldown", "Refroidissement", "paramètre"),
        ("Multiplier", "Multiplicateur", "paramètre"),
        
        # Paramètres IA
        ("AI.PreAttackDuration", "IA.AnnonceDuree", "paramètre"),
        ("AI.FireDuration", "IA.TirDuree", "paramètre"),
        ("AI.PostAttackDuration", "IA.RecuperationDuree", "paramètre"),
        ("AI.AttackDistance", "IA.PorteeAttaque", "paramètre"),
        ("AI.AttackDistanceScaleY", "IA.PorteeAttaqueEchelleY", "paramètre"),
        ("AI.FireTicks", "IA.TicksTir", "paramètre"),
        ("AI.FireInterval", "IA.IntervalleTir", "paramètre"),
        ("AI.Spread", "IA.Dispersion", "paramètre"),
        ("AI.BarrelLength", "IA.LongueurCanon", "paramètre"),
        ("AI.NumProjectiles", "IA.NombreProjectiles", "paramètre"),
        ("AI.ProjectileAngleInterval", "IA.IntervalleAngleProjectile", "paramètre"),
        ("AI.SpawnRate", "IA.TauxApparition", "paramètre"),
        ("AI.SpawnRadius", "IA.RayonApparition", "paramètre"),
        ("AI.SpawnsPerBurstMin", "IA.ApparitionsParVagueMin", "paramètre"),
        ("AI.SpawnsPerBurstMax", "IA.ApparitionsParVagueMax", "paramètre"),
        ("AI.MaxActiveSpawns", "IA.MaxActifs", "paramètre"),
        ("AI.TeleportMinDistance", "IA.TeleportMinDistance", "paramètre"),
        ("AI.TeleportMaxDistance", "IA.TeleportMaxDistance", "paramètre"),
        ("AI.ChargeSelfVelocity", "IA.VitesseCharge", "paramètre"),
        ("AI.FireSelfVelocity", "IA.VitesseTir", "paramètre"),
        ("AI.PreAttackAnimationSpeed", "IA.VitesseAnimationAnnounce", "paramètre"),
        ("AI.PreAttackEndFlashFraction", "IA.FractionFlashFinAnnonce", "paramètre"),
        ("AI.PreAttackRotationDampening", "IA.AttenuationRotationAnnonce", "paramètre"),
        ("AI.FireRotationDampening", "IA.AttenuationRotationTir", "paramètre"),
        ("AI.MoveWithinRangeTimeout", "IA.DelaiDeplacementPortee", "paramètre"),
        ("AI.MoveSuccessDistance", "IA.DistanceSuccesDeplacement", "paramètre"),
        ("AI.WaitForAngleTowardTargetTimeOut", "IA.DelaiAngleCible", "paramètre"),
        ("AI.TargetOffsetDistance", "IA.DistanceCible", "paramètre"),
        ("AI.DashIfOverDistance", "IA.DashSiDepassement", "paramètre"),
        ("AI.RetreatToId", "IA.ReculVersId", "paramètre"),
        ("AI.RetreatBufferDistance", "IA.TamponRecul", "paramètre"),
        ("AI.FireProjectileStartDelay", "IA.DelaiDebutTir", "paramètre"),
        ("AI.AttackSlotInterval", "IA.IntervalleSlotAttaque", "paramètre"),
        ("AI.AttackSlotsPerTick", "IA.SlotsParTick", "paramètre"),
        ("AI.UseTargetId", "IA.UsaCibleId", "paramètre"),
        ("AI.MoveToId", "IA.SeDeplacerVersId", "paramètre"),
        ("AI.EndScale", "IA.EchelleFin", "paramètre"),
        ("AI.ScaleDuration", "IA.DureeEchelle", "paramètre"),
        ("AI.LoSBuffer", "IA.TamponLigneVie", "paramètre"),
        ("AI.PreFireDuration", "IA.DureePreTir", "paramètre"),
        ("AI.PreAttackSetZHeight", "IA.AlteurePreTir", "paramètre"),
        ("AI.FireSetZHeight", "IA.AlteureTir", "paramètre"),
        ("AI.FireSetZDuration", "IA.DureeAltitudeTir", "paramètre"),
        ("AI.AIPickupTime", "IA.DureeRamassage", "paramètre"),
        ("AI.AIPickupDuration", "IA.DureeRamassageIA", "paramètre"),
        ("AI.BeginPickupDuration", "IA.DureeDebutRamassage", "paramètre"),
        ("AI.HealTicksPerConsume", "IA.TicksSoinParConsommation", "paramètre"),
        ("AI.HealPerTick", "IA.SoinParTick", "paramètre"),
        ("AI.HealTickInterval", "IA.IntervalleSoin", "paramètre"),
        ("AI.FireTickSelfVelocity", "IA.VitesseTickTir", "paramètre"),
        ("AI.FireTickSelfVelocityAngleOffset", "IA.AngleOffsetVitesseTick", "paramètre"),
        ("AI.FireTicksMin", "IA.TicksTirMin", "paramètre"),
        ("AI.FireTicksMax", "IA.TicksTirMax", "paramètre"),
        ("AI.TargetOffsetDistanceMin", "IA.DistanceCibleMin", "paramètre"),
        ("AI.TargetOffsetDistanceMax", "IA.DistanceCibleMax", "paramètre"),
        ("AI.FireSelfVelocityAngleOffset", "IA.AngleOffsetVitesseTir", "paramètre"),
        ("AI.PreAttackSelfVelocity", "IA.VitesseAutoAnnonce", "paramètre"),
        ("AI.PreAttackSelfVelocityAngleOffset", "IA.AngleOffsetVitesseAutoAnnonce", "paramètre"),
        ("AI.FireSelfVelocityAngleOffset", "IA.AngleOffsetVitesseTir", "paramètre"),
        ("AI.ProjectileInterval", "IA.IntervalleProjectile", "paramètre"),
        ("AI.SpawnBurstDelay", "IA.DelaiVagueApparition", "paramètre"),
        ("AI.SpawnRadiusMin", "IA.RayonApparitionMin", "paramètre"),
        ("AI.SpawnRadiusMax", "IA.RayonApparitionMax", "paramètre"),
        ("AI.PreMoveDuration", "IA.DureePreDeplacement", "paramètre"),
        ("AI.PreAttackEndDuration", "IA.DureeFinAnnonce", "paramètre"),
        ("AI.PostAttackDurationMin", "IA.DureeRecuperationMin", "paramètre"),
        ("AI.PostAttackDurationMax", "IA.DureeRecuperationMax", "paramètre"),
        ("AI.PostAttackCooldownMin", "IA.RefroidissementPostAttaqueMin", "paramètre"),
        ("AI.OrbitTickDegrees", "IA.DegresTickOrbite", "paramètre"),
        ("AI.OrbitTickDuration", "IA.DureeTickOrbite", "paramètre"),
        ("AI.OrbitDistance", "IA.DistanceOrbite", "paramètre"),
        ("AI.EnterFogRadiusBuffer", "IA.TamponRayonBrumeEntree", "paramètre"),
        ("AI.ExitFogRadiusBuffer", "IA.TamponRayonBrumeSortie", "paramètre"),
        ("AI.FogRadius", "IA.RayonBrume", "paramètre"),
        ("AI.FogRadiusScaleY", "IA.EchelleYRayonBrume", "paramètre"),
        ("AI.TeleportToBattleFoeChance", "IA.ProbabiliteTeleportCible", "paramètre"),
        ("AI.WanderDistance", "IA.DistanceErrance", "paramètre"),
        ("AI.WanderFrequency", "IA.FrequenceErrance", "paramètre"),
        ("AI.AggroRange", "IA.PorteeAggro", "paramètre"),
        ("AI.PreTeleportWait", "IA.AttentePreTeleport", "paramètre"),
        ("AI.PostTeleportWait", "IA.AttentePostTeleport", "paramètre"),
        ("AI.TeleportationInterval", "IA.IntervalleTeleport", "paramètre"),
        ("AI.MaxConsecutiveUses", "IA.MaxUsagesConsecutifs", "paramètre"),
        ("AI.FireFxOffset", "IA.OffsetEffetTir", "paramètre"),
        ("AI.SetDumbFireThreadWait", "IA.AttenteThreadTir", "paramètre"),
        ("AI.TargetMinDistance", "IA.DistanceCibleMin", "paramètre"),
        ("AI.TimeSlowDuration", "IA.DureeRalentissementTemps", "paramètre"),
        ("AI.WaitDurationForComboPartnerMove", "IA.AttenteDeplacementPartenaireCombo", "paramètre"),
        ("AI.TargetArcRange", "IA.PorteeArcCible", "paramètre"),
        ("AI.PreAttackDurationMin", "IA.DureeAnnonceMin", "paramètre"),
        ("AI.PreAttackDurationMax", "IA.DureeAnnonceMax", "paramètre"),
        ("AI.PreAttackDuration", "IA.DureeAnnonce", "paramètre"),
        ("AI.PostAttackDuration", "IA.DureeRecuperation", "paramètre"),
        ("AI.AttackDistance", "IA.PorteeAttaque", "paramètre"),
        ("AI.FireDuration", "IA.DureeTir", "paramètre"),
        ("AI.PreAttackDuration", "IA.DureeAnnonce", "paramètre"),
        
        # Paramètres d'IA fin de phase
        ("AIEndHealthThreshold", "IA.FinSeuilPV", "paramètre"),
        ("AIEndGroupHealthThreshold", "IA.FinSeuilPVGroupe", "paramètre"),
        ("AIEndLastAlive", "IA.FinDernierVivant", "paramètre"),
        ("AIEndWithSpawnedEncounter", "IA.FinAvecRencontreAppelee", "paramètre"),
        ("AIEndWithSpawnedEncounterTimeout", "IA.FinRencontreAppeleeDelai", "paramètre"),
        ("UnequipAllWeapons", "IA.DequiperToutesArmes", "paramètre"),
        ("WaitDuration", "IA.AttenteDuree", "paramètre"),
        ("NewMaxHealth", "IA.NouveauPVMax", "paramètre"),
        
        # Armes (chaînes)
        ("SwapOnFire", "REL.EchangeAuTir", "paramètre"),
        ("AddOnFire", "REL.AjouterAuTir", "paramètre"),
        ("AddControlOnFire", "REL.AjouterContrôleAuTir", "paramètre"),
        ("RemoveControlOnCharge", "REL.RetirerContrôleACharge", "paramètre"),
        ("ForceReleaseWeaponOnFire", "REL.ForceLacherAuTir", "paramètre"),
        ("ChargeTime", "REL.TempsCharge", "paramètre"),
        ("Projectile", "REL.Projectile", "paramètre"),
        ("ProjectileToArm", "REL.ProjectileBras", "paramètre"),
        ("InheritFrom", "HériterDe", "paramètre"),
        
        # Effets
        ("Effects", "Effets", "paramètre"),
        ("Modifier", "Modificateur", "paramètre"),
        ("DurationFrames", "DureeCadres", "paramètre"),
        ("Type", "Type", "paramètre"),
        ("Active", "Actif", "paramètre"),
        ("CanAffectInvulnerable", "PeutAffecterInvulnérable", "paramètre"),
        ("IgnoreName", "IgnorerNom", "paramètre"),
        
        # Génération de rencontres
        ("MinWaves", "Gen.OndesMin", "paramètre"),
        ("MaxWaves", "Gen.OndesMax", "paramètre"),
        ("MinTypes", "Gen.TypesMin", "paramètre"),
        ("MaxTypes", "Gen.TypesMax", "paramètre"),
        ("MaxTypesCap", "Gen.TypesMaxPlafond", "paramètre"),
        ("TypeCountDepthRamp", "Gen.RampeTypesProfondeur", "paramètre"),
        ("EnemyCountDepthRamp", "Gen.RampeEnnemisProfondeur", "paramètre"),
        ("BaseDifficulty", "Gen.DifficulteDeBase", "paramètre"),
        ("DepthDifficultyRamp", "Gen.RampeDifficulteProfondeur", "paramètre"),
        ("DifficultyModifier", "Gen.ModificateurDifficulte", "paramètre"),
        ("DifficultyMultiplier", "Gen.MultiplicateurDifficulte", "paramètre"),
        ("SpawnIntervalMin", "Gen.IntervalleApparitionMin", "paramètre"),
        ("SpawnIntervalMax", "Gen.IntervalleApparitionMax", "paramètre"),
        ("ActiveEnemyCapBase", "Gen.PlafondEnnemisActifsBase", "paramètre"),
        ("ActiveEnemyCapMax", "Gen.PlafondEnnemisActifsMax", "paramètre"),
        ("ActiveEnemyCapDepthRamp", "Gen.RampePlafondEnnemisProfondeur", "paramètre"),
        ("ActiveEnemyCapMin", "Gen.PlafondEnnemisActifsMin", "paramètre"),
        ("MetaPointStoreRamp", "Gen.RampePointsMeta", "paramètre"),
        ("MoneyDropCapMin", "Gen.PlafondLarguerArgentMin", "paramètre"),
        ("MoneyDropCapMax", "Gen.PlafondLarguerArgentMax", "paramètre"),
        ("MoneyDropCapDepthRamp", "Gen.RampePlafondLarguerArgentProfondeur", "paramètre"),
        ("PreSpawnMinEndPointDistance", "Gen.DistanceMinPointFinAvantApparition", "paramètre"),
        ("MaxEliteTypes", "Gen.TypesEliteMax", "paramètre"),
        ("Gen.DifficultyRating", "Gen.NoteDifficulte", "paramètre"),
        ("Gen.MaxCount", "Gen.NombreMax", "paramètre"),
        
        # Générateur
        ("Generated", "Gen", "paramètre"),
        ("GeneratedF", "GenF", "paramètre"),
        ("BaseIntroEncounter", "RencontreIntroDeBase", "paramètre"),
        
        # Ennemis
        ("1_BaseEnemy", "BaseEnnemi", "entité"),
        ("1_BaseBoss", "BaseBoss", "entité"),
        ("1_BaseDamagingWeapon", "BaseArmeDegats", "entité"),
        ("BaseUnlockableWeapon", "BaseArmeDébloquable", "entité"),
        ("DefaultWeaponValues", "ValeursArmeParDefaut", "entité"),
        ("PassiveRoomWeapon", "ArmePassiveSalle", "entité"),
        
        # Projectiles
        ("ProjectileStaffSwing1", "PROJ.BâtonFouet1", "entité"),
        ("ProjectileStaffSwing2", "PROJ.BâtonFouet2", "entité"),
        ("ProjectileStaffSwing3", "PROJ.BâtonFouet3", "entité"),
        ("ProjectileStaffSwing4", "PROJ.BâtonFouet4", "entité"),
        ("ProjectileStaffSwing5", "PROJ.BâtonFouet5", "entité"),
        ("ProjectileStaffBall1", "PROJ.BâtonBalle1", "entité"),
        ("ProjectileStaffBolt1", "PROJ.BâtonÉclair1", "entité"),
        ("ProjectileStaffBolt2", "PROJ.BâtonÉclair2", "entité"),
        ("ProjectileStaffBolt3", "PROJ.BâtonÉclair3", "entité"),
        ("ProjectileTorch1", "PROJ.Torche1", "entité"),
        ("ProjectileTorch2", "PROJ.Torche2", "entité"),
        ("ProjectileTorch3", "PROJ.Torche3", "entité"),
        ("ProjectileAxe1", "PROJ.Hache1", "entité"),
        ("ProjectileAxe2", "PROJ.Hache2", "entité"),
        ("ProjectileAxe3", "PROJ.Hache3", "entité"),
        ("ProjectileDagger1", "PROJ.Dague1", "entité"),
        ("ProjectileDagger2", "PROJ.Dague2", "entité"),
        ("ProjectileLob1", "PROJ.Lob1", "entité"),
        ("ProjectileLob2", "PROJ.Lob2", "entité"),
        ("ProjectileMorphedAttack1", "PROJ.AttaqueMorphée1", "entité"),
        ("ProjectileMorphedBlink1", "PROJ.ClignementMorphé1", "entité"),
        ("ProjectileSkullImpulse1", "PROJ.ImpulseCrâne1", "entité"),
        ("ProjectileSpellLaser1", "PROJ.SortLaser1", "entité"),
        ("ProjectileSpellLeap1", "PROJ.SortSaut1", "entité"),
        ("ProjectileSpellMeteor1", "PROJ.SortMétéore1", "entité"),
        ("ProjectileSpellMoonBeam1", "PROJ.SortRayonLunaire1", "entité"),
        ("ProjectileSpellPolymorph1", "PROJ.SortPolymorphe1", "entité"),
        ("ProjectileSpellPotion1", "PROJ.SortPotion1", "entité"),
        ("ProjectileSpellSummon1", "PROJ.SortInvocation1", "entité"),
        ("ProjectileSpellTimeSlow1", "PROJ.SortRalentissementTemps1", "entité"),
        ("ProjectileSpellTransform1", "PROJ.SortTransformation1", "entité"),
        ("ProjectileTransformAttack1", "PROJ.AttaqueTransformation1", "entité"),
        ("ProjectileTransformBlink1", "PROJ.ClignementTransformation1", "entité"),
        ("ProjectileTransformCast1", "PROJ.LancerTransformation1", "entité"),
        ("ProjectileTransformSpecial1", "PROJ.SpécialTransformation1", "entité"),
        
        # Armes
        ("WeaponStaffSwing", "REL.BâtonFouet", "entité"),
        ("WeaponStaffSwing2", "REL.BâtonFouet2", "entité"),
        ("WeaponStaffSwing3", "REL.BâtonFouet3", "entité"),
        ("WeaponStaffSwing5", "REL.BâtonFouet5", "entité"),
        ("WeaponStaffBall", "REL.BâtonBalle", "entité"),
        ("WeaponStaffBolt", "REL.BâtonÉclair", "entité"),
        ("WeaponStaffDash", "REL.BâtonDash", "entité"),
        ("WeaponTorch", "REL.Torche", "entité"),
        ("WeaponAxe", "REL.Hache", "entité"),
        ("WeaponDagger", "REL.Dague", "entité"),
        ("WeaponLob", "REL.Lob", "entité"),
        ("WeaponMorphedAttack", "REL.AttaqueMorphée", "entité"),
        ("WeaponMorphedBlink", "REL.ClignementMorphé", "entité"),
        ("WeaponSkullImpulse", "REL.ImpulseCrâne", "entité"),
        ("WeaponSpellLaser", "REL.SortLaser", "entité"),
        ("WeaponSpellLeap", "REL.SortSaut", "entité"),
        ("WeaponSpellMeteor", "REL.SortMétéore", "entité"),
        ("WeaponSpellMoonBeam", "REL.SortRayonLunaire", "entité"),
        ("WeaponSpellPolymorph", "REL.SortPolymorphe", "entité"),
        ("WeaponSpellPotion", "REL.SortPotion", "entité"),
        ("WeaponSpellSummon", "REL.SortInvocation", "entité"),
        ("WeaponSpellTimeSlow", "REL.SortRalentissementTemps", "entité"),
        ("WeaponSpellTransform", "REL.SortTransformation", "entité"),
        ("WeaponTransformAttack", "REL.AttaqueTransformation", "entité"),
        ("WeaponTransformBlink", "REL.ClignementTransformation", "entité"),
        ("WeaponTransformCast", "REL.LancerTransformation", "entité"),
        ("WeaponTransformSpecial", "REL.SpécialTransformation", "entité"),
        ("WeaponAnywhereCast", "REL.LancerPartout", "entité"),
        ("WeaponBlink", "REL.Clignement", "entité"),
        ("WeaponCast", "REL.Lancer", "entité"),
        ("WeaponSprint", "REL.Sprint", "entité"),
        ("WeaponSuit", "REL.Combinaison", "entité"),
        ("EncounterStartBuffWeapon", "REL.BuffDebutRencontre", "entité"),
        ("FlashbackHadesBlink", "REL.FlashbackHadesClignement", "entité"),
        ("FlashbackMelBlink", "REL.FlashbackMelClignement", "entité"),
        ("PoseidonSprintWeapon", "REL.SprintPoseidon", "entité"),
        ("SelfSlow", "REL.RalentissementAuto", "entité"),
        
        # Ennemis spécifiques
        ("Mage", "CRT.Sorcier", "entité"),
        ("Mage_Elite", "CRT.SorcierElite", "entité"),
        ("Wastrel", "CRT.Gredin", "entité"),
        ("Smacker", "CRT.Fouetteur", "entité"),
        ("Bronzebeak", "CRT.BecBronze", "entité"),
        ("Charybdis", "CRT.Charybde", "entité"),
        ("Wretched Thug", "CRT.VaurienMiserable", "entité"),
        ("Sky-Dracon", "CRT.DragonCeleste", "entité"),
        ("Boozer", "CRT.Ivrogne", "entité"),
        ("Auto-Watcher", "CRT.GardienAuto", "entité"),
        ("Auto-Forcer", "CRT.ForcerAuto", "entité"),
        ("Bone-Raker", "CRT.RacleurOsseux", "entité"),
        ("Inferno-Bomber", "CRT.BombardierInfernal", "entité"),
        ("Bloodless", "CRT.SansSang", "entité"),
        ("BloodlessBerserker", "CRT.BerserkerSansSang", "entité"),
        ("BloodlessGrenadier", "CRT.GrenadierSansSang", "entité"),
        ("BloodlessNaked", "CRT.NuSansSang", "entité"),
        ("Burn-Flinger", "CRT.LanceurBrûlure", "entité"),
        ("Slam-Dancer", "CRT.DanseurFrappe", "entité"),
        ("Wave-Maker", "CRT.FabriqueVagues", "entité"),
        
        # Boss
        ("Hecate", "ANO.Hecate", "entité"),
        ("Scylla", "ANO.Scylla", "entité"),
        ("Infernal Beast", "ANO.BeteInfernale", "entité"),
        ("Chronos", "ANO.Chronos", "entité"),
        ("Polyphemus", "ANO.Polyphemus", "entité"),
        ("Eris", "ANO.Eris", "entité"),
        ("Prometheus", "ANO.Prometheus", "entité"),
        
        # PNJ
        ("Arachne", "NVA.Arachne", "entité"),
        ("Aphrodite", "ENT.Aphrodite", "entité"),
        ("Apollo", "ENT.Apollo", "entité"),
        ("Ares", "ENT.Ares", "entité"),
        ("Artemis", "ENT.Artemis", "entité"),
        ("Athena", "ENT.Athena", "entité"),
        ("Demeter", "ENT.Demeter", "entité"),
        ("Hades", "ENT.Hades", "entité"),
        ("Hermes", "ENT.Hermes", "entité"),
        ("Hephaestus", "ENT.Hephaestus", "entité"),
        ("Hypnos", "ENT.Hypnos", "entité"),
        ("Nike", "ENT.Nike", "entité"),
        ("Persephone", "ENT.Persephone", "entité"),
        ("Poseidon", "ENT.Poseidon", "entité"),
        ("Zeus", "ENT.Zeus", "entité"),
        
        # Niveaux
        ("BiomeB", "SEC.SecteurB", "entité"),
        ("BiomeF", "SEC.SecteurF", "entité"),
        ("BiomeG", "SEC.SecteurG", "entité"),
        ("BiomeH", "SEC.SecteurH", "entité"),
        ("BiomeI", "SEC.SecteurI", "entité"),
        ("BiomeN", "SEC.SecteurN", "entité"),
        ("BiomeO", "SEC.SecteurO", "entité"),
        ("BiomeP", "SEC.SecteurP", "entité"),
    ]
    
    for original, sd, cat in tokens_donnees:
        if original not in mapping:
            mapping[original] = {
                "nom_sd": sd,
                "categorie": cat,
                "nom_affiche": original,
            }
    
    return mapping


def main():
    print("Chargement de la carte de données...")
    
    # Charger identity_map
    with open(CARTE_DIR / "identity_map.json", "r", encoding="utf-8") as f:
        identity = json.load(f)
    
    print(f"  - identity_map: {len(identity)} entités")
    
    # Construire le mapping
    mapping = construire_mapping(identity)
    
    print(f"  - Mapping total: {len(mapping)} tokens")
    
    # Écrire le mapping
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_DIR / "MAPPING_SPACE_DRACULA.json", "w", encoding="utf-8") as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)
    
    print(f"\nÉcrit dans: {OUTPUT_DIR / 'MAPPING_SPACE_DRACULA.json'}")
    
    # Statistiques par catégorie
    cats = {}
    for token, info in mapping.items():
        cat = info.get("categorie", "inconnu")
        cats[cat] = cats.get(cat, 0) + 1
    
    print("\n=== STATISTIQUES PAR CATÉGORIE ===")
    for cat, count in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"  {cat}: {count}")
    
    print("\n=== APERÇU DU MAPPING (premières 20) ===")
    i = 0
    for original, info in mapping.items():
        if i >= 20:
            break
        print(f"  {original} -> {info['nom_sd']}")
        i += 1


if __name__ == "__main__":
    main()
