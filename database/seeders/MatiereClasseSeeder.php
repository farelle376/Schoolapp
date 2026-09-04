<?php
// database/seeders/ClasseMatiereSeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MatiereClasseSeeder extends Seeder
{

    public function run(): void
    {
      
        // Exemple d'associations
        $associations = [
            // 6eme
            ['classe_id' => 1, 'matiere_id' => 1, 'coefficient' => 1], // Maths
            ['classe_id' => 1, 'matiere_id' => 2, 'coefficient' => 1], // Français
            ['classe_id' => 1, 'matiere_id' => 3, 'coefficient' => 1], // Anglais
            ['classe_id' => 1, 'matiere_id' => 5, 'coefficient' => 1], // PC
            ['classe_id' => 1, 'matiere_id' => 6, 'coefficient' => 1], // SVT
            ['classe_id' => 1, 'matiere_id' => 4, 'coefficient' => 1], // HG
            ['classe_id' => 1, 'matiere_id' => 8, 'coefficient' => 1], // Philo
            
            // 5eme
            ['classe_id' => 2, 'matiere_id' => 1, 'coefficient' => 1], // Maths
            ['classe_id' => 2, 'matiere_id' => 2, 'coefficient' => 1], // Français
            ['classe_id' => 2, 'matiere_id' => 3, 'coefficient' => 1], // Anglais
            ['classe_id' => 2, 'matiere_id' => 5, 'coefficient' => 1], // PC
            ['classe_id' => 2, 'matiere_id' => 6, 'coefficient' => 1], // SVT
            ['classe_id' => 2, 'matiere_id' => 4, 'coefficient' => 1], // HG
            ['classe_id' => 2, 'matiere_id' => 8, 'coefficient' => 1], // Philo

            //4eme
            ['classe_id' => 3, 'matiere_id' => 1, 'coefficient' => 2], // Maths
            ['classe_id' => 3, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 3, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 3, 'matiere_id' => 5, 'coefficient' => 2], // PC
            ['classe_id' => 3, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 3, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' => 3, 'matiere_id' => 10, 'coefficient' => 2], // HG
            ['classe_id' => 3, 'matiere_id' => 8, 'coefficient' => 1], // Philo

            //3eme
             ['classe_id' => 4, 'matiere_id' => 1, 'coefficient' => 3], // Maths
            ['classe_id' => 4, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 4, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 4, 'matiere_id' => 5, 'coefficient' => 2], // PC
            ['classe_id' => 4, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 4, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' => 4, 'matiere_id' => 10, 'coefficient' => 2], // HG
            ['classe_id' => 4, 'matiere_id' => 8, 'coefficient' => 2], // Philo

            //2nd AB
            ['classe_id' => 5, 'matiere_id' => 1, 'coefficient' => 2], // Maths (coeff plus élevé)
            ['classe_id' => 5, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 5, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 5, 'matiere_id' => 9, 'coefficient' => 3], // Philo
            ['classe_id' => 5, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 5, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>5, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 5, 'matiere_id' => 10, 'coefficient' => 2], // Maths sup
            ['classe_id' => 5, 'matiere_id' => 7, 'coefficient' => 2], // Philo

           //2nd C
            ['classe_id' => 6, 'matiere_id' => 1, 'coefficient' => 4], // Maths (coeff plus élevé)
            ['classe_id' => 6, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 6, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 6, 'matiere_id' => 5, 'coefficient' => 4], // Anglais
            ['classe_id' => 6, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 6, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' => 6, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 6, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            //2nd D
           ['classe_id' => 7, 'matiere_id' => 1, 'coefficient' => 3], // Maths (coeff plus élevé)
            ['classe_id' => 7, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 7, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
             ['classe_id' => 7, 'matiere_id' => 5, 'coefficient' => 2], // Anglais
            ['classe_id' => 7, 'matiere_id' => 6, 'coefficient' => 3], // SVT
            ['classe_id' => 7, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>7, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 7, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            // 1ere AB
             ['classe_id' => 8, 'matiere_id' => 1, 'coefficient' => 2], // Maths (coeff plus élevé)
            ['classe_id' => 8, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 8, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 8, 'matiere_id' => 9, 'coefficient' => 3], // Philo
            ['classe_id' => 8, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 8, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>8, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 8, 'matiere_id' => 10, 'coefficient' => 2], // Maths sup
            ['classe_id' => 8, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            // 1ere C
            ['classe_id' => 9, 'matiere_id' => 1, 'coefficient' => 3], // Maths (coeff plus élevé)
            ['classe_id' => 9, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 9, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
             ['classe_id' => 9, 'matiere_id' => 5, 'coefficient' => 3], // Anglais
            ['classe_id' => 9, 'matiere_id' => 6, 'coefficient' => 3], // SVT
            ['classe_id' => 9, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>9, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 9, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            // 1ere D
           ['classe_id' => 10, 'matiere_id' => 1, 'coefficient' => 3], // Maths (coeff plus élevé)
            ['classe_id' => 10, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 10, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
             ['classe_id' => 10, 'matiere_id' => 5, 'coefficient' => 3], // Anglais
            ['classe_id' => 10, 'matiere_id' => 6, 'coefficient' => 3], // SVT
            ['classe_id' => 10, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>10, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 10, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            // Tle AB
            ['classe_id' => 11, 'matiere_id' => 1, 'coefficient' => 2], // Maths (coeff plus élevé)
            ['classe_id' => 11, 'matiere_id' => 2, 'coefficient' => 3], // Français
            ['classe_id' => 11, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
            ['classe_id' => 11, 'matiere_id' => 9, 'coefficient' => 4], // Philo
            ['classe_id' => 11, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 11, 'matiere_id' => 4, 'coefficient' => 3], // HG
            ['classe_id' =>11, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 11, 'matiere_id' => 10, 'coefficient' => 2], // Maths sup
            ['classe_id' => 11, 'matiere_id' => 7, 'coefficient' => 3], // Philo

            //Tle C
            ['classe_id' => 12, 'matiere_id' => 1, 'coefficient' => 4], // Maths (coeff plus élevé)
            ['classe_id' => 12, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 12, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
             ['classe_id' => 12, 'matiere_id' => 5, 'coefficient' => 4], // Anglais
            ['classe_id' => 12, 'matiere_id' => 6, 'coefficient' => 2], // SVT
            ['classe_id' => 12, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>12, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 12, 'matiere_id' => 7, 'coefficient' => 2], // Philo

            // Tle D
             ['classe_id' => 13, 'matiere_id' => 1, 'coefficient' => 4], // Maths (coeff plus élevé)
            ['classe_id' => 13, 'matiere_id' => 2, 'coefficient' => 2], // Français
            ['classe_id' => 13, 'matiere_id' => 3, 'coefficient' => 2], // Anglais
             ['classe_id' => 13, 'matiere_id' => 5, 'coefficient' => 4], // Anglais
            ['classe_id' => 13, 'matiere_id' => 6, 'coefficient' => 4], // SVT
            ['classe_id' => 13, 'matiere_id' => 4, 'coefficient' => 2], // HG
            ['classe_id' =>13, 'matiere_id' => 8, 'coefficient' => 2], // Philo
            ['classe_id' => 13, 'matiere_id' => 7, 'coefficient' => 2], // Philo

           
        ];
        
        foreach ($associations as $assoc) {
            DB::table('matiere_classe')->updateOrInsert(
                [
                    'classe_id' => $assoc['classe_id'],
                    'matiere_id' => $assoc['matiere_id']
                ],
                [
                    'coefficient' => $assoc['coefficient'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
        
        $this->command->info('✅ Associations classe_matiere créées !');
    }
}