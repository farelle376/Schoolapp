<?php
// database/seeders/ParentEleveSeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ParentEleveSeeder extends Seeder
{
    public function run(): void
    {
        // Vider la table pivot
        DB::table('parent_eleve')->truncate();
        
        // Vérifier d'abord les IDs existants
        $parents = DB::table('familles')->get();
        $eleves = DB::table('eleves')->get();
        
        $this->command->info('=========================================');
        $this->command->info('📊 PARENTS DISPONIBLES:');
        foreach ($parents as $parent) {
            $this->command->info("  ID: {$parent->id} - {$parent->prenom} {$parent->nom} - Tél: {$parent->num_telephone}");
        }
        
        $this->command->info('📊 ÉLÈVES DISPONIBLES:');
        foreach ($eleves as $eleve) {
            $this->command->info("  ID: {$eleve->id} - {$eleve->prenom} {$eleve->nom}");
        }
        $this->command->info('=========================================');
        
        // Associations basées sur les IDs que vous avez mentionnés
        $associations = [
            // Mamadou Diallo (ID 1) - Père - Enfants: ID 1, 4, 8, 11
            ['parent_id' => 1, 'eleve_id' => 1, 'type_parent' => 'pere'],
            ['parent_id' => 1, 'eleve_id' => 4, 'type_parent' => 'pere'],
            ['parent_id' => 1, 'eleve_id' => 8, 'type_parent' => 'pere'],
            ['parent_id' => 1, 'eleve_id' => 11, 'type_parent' => 'pere'],
            
            // Aissatou Diallo (ID 2) - Mère - Enfants: ID 1, 4, 8, 11
            ['parent_id' => 2, 'eleve_id' => 1, 'type_parent' => 'mere'],
            ['parent_id' => 2, 'eleve_id' => 4, 'type_parent' => 'mere'],
            ['parent_id' => 2, 'eleve_id' => 8, 'type_parent' => 'mere'],
            ['parent_id' => 2, 'eleve_id' => 11, 'type_parent' => 'mere'],
            
            // Oumar Ndiaye (ID 3) - Père - Enfant: ID 3
            ['parent_id' => 3, 'eleve_id' => 3, 'type_parent' => 'pere'],
            
            // Fatou Ndiaye (ID 4) - Mère - Enfant: ID 3
            ['parent_id' => 4, 'eleve_id' => 3, 'type_parent' => 'mere'],
        ];
        
        $count = 0;
        
        foreach ($associations as $assoc) {
            // Vérifier que les IDs existent
            $parentExists = DB::table('familles')->where('id', $assoc['parent_id'])->exists();
            $eleveExists = DB::table('eleves')->where('id', $assoc['eleve_id'])->exists();
            
            if ($parentExists && $eleveExists) {
                // Vérifier si l'association existe déjà
                $alreadyExists = DB::table('parent_eleve')
                    ->where('parent_id', $assoc['parent_id'])
                    ->where('eleve_id', $assoc['eleve_id'])
                    ->exists();
                
                if (!$alreadyExists) {
                    DB::table('parent_eleve')->insert([
                        'parent_id' => $assoc['parent_id'],
                        'eleve_id' => $assoc['eleve_id'],
                        'type_parent' => $assoc['type_parent'],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                    $count++;
                    
                    $parent = DB::table('familles')->where('id', $assoc['parent_id'])->first();
                    $eleve = DB::table('eleves')->where('id', $assoc['eleve_id'])->first();
                    $this->command->info("✓ {$parent->prenom} {$parent->nom} ({$assoc['type_parent']}) → {$eleve->prenom} {$eleve->nom}");
                }
            } else {
                if (!$parentExists) {
                    $this->command->error("❌ Parent ID {$assoc['parent_id']} n'existe pas");
                }
                if (!$eleveExists) {
                    $this->command->error("❌ Élève ID {$assoc['eleve_id']} n'existe pas");
                }
            }
        }
        
        $this->command->info('=========================================');
        $this->command->info("✅ $count associations parent_eleve créées !");
        $this->command->info('=========================================');
        
        // Afficher le résumé des associations
        $this->command->info('📋 RÉSUMÉ DES ASSOCIATIONS:');
        $summary = DB::table('parent_eleve')
            ->join('familles', 'parent_eleve.parent_id', '=', 'familles.id')
            ->join('eleves', 'parent_eleve.eleve_id', '=', 'eleves.id')
            ->select('familles.prenom as parent_prenom', 'familles.nom as parent_nom',
                    'eleves.prenom as eleve_prenom', 'eleves.nom as eleve_nom',
                    'parent_eleve.type_parent')
            ->get();
        
        foreach ($summary as $item) {
            $this->command->info("  {$item->parent_prenom} {$item->parent_nom} ({$item->type_parent}) → {$item->eleve_prenom} {$item->eleve_nom}");
        }
        $this->command->info('=========================================');
    }
}