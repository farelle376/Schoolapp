<?php

namespace App\Helpers;

use App\Models\Classe;

class SchoolHelper
{
    /**
     * Afficher le tableau des coefficients par classe
     */
    public static function getCoefficientsTable()
    {
        $classes = Classe::with('matieres')->get();
        $result = [];
        
        foreach ($classes as $classe) {
            $result[$classe->nom_complet] = [];
            foreach ($classe->matieres as $matiere) {
                $result[$classe->nom_complet][$matiere->nom] = $matiere->pivot->coefficient;
            }
        }
        
        return $result;
    }
    
    /**
     * Calculer la moyenne d'un élève pour un trimestre
     */
    public static function calculateMoyenne($eleveId, $trimestre)
    {
        $eleve = \App\Models\Eleve::with('classe.matieres')->find($eleveId);
        $notes = \App\Models\Note::where('eleve_id', $eleveId)
            ->where('trimestre', $trimestre)
            ->with('matiere')
            ->get();
        
        $totalNotes = 0;
        $totalCoefficients = 0;
        
        foreach ($notes as $note) {
            $coefficient = $note->matiere->getCoefficientForClasse($eleve->classe_id);
            $totalNotes += $note->note * $coefficient;
            $totalCoefficients += $coefficient;
        }
        
        return $totalCoefficients > 0 ? round($totalNotes / $totalCoefficients, 2) : 0;
    }
}