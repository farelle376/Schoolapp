<?php

namespace Database\Seeders;

use App\Models\Utilisateur;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UtilisateurSeeder extends Seeder
{
    public function run(): void
    {
        // Créer un administrateur principal
        Utilisateur::create([
            'name' => 'AdminEcole',
            'email' => 'admin@ecole.com',
            'password' => Hash::make('admin123'),
        ]);

        $this->command->info('Admin créé: admin@ecole.sn / admin123');
    }
}