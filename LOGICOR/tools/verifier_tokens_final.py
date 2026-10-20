import os, re, sys

tokens = ["hades", "supergod", "necro", "erebus", "tartarus", "asphodel",
          "elysium", "styx", "phlegethon", "cocyte", "mega_leap", "MegaLeap",
          "Hades", "SUPGOD", "Necro", "Erebus", "Tartarus", "Asphodel",
          "Elysium", "Styx", "Phlegethon", "Cocyte"]

base = r"D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE"
ignore_dirs = {".godot", "imported", "__pycache__"}

found = 0
for root, dirs, files in os.walk(base):
    dirs[:] = [d for d in dirs if d not in ignore_dirs]
    for f in files:
        path = os.path.join(root, f)
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
        except:
            continue
        for t in tokens:
            if t in content:
                rel = os.path.relpath(path, base)
                print(f"{rel} : {t}")
                found += 1

if found == 0:
    print("0 tokens originaux trouves")
else:
    print(f"{found} occurrences")
