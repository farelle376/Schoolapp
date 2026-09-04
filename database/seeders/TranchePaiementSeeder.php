<?php
// database/seeders/TranchePaiementSeeder.php

namespace Database\Seeders;

use App\Models\Eleve;
use App\Models\TranchePaiement;
use Illuminate\Database\Seeder;

class TranchePaiementSeeder extends Seeder
{
    public function run(): void
    {
        $eleves = Eleve::all();
        
        $tranches = [
            ['numero' => 1, 'libelle' => 'Inscription', 'montant' => 50000, 'description' => 'Frais d\'inscription annuelle', 'date_limite' => '2025-09-30'],
            ['numero' => 2, 'libelle' => '1ère Tranche', 'montant' => 50000, 'description' => 'Frais de scolarité - 1er trimestre', 'date_limite' => '2025-11-30'],
            ['numero' => 3, 'libelle' => '2ème Tranche', 'montant' => 50000, 'description' => 'Frais de scolarité - 2ème trimestre', 'date_limite' => '2026-02-28'],
            ['numero' => 4, 'libelle' => '3ème Tranche', 'montant' => 50000, 'description' => 'Frais de scolarité - 3ème trimestre', 'date_limite' => '2026-05-30'],
        ];
        
        foreach ($eleves as $eleve) {
            foreach ($tranches as $tranche) {
                // 70% de chance que la tranche soit payée
                $estPaye = rand(1, 100) <= 70;
                
                TranchePaiement::create([
                    'eleve_id' => $eleve->id,
                    'numero_tranche' => $tranche['numero'],
                    'libelle' => $tranche['libelle'],
                    'montant' => $tranche['montant'],
                    'description' => $tranche['description'],
                    'date_limite' => $tranche['date_limite'],
                    'statut' => $estPaye ? 'paye' : 'non_paye',
                ]);
            }
        }
        
        $this->command->info('✅ Tranches de paiement créées !');
        $this->command->info('📊 Total: ' . TranchePaiement::count() . ' tranches');
    }
}