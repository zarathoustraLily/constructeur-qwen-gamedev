import re, os, json

os.chdir(os.path.join(os.path.dirname(__file__), '..', 'A_TRADUIRE'))

all_content = {}
file_extensions = ['.json', '.tres', '.gd', '.tscn', '.csv', '.md']

for root, dirs, files in os.walk('.'):
    for fn in files:
        if any(fn.endswith(ext) for ext in file_extensions):
            fp = os.path.join(root, fn)
            try:
                with open(fp, encoding='utf-8') as f:
                    all_content[fp] = f.read()
            except:
                pass

all_tokens = set()
for content in all_content.values():
    camels = re.findall(r'\b[a-z]+(?:[A-Z][a-z]*)+\b', content)
    pascals = re.findall(r'\b[A-Z][a-z]+(?:[A-Z][a-z]*)+\b', content)
    all_tokens.update(camels)
    all_tokens.update(pascals)

english_tokens = set()
common = {'the','and','for','with','this','that','from','have','will','would','could',
'should','there','their','they','them','then','than','when','where','which','while',
'about','above','after','again','along','among','around','before','below','between',
'under','until','into','onto','upon','over','across','through','during','without',
'within','against','each','every','both','few','more','most','other','some','such',
'no','nor','not','only','own','same','so','too','very','can','just','also','now',
'may','might','must','need','ought','shall','do','did','does','doing','done',
'go','goes','going','gone','get','gets','got','getting','give','gives','gave','given',
'having','has','had','is','are','was','were','be','been','being','am','an','as','at',
'by','in','of','on','or','to','up','us','it','its','he','she','we','you','they','me',
'my','your','his','her','our','their','what','who','whom','whose','how','why',
'if','else','case','default','switch','break','continue','return','new','delete',
'class','function','var','let','const','type','interface','extends','implements',
'public','private','protected','static','final','void','int','float','double','char',
'bool','boolean','string','object','array','list','map','set','dict','json','xml',
'html','css','js','ts','py','gd','md','csv','tres','tscn','lua','yaml','yml'}

for t in all_tokens:
    if t.isascii() and re.match(r'^[a-zA-Z]+$', t):
        if t.lower() not in common:
            english_tokens.add(t)

attack_names = set()
for t in english_tokens:
    for content in all_content.values():
        if re.search(r'(?:ANO|MIN|CRT)-\d+_' + re.escape(t) + r'\b', content):
            attack_names.add(t)
            break

effect_names = set()
for t in english_tokens:
    for content in all_content.values():
        if re.search(r'Effect\.' + re.escape(t), content):
            effect_names.add(t)
            break

ui_names = set()
icon_file = None
for fp, content in all_content.items():
    if 'ICONES_UI' in fp:
        icon_file = content
        break
if icon_file:
    ui_ids = re.findall(r'"nom":\s*"([A-Za-z0-9_]+)"', icon_file)
    ui_paths = re.findall(r'"chemin":\s*"([A-Za-z0-9_\\/\-]+)"', icon_file)
    ui_names.update(ui_ids)
    ui_names.update(ui_paths)

dt_columns = set()
for t in english_tokens:
    if t.startswith('AI_') or t in ('Damage','DamageRadius','Range','Cooldown','DisplayName','RowName','OwnerTag'):
        dt_columns.add(t)

other_english = english_tokens - attack_names - effect_names - ui_names - dt_columns

print(f'Total English tokens: {len(english_tokens)}')
print(f'Attack names: {len(attack_names)}')
print(f'Effect names: {len(effect_names)}')
print(f'UI names: {len(ui_names)}')
print(f'DT columns: {len(dt_columns)}')
print(f'Other: {len(other_english)}')
print()
print('=== ATTACK NAMES (all) ===')
for t in sorted(attack_names):
    print(t)
print()
print('=== EFFECT NAMES (all) ===')
for t in sorted(effect_names):
    print(t)
print()
print('=== UI NAMES (all) ===')
for t in sorted(ui_names):
    print(t)
print()
print('=== DT COLUMNS (all) ===')
for t in sorted(dt_columns):
    print(t)
print()
print('=== OTHER (all) ===')
for t in sorted(other_english):
    print(t)
