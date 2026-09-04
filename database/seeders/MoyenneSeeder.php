<?php

namespace Database\Seeders;

use App\Models\Moyenne;
use App\Models\Eleve;
use App\Models\Note;
use Illuminate\Database\Seeder;

class MoyenneSeeder extends Seeder
{
    public function run(): void
    {
        $eleves = Eleve::with('classe.matieres')->get();
        $trimestres = ['1', '2', '3'];
        
        foreach ($eleves as $eleve) {
            foreach ($trimestres as $trimestre) {
                // Récupérer les notes de l'élève pour ce trimestre
                $notes = Note::where('eleve_id', $eleve->id)
                    ->where('trimestre', $trimestre)
                    ->with('matiere')
                    ->get();
                
                $totalNotes = 0;
                $totalCoefficients = 0;
                
                foreach ($notes as $note) {
                    // Récupérer le coefficient de la matière pour cette classe
                    $coefficient = $note->matiere->getCoefficientForClasse($eleve->classe_id);
                    $totalNotes += $note->note * $coefficient;
                    $totalCoefficients += $coefficient;
                }
                
                $moyenne = $totalCoefficients > 0 ? $totalNotes / $totalCoefficients : 0;
                
                // Calculer le rang (simplifié pour le seeder)
                
                Moyenne::create([
                    'eleve_id' => $eleve->id,
                    'trimestre' => $trimestre,
                    'moyenne' => round($moyenne, 2),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }
}