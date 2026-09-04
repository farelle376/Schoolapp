<?php
// database/seeders/ParentModelSeeder.php

namespace Database\Seeders;

use App\Models\ParentModel;
use Illuminate\Database\Seeder;

class ParentModelSeeder extends Seeder
{
    public function run(): void
    {
        // Vider la table avant d'insérer
       
        
        $parents = [
            [
                'nom' => 'Diallo',
                'prenom' => 'Mamadou',
                'type_parent' => 'pere',
                'num_telephone' => '0141644052',
                'email' => 'mamadou.diallo@ecole.sn',
                'is_active' => true,
            ],
            [
                'nom' => 'Diallo',
                'prenom' => 'Aissatou',
                'type_parent' => 'mere',
                'num_telephone' => '7812345670',
                'email' => 'aissatou.diallo@ecole.sn',
                'is_active' => true,
            ],
            [
                'nom' => 'Ndiaye',
                'prenom' => 'Oumar',
                'type_parent' => 'pere',
                'num_telephone' => '0196939641',
                'email' => 'oumar.ndiaye@ecole.sn',
                'is_active' => true,
            ],
            [
                'nom' => 'Ndiaye',
                'prenom' => 'Fatou',
                'type_parent' => 'mere',
                'num_telephone' => '7823456780',
                'email' => 'fatou.ndiaye@ecole.sn',
                'is_active' => true,
            ],
            [
                'nom' => 'Sow',
                'prenom' => 'Ibrahima',
                'type_parent' => 'pere',
                'num_telephone' => '7734567890',
                'email' => 'ibrahima.sow@ecole.sn',
                'is_active' => true,
            ],
            [
                'nom' => 'Sow',
                'prenom' => 'Mariama',
                'type_parent' => 'mere',
                'num_telephone' => '7834567890',
                'email' => 'mariama.sow@ecole.sn',
                'is_active' => true,
            ],
        ];
        
        foreach ($parents as $parent) {
            ParentModel::create($parent);
        }
        
        $this->command->info('✅ ' . ParentModel::count() . ' parents créés');
        
        // Afficher les parents avec leurs IDs
        $allParents = ParentModel::all();
        foreach ($allParents as $parent) {
            $this->command->info("ID: {$parent->id} - {$parent->prenom} {$parent->nom} - Tél: {$parent->num_telephone}");
        }
    }
}