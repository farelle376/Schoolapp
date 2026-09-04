<?php

namespace Database\Seeders;

use App\Models\Notification;
use App\Models\Eleve;
use Illuminate\Database\Seeder;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $eleves = Eleve::all();
        $types = ['note', 'paiement', 'absence', 'bulletin', 'info'];
        $titres = [
            'note' => 'Nouvelle note disponible',
            'paiement' => 'Paiement reçu',
            'absence' => 'Absence signalée',
            'bulletin' => 'Bulletin trimestriel',
            'info' => 'Information importante'
        ];
        
        $notifications = [];
        
        foreach ($eleves as $eleve) {
            // 5 notifications par élève
            for ($i = 0; $i < 5; $i++) {
                $type = $types[array_rand($types)];
                $parentPhone = rand(0, 1) ? $eleve->num_papa : $eleve->num_maman;
                
                if ($parentPhone) {
                    $notifications[] = [
                        'eleve_id' => $eleve->id,
                        'type' => $type,
                        'titre' => $titres[$type],
                        'contenu' => "Ceci est une notification de test concernant {$eleve->prenom} {$eleve->nom}",
                        'data' => json_encode(['test' => true]),
                        'destinataire_phone' => $parentPhone,
                        'statut' => 'envoye',
                        'envoye_at' => now()->subDays(rand(1, 30)),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
            }
        }
        
        foreach (array_chunk($notifications, 50) as $chunk) {
            Notification::insert($chunk);
        }
    }
}