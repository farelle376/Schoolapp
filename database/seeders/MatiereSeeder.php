<?php

namespace Database\Seeders;

use App\Models\Matiere;
use Illuminate\Database\Seeder;

class MatiereSeeder extends Seeder
{
    public function run(): void
    {
        $matieres = [
            ['nom' => 'Mathématiques', 'coefficient' => 4],
            ['nom' => 'Français', 'coefficient' => 4],
            ['nom' => 'Anglais', 'coefficient' => 3],
            ['nom' => 'Histoire-Géographie', 'coefficient' => 2],
            ['nom' => 'Physique-Chimie', 'coefficient' => 3],
            ['nom' => 'SVT', 'coefficient' => 2],
            ['nom' => 'Philosophie', 'coefficient' => 2],
            ['nom' => 'EPS', 'coefficient' => 1],
            ['nom' => 'Economie', 'coefficient' => 1],
            ['nom' => 'Espagnol', 'coefficient' => 2],
        ];

        foreach ($matieres as $matiere) {
            Matiere::create($matiere);
        }
    }
}