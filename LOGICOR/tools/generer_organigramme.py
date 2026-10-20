#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_organigramme.py
Analyse complète du graphe Hades II et génère l'organigramme Space Dracula.
"""

import json
from collections import defaultdict, Counter
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_FILE = Path(__file__).parent.parent / "space_dracula" / "ORGANOGRAPHE_COMPLET.md"
MAPPING_FILE = Path(__file__).parent.parent / "space_dracula" / "donnees" / "MAPPING_SPACE_DRACULA.json"


def charger_graphe():
    """Charge le graphe complet depuis graph.jsonl."""
    nodes = {}
    edges = []
    
    with open(CARTE_DIR / "graph.jsonl", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if obj.get("type") == "edge":
                edges.append(obj)
            elif "id" in obj and "type" in obj:
                nodes[obj["id"]] = obj
    
    return nodes, edges


def charger_mapping():
    """Charge le mapping de renommage Space Dracula."""
    with open(MAPPING_FILE, encoding="utf-8") as f:
        return json.load(f)


def categoriser_entites(nodes):
    """Catégorise les entités par type."""
    categories = defaultdict(list)
    
    for node_id, node in nodes.items():
        cat = node.get("category", "inconnu")
        categories[cat].append(node_id)
    
    return categories


def extraire_relations(edges, nodes):
    """Extrait les relations entre entités."""
    relations = defaultdict(list)
    
    for edge in edges:
        source = edge.get("source", "")
        target = edge.get("target", "")
        rel = edge.get("rel", "")
        attr = edge.get("attr", "")
        
        relations[rel].append({
            "source": source,
            "target": target,
            "attr": attr
        })
    
    return relations


def generer_organigramme():
    """Génère le document organigramme complet."""
    print("Chargement du graphe...")
    nodes, edges = charger_graphe()
    print(f"  Nœuds: {len(nodes)}")
    print(f"  Arêtes: {len(edges)}")
    
    print("Catégorisation...")
    categories = categoriser_entites(nodes)
    
    print("Extraction des relations...")
    relations = extraire_relations(edges, nodes)
    
    # Charger le mapping pour les noms Space Dracula
    mapping = charger_mapping()
    
    # Construire l'organigramme
    lignes = []
    lignes.append("# ORGANIGRAMME COMPLET - Space Dracula")
    lignes.append("")
    lignes.append("Généré automatiquement depuis le graphe Hades II (16706 nœuds, 10531 arêtes)")
    lignes.append("")
    lignes.append("---")
    lignes.append("")
    
    # 1. STRUCTURE GÉNÉRALE
    lignes.append("## 1. STRUCTURE GÉNÉRALE")
    lignes.append("")
    lignes.append("```")
    lignes.append("RUN (Course)")
    lignes.append("  │")
    lignes.append("  ├─→ NIVEAU 1 (Biome A)")
    lignes.append("  │     ├─→ Salle 1 (Type: Combat)")
    lignes.append("  │     │     └─→ Rencontre → Vagues → Ennemis")
    lignes.append("  │     ├─→ Salle 2 (Type: Mini-Boss)")
    lignes.append("  │     │     └─→ Mini-Boss + Ennemis")
    lignes.append("  │     └─→ Salle 3 (Type: Boss)")
    lignes.append("  │           └─→ Boss (Phases → Armes)")
    lignes.append("  │")
    lignes.append("  ├─→ NIVEAU 2 (Biome B)")
    lignes.append("  │     └─→ ...")
    lignes.append("  │")
    lignes.append("  └─→ NIVEAU 8 (Biome H)")
    lignes.append("        └─→ Boss Final")
    lignes.append("```")
    lignes.append("")
    
    # 2. ENTITÉS PAR CATÉGORIE
    lignes.append("---")
    lignes.append("")
    lignes.append("## 2. ENTITÉS PAR CATÉGORIE")
    lignes.append("")
    
    # Catégories principales
    categories_principales = [
        ("Units Enemies", "Ennemis"),
        ("Units NPCs", "PNJ"),
        ("Units PlayerUnits", "Héros"),
        ("Weapons PlayerWeapons", "Armes du joueur"),
        ("Weapons EnemyWeapons", "Armes ennemies"),
        ("Projectiles PlayerProjectiles", "Projectiles joueur"),
        ("Projectiles EnemyProjectiles", "Projectiles ennemis"),
        ("Obstacles", "Obstacles"),
    ]
    
    for cat, nom in categories_principales:
        if cat in categories:
            entites = categories[cat]
            lignes.append(f"### {nom} ({len(entites)} entités)")
            lignes.append("")
            # Afficher quelques exemples
            for e in entites[:10]:
                lignes.append(f"- {e}")
            if len(entites) > 10:
                lignes.append(f"- ... et {len(entites) - 10} autres")
            lignes.append("")
    
    # 3. RELATIONS
    lignes.append("---")
    lignes.append("")
    lignes.append("## 3. RELATIONS")
    lignes.append("")
    
    relations_expliquees = [
        ("inherits", "Héritage (classe parent → classe enfant)"),
        ("spawns", "Apparition (rencontre → ennemi)"),
        ("unit_uses_weapon", "Utilisation d'arme (unité → arme)"),
        ("weapon_chain", "Chaîne d'armes (arme → arme suivante)"),
        ("room_has_encounter", "Salle a rencontre (salle → rencontre)"),
        ("phase_of", "Phase de (phase → boss)"),
        ("phase_equips", "Phase équipe (phase → arme)"),
        ("applies_effect", "Applique effet (action → effet)"),
        ("fires_projectile", "Tire projectile (arme → projectile)"),
        ("plays_anim", "Joue animation (objet → animation)"),
        ("uses_enemy_set", "Utilise set ennemi (rencontre → set)"),
    ]
    
    for rel, explication in relations_expliquees:
        if rel in relations:
            lignes.append(f"### {rel} ({len(relations[rel])} arêtes)")
            lignes.append(f"*{explication}*")
            lignes.append("")
            # Afficher quelques exemples
            for r in relations[rel][:5]:
                lignes.append(f"- `{r['source']}` → `{r['target']}`" + (f" ({r['attr']})" if r['attr'] else ""))
            if len(relations[rel]) > 5:
                lignes.append(f"- ... et {len(relations[rel]) - 5} autres")
            lignes.append("")
    
    # 4. BOSS ET PHASES
    lignes.append("---")
    lignes.append("")
    lignes.append("## 4. BOSS ET PHASES")
    lignes.append("")
    
    # Extraire les boss et leurs phases
    phases = relations.get("phase_of", [])
    phase_equips = relations.get("phase_equips", [])
    
    bosses = set()
    for p in phases:
        bosses.add(p["target"])
    
    lignes.append(f"### Boss détectés: {len(bosses)}")
    lignes.append("")
    
    for boss in sorted(bosses):
        lignes.append(f"#### {boss}")
        lignes.append("")
        # Phases de ce boss
        boss_phases = [p for p in phases if p["target"] == boss]
        lignes.append(f"Phases: {len(boss_phases)}")
        for p in boss_phases:
            lignes.append(f"- Phase: `{p['source']}`")
            # Armes équipées dans cette phase
            p_equips = [e for e in phase_equips if e["source"] == p["source"]]
            if p_equips:
                armes = [e["target"] for e in p_equips]
                lignes.append(f"  - Armes: {', '.join(armes[:5])}" + (f" ... (+{len(armes)-5})" if len(armes) > 5 else ""))
        lignes.append("")
    
    # 5. ENNEMIS ET ARMES
    lignes.append("---")
    lignes.append("")
    lignes.append("## 5. ENNEMIS ET ARMES")
    lignes.append("")
    
    unit_uses_weapon = relations.get("unit_uses_weapon", [])
    
    # Groupes par unité
    unites_avec_armes = defaultdict(list)
    for u in unit_uses_weapon:
        unites_avec_armes[u["source"]].append(u["target"])
    
    lignes.append(f"### Unités avec armes: {len(unites_avec_armes)}")
    lignes.append("")
    
    for unite in sorted(unites_avec_armes.keys()):
        armes = unites_avec_armes[unite]
        lignes.append(f"#### {unite}")
        lignes.append(f"Armes ({len(armes)}):")
        for a in armes[:10]:
            lignes.append(f"- {a}")
        if len(armes) > 10:
            lignes.append(f"- ... et {len(armes) - 10} autres")
        lignes.append("")
    
    # 6. CHAINES D'ARMES
    lignes.append("---")
    lignes.append("")
    lignes.append("## 6. CHAINES D'ARMES (JOUEUR)")
    lignes.append("")
    
    weapon_chain = relations.get("weapon_chain", [])
    
    # Groupes par arme source
    chaines = defaultdict(list)
    for w in weapon_chain:
        chaines[w["source"]].append(w["target"])
    
    lignes.append(f"### Armes avec chaînes: {len(chaines)}")
    lignes.append("")
    
    for arme in sorted(chaines.keys()):
        cibles = chaines[arme]
        lignes.append(f"### {arme}")
        for c in cibles:
            lignes.append(f"- → {c}")
        lignes.append("")
    
    # 7. SALLES ET RENCONTRES
    lignes.append("---")
    lignes.append("")
    lignes.append("## 7. SALLES ET RENCONTRES")
    lignes.append("")
    
    room_has_encounter = relations.get("room_has_encounter", [])
    
    # Groupes par salle
    salles = defaultdict(list)
    for r in room_has_encounter:
        salles[r["source"]].append(r["target"])
    
    lignes.append(f"### Salles avec rencontres: {len(salles)}")
    lignes.append("")
    
    for salle in sorted(salles.keys()):
        rencontres = salles[salle]
        lignes.append(f"### {salle}")
        lignes.append(f"Rencontres légales ({len(rencontres)}):")
        for renc in rencontres[:10]:
            lignes.append(f"- {renc}")
        if len(rencontres) > 10:
            lignes.append(f"- ... et {len(rencontres) - 10} autres")
        lignes.append("")
    
    # 8. SPAWNS
    lignes.append("---")
    lignes.append("")
    lignes.append("## 8. APPARITIONS (SPAWNS)")
    lignes.append("")
    
    spawns = relations.get("spawns", [])
    
    # Groupes par rencontre
    rencontres_spawns = defaultdict(list)
    for s in spawns:
        rencontres_spawns[s["source"]].append(s["target"])
    
    lignes.append(f"### Rencontres avec spawns: {len(rencontres_spawns)}")
    lignes.append("")
    
    for renc in sorted(rencontres_spawns.keys()):
        ennemis = rencontres_spawns[renc]
        lignes.append(f"### {renc}")
        lignes.append(f"Ennemis ({len(ennemis)}):")
        for e in ennemis[:15]:
            lignes.append(f"- {e}")
        if len(ennemis) > 15:
            lignes.append(f"- ... et {len(ennemis) - 15} autres")
        lignes.append("")
    
    # 9. STATISTIQUES
    lignes.append("---")
    lignes.append("")
    lignes.append("## 9. STATISTIQUES")
    lignes.append("")
    lignes.append(f"| Type | Count |")
    lignes.append(f"|------|-------|")
    lignes.append(f"| Nœuds total | {len(nodes)} |")
    lignes.append(f"| Arêtes total | {len(edges)} |")
    lignes.append(f"| Entités SJSON | {sum(1 for n in nodes.values() if n.get('type') == 'sjson_entity')} |")
    lignes.append(f"| Entités Lua | {sum(1 for n in nodes.values() if n.get('type') == 'lua_entity')} |")
    lignes.append("")
    lignes.append("### Arêtes par relation")
    lignes.append("")
    lignes.append("| Relation | Count |")
    lignes.append("|----------|-------|")
    for rel in sorted(relations.keys()):
        lignes.append(f"| {rel} | {len(relations[rel])} |")
    lignes.append("")
    
    # Écrire le fichier
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lignes))
    
    print(f"\nOrganigramme généré: {OUTPUT_FILE}")
    print(f"  Lignes: {len(lignes)}")
    print(f"  Taille: {OUTPUT_FILE.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    generer_organigramme()
