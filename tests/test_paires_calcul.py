"""Les familles des shaders de calcul : ce qu'une demande montre, et les fautes de compilation, sans Godot."""

from usine.paires import calcul
from usine.paires import shader_fonction as sf

GLSL = """#[compute]
#version 450

// Le transport : chaque case reçoit la valeur d'où vient le courant.
// Une seconde ligne.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D source;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// La valeur de `source` dans la case `cell`.
float source_at(ivec2 cell) {
	return imageLoad(source, cell).r;
}

// Une invocation par case.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	float value = imageLoad(source, cell).r;
	imageStore(target, cell, vec4(source_at(cell) * constants.delta));
}
"""


def test_les_declarations_sont_lues_avec_leur_nom():
    noms = dict(calcul.declarations(GLSL))
    assert set(noms) == {"target", "source", "constants"}
    assert noms["constants"].endswith("} constants;") and "float delta;" in noms["constants"]


def test_la_demande_montre_ce_que_la_fonction_emploie_et_rien_d_autre():
    fonctions = sf.fonctions(GLSL)
    lecture = next(f for f in fonctions if f.nom == "source_at")
    texte = calcul.contexte(GLSL, lecture, fonctions)
    assert "image2D source" in texte and "image2D target" not in texte and "Constants" not in texte
    assert texte.rstrip().endswith("// À écrire.\n}")


def test_main_voit_ses_images_ses_constantes_et_ce_qu_il_appelle():
    fonctions = sf.fonctions(GLSL)
    principale = next(f for f in fonctions if f.nom == "main")
    texte = calcul.contexte(GLSL, principale, fonctions)
    assert "image2D target" in texte and "Constants" in texte
    assert "float source_at(ivec2 cell) {\n\t…\n}" in texte and "return imageLoad" not in texte


def test_la_tete_du_fichier_est_son_commentaire():
    assert calcul.tete_du_fichier(GLSL) == "Le transport : chaque case reçoit la valeur d'où vient le courant. Une seconde ligne."


def test_les_fautes_de_compilation_visent_ce_que_glslang_refuse():
    fautes = calcul.fautes_compilation("a.glsl", GLSL)
    genres = {f.genre for f in fautes}
    assert {"point_virgule", "cellule_non_signee", "ecriture_flottante", "lecture_vecteur", "constante_nue",
            "image_en_ecriture", "image_en_lecture"} <= genres
    ecriture = next(f for f in fautes if f.genre == "ecriture_flottante")
    assert ecriture.fautif.strip() == "imageStore(target, cell, source_at(cell) * constants.delta);"
    assert ecriture.texte != GLSL and ecriture.juste in GLSL


def test_le_lanceur_d_un_shader_est_la_fonction_qui_le_fait_tourner():
    gd = ('class_name Passe extends RefCounted\n\nconst SIMPLE := "res://1_core/gpu/shaders/a.glsl"\n\nvar _simple: ComputePass\n\n\n'
          'func _init(device: ComputeDevice) -> void:\n\t_simple = ComputePass.new(device, SIMPLE)\n\n\n'
          '## Lance le shader.\nfunc lancer(target: RID) -> void:\n\t_simple.run([target], PackedFloat32Array(), Vector3i.ONE)\n')
    texte = calcul.lanceur({"1_core/gpu/passe.gd": gd}, "1_core/gpu/shaders/a.glsl")
    assert "res://1_core/gpu/passe.gd" in texte and "## Lance le shader." in texte and "_simple.run" in texte
    assert calcul.lanceur({"1_core/gpu/passe.gd": gd}, "1_core/gpu/shaders/b.glsl") is None
