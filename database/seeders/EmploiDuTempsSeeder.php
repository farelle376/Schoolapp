<?php

namespace Database\Seeders;

use App\Models\EmploiDuTemps;
use App\Models\Classe;
use App\Models\Matiere;
use App\Models\Professeur;
use Illuminate\Database\Seeder;

class EmploiDuTempsSeeder extends Seeder
{
    public function run(): void
    {
        $classes = Classe::all();
        $jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
        
        // Horaires types d'une journée scolaire (8h - 17h)
        $horaires = [
            ['debut' => '08:00', 'fin' => '10:00'],
            ['debut' => '10:00', 'fin' => '12:00'],
            ['debut' => '15:00', 'fin' => '17:00'],
        ];
        
        foreach ($classes as $classe) {
            // Récupérer les matières de la classe
            $matieresClasse = $classe->matieres;
            
          
                foreach ($jours as $jour) {
                    // Ne pas mettre de cours le samedi après-midi
                    $maxCours = ($jour === 'samedi') ? 4 : count($horaires);
                    
                    // Générer 4 à 6 cours par jour
                    $nombreCours = rand(3, min(4, $maxCours));
                    $horairesUtilises = [];
                    
                    for ($i = 0; $i < $nombreCours; $i++) {
                        // Choisir un horaire aléatoire non utilisé
                        $horaireIndex = array_rand($horaires);
                        while (in_array($horaireIndex, $horairesUtilises)) {
                            $horaireIndex = array_rand($horaires);
                        }
                        $horairesUtilises[] = $horaireIndex;
                        $horaire = $horaires[$horaireIndex];
                        
                        // Choisir une matière aléatoire de la classe
                        $matiere = $matieresClasse->random();
                        
                        // Trouver un professeur qui enseigne cette matière
                        $professeur = Professeur::where('matiere_id', $matiere->id)
                            ->whereHas('classes', function($query) use ($classe) {
                                $query->where('classe_id', $classe->id);
                            })
                            ->first();
                        
                        // Si aucun professeur trouvé, en prendre un aléatoire de la matière
                        if (!$professeur) {
                            $professeur = Professeur::where('matiere_id', $matiere->id)->first();
                        }
                        
                        if ($professeur) {
                            // Types de cours selon la matière
                            $typesCours = ['cours', 'td', 'tp', 'evaluation'];
                            $typeCours = $typesCours[array_rand($typesCours)];
                            
                            // Pour les évaluations, moins fréquentes
                            if ($typeCours === 'evaluation' && rand(1, 10) > 2) {
                                $typeCours = 'cours';
                            }
                            
                            // Salle aléatoire
                            
                            EmploiDuTemps::create([
                                'classe_id' => $classe->id,
                                'matiere_id' => $matiere->id,
                                'professeur_id' => $professeur->id,
                                'jour' => $jour,
                                'heure_debut' => $horaire['debut'],
                                'heure_fin' => $horaire['fin'],
                                'type_cours' => $typeCours,
                                'est_active' => true,
                            ]);
                        }
                    }
                }
            
        }
        
        $this->command->info('Emplois du temps créés avec succès !');
        $this->command->info('Total: ' . EmploiDuTemps::count() . ' cours planifiés');
    }
}