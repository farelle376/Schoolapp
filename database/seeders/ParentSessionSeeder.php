<?php

namespace Database\Seeders;

use App\Models\ParentSession;
use Illuminate\Database\Seeder;

class ParentSessionSeeder extends Seeder
{
    public function run(): void
    {
        // Ne pas créer de sessions dans les seeders
        // Elles seront créées lors des connexions des parents
        $this->command->info('Les sessions parents sont créées dynamiquement lors des connexions.');
    }
}