<?php
// app/Services/InscriptionService.php

namespace App\Services;

use App\Models\Inscription;
use App\Models\Eleve;

class InscriptionService
{
    public function getElevesByClasseAndAnnee($classeId, $anneeId)
    {
        return Eleve::whereHas('inscriptions', function ($query) use ($classeId, $anneeId) {
            $query->where('classe_id', $classeId)
                  ->where('annee_scolaire_id', $anneeId)
                  ->where('statut', 'actif');
        })->get();
    }

    public function getClasseActuelle($eleveId)
    {
        $inscription = Inscription::where('eleve_id', $eleveId)
                                  ->where('statut', 'actif')
                                  ->with('classe')
                                  ->first();
        return $inscription ? $inscription->classe : null;
    }

    // Autres méthodes d'inscription (créer, transférer, etc.)
}