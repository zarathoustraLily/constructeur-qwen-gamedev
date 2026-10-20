import json

# Lire les fiches ennemies v2 et extraire les props spawn avec valeurs
with open('space_dracula/fiches/FICHES_ENNEMIS_V2.json', encoding='utf-8') as f:
    fiches = json.load(f)

print('=== Exemples de props spawn dans les fiches ennemies V2 ===')
comptes = 0
for fiche in fiches:
    props = fiche.get('props', {})
    spawn_props = {k: v for k, v in props.items() if 'spawn' in k.lower()}
    if spawn_props:
        comptes += 1
        if comptes <= 5:
            print(f"  {fiche['id']}: {spawn_props}")
print(f'Total ennemis avec props spawn: {comptes} / {len(fiches)}')

print()
print('=== Tous les props spawn des fiches ennemies V2 ===')
toutes_cles = set()
for fiche in fiches:
    for key in fiche.get('props', {}).keys():
        if 'spawn' in key.lower():
            toutes_cles.add(key)
for k in sorted(toutes_cles):
    print(f'  {k}')
