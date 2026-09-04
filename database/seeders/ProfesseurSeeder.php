<?php

namespace Database\Seeders;
use App\Models\Professeur;
use App\Models\Matiere;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ProfesseurSeeder extends Seeder
{
    public function run(): void
    {
        $matieres = Matiere::all();
        
        $professeurs = [
            [
                'nom' => 'GBEDJI',
                'prenom' => ' Franc',
                'email' => 'francgbedji@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77123567',
                'matiere_id' => $matieres->where('nom', 'Mathématiques')->first()->id
            ],
            [
                'nom' => ' SINGBO',
                'prenom' => ' Paul',
                'email' => 'paulsingbo@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77235678',
                'matiere_id' => $matieres->where('nom', 'Français')->first()->id
            ],
            [
                'nom' => 'BOCO',
                'prenom' => 'Isaac',
                'email' => 'isaacboco@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77345789',
                'matiere_id' => $matieres->where('nom', 'Anglais')->first()->id
            ],
            [
                'nom' => 'GBADAMASSI',
                'prenom' => 'Moushalaf',
                'email' => 'moushalafgbadamassi@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77456890',
                'matiere_id' => $matieres->where('nom', 'Histoire-Géographie')->first()->id
            ],
            [
                'nom' => 'ASSOGBA',
                'prenom' => 'Merveille',
                'email' => 'merveilleassogba@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77567901',
                'matiere_id' => $matieres->where('nom', 'Physique-Chimie')->first()->id
            ],
            [
                'nom' => 'ADANDE',
                'prenom' => 'Mireille',
                'email' => 'mireilleadande@ecole.sn',
                'password' => Hash::make('password'),
                'numero' => '77679012',
                'matiere_id' => $matieres->where('nom', 'SVT')->first()->id
            ],
        ];

        foreach ($professeurs as $professeur) {
            Professeur::create($professeur);
        }
    }
}