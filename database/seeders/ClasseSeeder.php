<?php

namespace Database\Seeders;

use App\Models\Classe;
use Illuminate\Database\Seeder;

class ClasseSeeder extends Seeder
{
    public function run(): void
    {
        $classes = [
            ['nom' => '6ème', 'effectif' => 60],
            ['nom' => '5ème', 'effectif' => 40],
            ['nom' => '4ème', 'effectif' => 35],
            ['nom' => '3ème', 'effectif' => 30],
            ['nom' => '2nd AB', 'effectif' => 30],
            ['nom' => '2nd C', 'effectif' => 30],
            ['nom' => '2nd D', 'effectif' => 30],
            ['nom' => '1ere AB', 'effectif' => 25],
            ['nom' => '1ere C', 'effectif' => 25],
            ['nom' => '1ere D', 'effectif' => 25],
            ['nom' => 'Tle AB', 'effectif' => 20],
            ['nom' => 'Tle C', 'effectif' => 20],
            ['nom' => 'Tle D', 'effectif' => 20],
            
        ];

        foreach ($classes as $classe) {
            Classe::create($classe);
        }
    }
}