<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Ordre d'exécution important
        $this->call([
            UtilisateurSeeder::class,  
            ClasseSeeder::class,
            MatiereSeeder::class,
            MatiereClasseSeeder::class, // Nouveau seeder pour les coefficients
            ProfesseurSeeder::class,
            EleveSeeder::class,
            EmploiDuTempsSeeder::class,
            NoteSeeder::class,
            MoyenneSeeder::class,
            PaiementSeeder::class,
            TranchePaiementSeeder::class,
            BulletinSeeder::class,
            NotificationSeeder::class,
            ParentModelSeeder::class,
        ]);
        
        $this->command->info('Toutes les données ont été insérées avec succès !');
    }
}