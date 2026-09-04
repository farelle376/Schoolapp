<?php

namespace Database\Seeders;

use App\Models\VerificationCode;
use Illuminate\Database\Seeder;

class VerificationCodeSeeder extends Seeder
{
    public function run(): void
    {
        // Ne pas créer de codes de vérification dans les seeders par défaut
        // Ils seront créés dynamiquement lors des demandes de connexion
        $this->command->info('Les codes de vérification sont générés dynamiquement lors des connexions.');
    }
}