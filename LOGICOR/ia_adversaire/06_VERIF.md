# Vérification de l'IA - LOGICOR

## Test 1 : Arbre de décision (23 steps)

```bash
godot --headless --script adversaires/L_TestOracles.gd
```

**Sortie attendue :**
```
=== TEST IA (LOGICOR) ===

step  1 → S_MARQUER
step  2 → S_AVANCER
step  3 → S_AVANCER
step  4 → S_AVANCER
step  5 → S_AVANCER
        [PV Unit001 = 100 %]
step  6 → S_FRAPPER
step  7 → S_AVANCER
step  8 → S_FRAPPER
step  9 → S_AVANCER
step 10 → S_FRAPPER
        [PV Unit001 = 95 %]
step 11 → S_AVANCER
step 12 → S_FRAPPER
step 13 → S_AVANCER
step 14 → S_FRAPPER
step 15 → S_AVANCER
        [PV Unit001 = 90 %]
step 16 → S_FRAPPER
step 17 → S_AVANCER
step 18 → S_FRAPPER
step 19 → S_AVANCER
step 20 → S_FRAPPER
        [PV Unit001 = 85 %]
step 21 → S_AVANCER
step 22 → S_FRAPPER
step 23 → S_AVANCER
=== FIN : le Unit001 a descendu l'arbre 23 fois ===
```

## Test 2 : Pipeline de dégâts

```bash
godot --headless --script preuves/L_TestDegrats.gd
```

**Sortie attendue :**
```
=== TEST DEGRATS ===

Base: 10, Mult: 1.0, Additif: 0, Crit: false → 10
Base: 10, Mult: 1.0, Additif: 0, Crit: true → 30
Base: 10, Mult: 1.5, Additif: 5, Crit: false → 20
Base: 10, Mult: 1.5, Additif: 5, Crit: true → 60
Base: 5, Mult: 0.8, Additif: 2, Crit: false → 6
=== FIN : 5 tests passés ===
```

## Test 3 : Système d'i-frames

```bash
godot --headless --script preuves/L_TestInvuln.gd
```

**Sortie attendue :**
```
=== TEST INVULN ===

PV: 30 / 30 → Pas d'invuln
PV: 25 / 30 → Pas d'invuln
PV: 20 / 30 → Pas d'invuln
PV: 15 / 30 → INVULN ACTIVÉ (seuil: max(30×0.25, 15) = 15)
PV: 10 / 30 → INVULN ACTIF (temps restant: 1.3s)
PV: 5 / 30 → INVULN ACTIF (temps restant: 0.5s)
PV: 0 / 30 → INVULN TERMINÉ
=== FIN : i-frames fonctionnent ===
```

## Test 4 : Dernier effort

```bash
godot --headless --script preuves/L_TestDernierEffort.gd
```

**Sortie attendue :**
```
=== TEST DERNIER EFFORT ===

PV: 30 / 30 → Pas de dernier effort
PV: 25 / 30 → Pas de dernier effort
PV: 20 / 30 → Pas de dernier effort
PV: 15 / 30 → Pas de dernier effort
PV: 10 / 30 → Pas de dernier effort
PV: 5 / 30 → DERNIER EFFORT ACTIVÉ (seuil: 30×0.1 = 3, soin: +12 PV)
PV: 17 / 30 → DERNIER EFFORT ACTIF (temps restant: 5.0s)
PV: 17 / 30 → DERNIER EFFORT ACTIF (temps restant: 4.2s)
PV: 17 / 30 → DERNIER EFFORT TERMINÉ
=== FIN : dernier effort fonctionne ===
```

## Test 5 : Run director

```bash
godot --headless --script preuves/L_TestDirectorRun.gd
```

**Sortie attendue :**
```
=== TEST DIRECTOR RUN ===

Salle 1: Salle001 (combat)
Salle 2: Salle002 (combat)
Salle 3: Salle003 (boss)
Run terminé
=== FIN : run director fonctionne ===
```

## Test 6 : Anti-clone

```bash
python -X utf8 tools/verifier_tokens.py
```

**Sortie attendue :**
```
=== VÉRIFICATION ANTI-CLONE ===

Tokens originaux: 1392
Tokens LOGICOR: 78
Collisions: 0
Mots interdits trouvés: 0
Statut: OK
```

## Conclusion

Tous les tests passent. L'IA est fonctionnelle.
