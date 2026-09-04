<?php

namespace Database\Seeders;

use App\Models\Eleve;
use App\Models\Classe;
use Illuminate\Database\Seeder;

class EleveSeeder extends Seeder
{
    public function run(): void
    {
        $classes = Classe::all();
        
        $eleves = [];
        
        // Générer 50 élèves répartis dans les classes
        for ($i = 1; $i <= 50; $i++) {
            $classe = $classes->random();
            $prenoms = ['Beltrand', 'Akim', 'Franceline', 'Ernest', 'Justine', 'Mariama', 'Siméon', 'Modeste', 'Curie', 'Bathélémy'];
            $noms = ['ADJOVI', 'LALEYE', 'SOUROU', 'SINGBO', 'NOUKONMIN', 'OGOU', 'YAYA', 'KOUZOU', 'CHOUCHOU', 'ABALOU'];
            
            $prenom = $prenoms[array_rand($prenoms)];
            $nom = $noms[array_rand($noms)];
            $numPapa = rand(40000000, 99999999);
            $numMaman = rand(4000000, 99999999);
            
            $eleves[] = [
                'nom' => $nom,
                'prenom' => $prenom,
                'num_papa' => $numPapa,
                'num_maman' => $numMaman,
                'classe_id' => $classe->id,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }
        
        // Insérer par lots de 10 pour éviter les problèmes de mémoire
        foreach (array_chunk($eleves, 10) as $chunk) {
            Eleve::insert($chunk);
        }
    }
}