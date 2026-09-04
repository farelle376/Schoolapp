<?php
// database/seeders/PaiementSeeder.php

namespace Database\Seeders;

use App\Models\Eleve;
use App\Models\Paiement;
use App\Models\TranchePaiement;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class PaiementSeeder extends Seeder
{
    public function run(): void
    {
        $tranchesPayees = TranchePaiement::where('statut', 'paye')->get();
        
        foreach ($tranchesPayees as $tranche) {
            Paiement::create([
                'eleve_id' => $tranche->eleve_id,
                'tranche_id' => $tranche->id,
                'reference' => 'RECU-' . strtoupper(Str::random(8)) . '-' . $tranche->eleve_id . '-' . $tranche->numero_tranche,
                'numero_tranche' => $tranche->numero_tranche,
                'libelle' => $tranche->libelle,
                'montant' => $tranche->montant,
                'statut' => 'valide',
                'description' => $tranche->description,
                'date_paiement' => now()->subDays(rand(1, 90)),
                'mode_paiement' => ['MTN', 'Moov', 'Celtis'][rand(0, 2)],
            ]);
        }
        
        $this->command->info('✅ Paiements historiques créés !');
        $this->command->info('📊 Total: ' . Paiement::count() . ' paiements');
    }
}