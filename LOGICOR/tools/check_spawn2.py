import json

# Lire les fiches ennemies v2 et extraire les props spawn avec valeurs
with open('space_dracula/fiches/FICHES_ENNEMIS_V2.json', encoding='utf-8') as f:
    fiches = json.load(f)

print('=== Tous les props des fiches ennemies V2 (exemples) ===')
for fiche in fiches[:3]:
    print(f"  {fiche['id']}:")
    for k, v in fiche.get('props', {}).items():
        print(f"    {k} = {v}")

print()
print('=== Toutes les cles uniques dans FICHES_ENNEMIS_V2 ===')
toutes_cles = set()
for fiche in fiches:
    for key in fiche.get('props', {}).keys():
        toutes_cles.add(key)
for k in sorted(toutes_cles):
    print(f'  {k}')
