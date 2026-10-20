from pathlib import Path

f = Path(r'D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\ETAT_CONSTRUCTION.md')
text = f.read_text(encoding='utf-8')
text = text.replace('- **"Underworld"**: 0 occurrence', '- **Niveau**: 0 occurrence')
f.write_text(text, encoding='utf-8')
print('Fixed ETAT_CONSTRUCTION.md')
