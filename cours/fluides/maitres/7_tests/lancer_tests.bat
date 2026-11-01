@echo off
chcp 65001 > nul
#@ 1-10
rem Lance tous les tests du jeu (GdUnit4) sans fenêtre, à cadence fixe (60 images par seconde).
#@ 11+
rem Lance tous les tests du jeu (GdUnit4) à cadence fixe (60 images par seconde). Un shader de calcul demande une carte :
rem Godot n'en ouvre aucune sans fenêtre, il en ouvre donc une petite, qui se referme à la fin.
rem Le crochet de capture d'OBS peut faire planter l'ouverture d'un appareil local : on le retire pour ce seul lancement.
set DISABLE_VULKAN_OBS_CAPTURE=1
#@ all
rem Adapter GODOT si l'exécutable est ailleurs. Rapport HTML : .godot\rapports_tests\report_N\index.html
set GODOT=D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
cd /d "%~dp0.."
#@ 1-10
"%GODOT%" --headless --path . --fixed-fps 60 -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -rc 1 -rd .godot/rapports_tests -a res://7_tests ++ cadence_fixe
#@ 11+
"%GODOT%" --path . --rendering-driver vulkan --audio-driver Dummy --resolution 64x64 --fixed-fps 60 -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -rc 1 -rd .godot/rapports_tests -a res://7_tests ++ cadence_fixe
#@ all
if errorlevel 1 (echo === AU MOINS UN TEST ECHOUE) else (echo === TOUS LES TESTS PASSENT)
pause
