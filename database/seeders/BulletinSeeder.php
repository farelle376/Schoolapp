<?php
// database/seeders/BulletinSeeder.php

namespace Database\Seeders;

use App\Models\Bulletin;
use App\Models\Eleve;
use Illuminate\Database\Seeder;

class BulletinSeeder extends Seeder
{
    public function run()
    {
        $eleves = Eleve::all();
        $trimestres = ['1', '2', '3'];

        foreach ($eleves as $eleve) {
            foreach ($trimestres as $trimestre) {
                $moyenne = rand(80, 180) / 10; // Entre 8.0 et 18.0
                
                Bulletin::create([
                    'eleve_id' => $eleve->id,
                    'classe_id' => $eleve->classe_id,
                    'trimestre' => $trimestre,
                    'moyenne_generale' => $moyenne,
                    'mention' => Bulletin::getMention($moyenne),
                    'appreciation' => 'Appréciation automatique pour le trimestre ' . $trimestre,
                    'notes_data' => [],
                ]);
            }
        }
    }
}