import json, re
from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Read MAPPING_RENOMMAGE.json
with open(base / 'MAPPING_RENOMMAGE.json','r',encoding='utf-8') as f:
    mapping = json.load(f)

# Build a reverse mapping: new name -> old name
reverse = {}
for old, info in mapping.items():
    new = info.get('nom_space_dracula', old)
    reverse[new] = old

# Read ORGANOGRAPHE_COMPLET.md
f = base / 'ORGANOGRAPHE_COMPLET.md'
text = f.read_text(encoding='utf-8')

# Replace lua: references with original names
# Pattern: lua:boss-004-lvl_4ScytheThrow -> lua:ANO-004_A12
# We need to extract the boss/enemy number and the attack name
count = 0
for old, info in mapping.items():
    new = info.get('nom_space_dracula', old)
    # Replace lua:new_name with lua:old_name? No, we want to remove the original names
    # Actually, the lua: refs contain the ORIGINAL names (like boss-004-lvl_4ScytheThrow)
    # We need to replace them with the new codes (ANO-004_A12)
    pass

# The lua: refs are in the format: lua:boss-004-lvl_4ScytheThrow
# We need to extract: boss-004 -> ANO-004, lvl_4 -> (level), ScytheThrow -> A12
# But we don't have a direct mapping from the lua: name to the attack code

# Instead, let's just remove the lua: lines entirely since they reference original code
lines = text.split('\n')
new_lines = []
removed = 0
for line in lines:
    if 'lua:' in line and ('boss-' in line or 'enemi-' in line or 'miniboss-' in line):
        # Replace the lua: reference with a generic code
        # Extract the lua: ref
        match = re.search(r'lua:([a-zA-Z0-9_-]+)', line)
        if match:
            lua_ref = match.group(1)
            # Determine the type and number
            if lua_ref.startswith('boss-'):
                num = lua_ref.split('-')[1]
                new_ref = f'ANO-{num[:3]}_A??'
            elif lua_ref.startswith('enemi-'):
                num = lua_ref.split('-')[1]
                new_ref = f'CRT-{num[:3]}_A??'
            elif lua_ref.startswith('miniboss-'):
                num = lua_ref.split('-')[1]
                new_ref = f'MIN-{num[:3]}_A??'
            else:
                new_ref = 'A??'
            line = line.replace(f'lua:{lua_ref}', f'lua:{new_ref}')
            removed += 1
    new_lines.append(line)

text = '\n'.join(new_lines)
f.write_text(text, encoding='utf-8')
print(f'Replaced {removed} lua: references in ORGANOGRAPHE_COMPLET.md')
