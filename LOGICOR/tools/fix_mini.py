from pathlib import Path

base = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE')

# Fix the remaining attack IDs in FICHES_MINI_BOSSES_V2.json
f = base / 'fiches' / 'FICHES_MINI_BOSSES_V2.json'
text = f.read_text(encoding='utf-8')
text = text.replace('MIN-002_HowlSummonminiboss_002_niveau_A01', 'MIN-002_A06')
text = text.replace('MIN-001_A02Swipe', 'MIN-001_A03')
text = text.replace('MIN-001_A02Burrow', 'MIN-001_A04')
text = text.replace('MIN-001_A022Swipe', 'MIN-001_A05')
f.write_text(text, encoding='utf-8')
print('Fixed FICHES_MINI_BOSSES_V2.json')
