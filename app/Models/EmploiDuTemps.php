<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class EmploiDuTemps extends Model
{
    use HasFactory;

    protected $table = 'emplois_du_temps';

    protected $fillable = [
        'classe_id',
        'matiere_id',
        'professeur_id',
        'jour',
        'heure_debut',
        'heure_fin',
        'type_cours',
        'est_active',
    ];

    protected $casts = [
        'heure_debut' => 'datetime:H:i',
        'heure_fin' => 'datetime:H:i',
        'est_active' => 'boolean',
    ];

    // Jours de la semaine
    public static $jours = [
        'lundi' => 'Lundi',
        'mardi' => 'Mardi',
        'mercredi' => 'Mercredi',
        'jeudi' => 'Jeudi',
        'vendredi' => 'Vendredi',
        'samedi' => 'Samedi',
    ];

    // Types de cours
    public static $typesCours = [
        'cours' => 'Cours',
        'td' => 'Travaux dirigés',
        'tp' => 'Travaux pratiques',
        'evaluation' => 'Évaluation / Contrôle',
    ];

    // Relations
    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function matiere()
    {
        return $this->belongsTo(Matiere::class);
    }

    public function professeur()
    {
        return $this->belongsTo(Professeur::class);
    }

    // Accessors
    public function getJourLibelleAttribute()
    {
        return self::$jours[$this->jour] ?? $this->jour;
    }

    public function getTypeCoursLibelleAttribute()
    {
        return self::$typesCours[$this->type_cours] ?? $this->type_cours;
    }

    public function getHeureDebutFormattedAttribute()
    {
        return Carbon::parse($this->heure_debut)->format('H:i');
    }

    public function getHeureFinFormattedAttribute()
    {
        return Carbon::parse($this->heure_fin)->format('H:i');
    }

    public function getDureeAttribute()
    {
        $debut = Carbon::parse($this->heure_debut);
        $fin = Carbon::parse($this->heure_fin);
        $minutes = $debut->diffInMinutes($fin);
        $heures = floor($minutes / 60);
        $minutesRestantes = $minutes % 60;
        
        if ($heures > 0 && $minutesRestantes > 0) {
            return "{$heures}h{$minutesRestantes}";
        } elseif ($heures > 0) {
            return "{$heures}h";
        }
        return "{$minutesRestantes}min";
    }

    public function getHoraireAttribute()
    {
        return $this->heure_debut_formatted . ' - ' . $this->heure_fin_formatted;
    }

    // Scopes
    public function scopePourClasse($query, $classeId)
    {
        return $query->where('classe_id', $classeId);
    }

    public function scopePourProfesseur($query, $professeurId)
    {
        return $query->where('professeur_id', $professeurId);
    }

    public function scopePourJour($query, $jour)
    {
        return $query->where('jour', $jour);
    }


    public function scopeActif($query)
    {
        return $query->where('est_active', true);
    }

    public function scopeParOrdreHoraire($query)
    {
        return $query->orderBy('heure_debut');
    }

    // Méthodes utilitaires
    public function verifierConflit()
    {
        // Vérifier si le professeur n'a pas déjà un cours à cette heure
        $conflitProfesseur = EmploiDuTemps::where('professeur_id', $this->professeur_id)
            ->where('jour', $this->jour)
            ->where('est_active', true)
            ->where(function($query) {
                $query->whereBetween('heure_debut', [$this->heure_debut, $this->heure_fin])
                      ->orWhereBetween('heure_fin', [$this->heure_debut, $this->heure_fin])
                      ->orWhere(function($q) {
                          $q->where('heure_debut', '<=', $this->heure_debut)
                            ->where('heure_fin', '>=', $this->heure_fin);
                      });
            })
            ->where('id', '!=', $this->id)
            ->exists();
        
        // Vérifier si la classe n'a pas déjà un cours à cette heure
        $conflitClasse = EmploiDuTemps::where('classe_id', $this->classe_id)
            ->where('jour', $this->jour)
            ->where('est_active', true)
            ->where(function($query) {
                $query->whereBetween('heure_debut', [$this->heure_debut, $this->heure_fin])
                      ->orWhereBetween('heure_fin', [$this->heure_debut, $this->heure_fin])
                      ->orWhere(function($q) {
                          $q->where('heure_debut', '<=', $this->heure_debut)
                            ->where('heure_fin', '>=', $this->heure_fin);
                      });
            })
            ->where('id', '!=', $this->id)
            ->exists();
        
        return [
            'conflit_professeur' => $conflitProfesseur,
            'conflit_classe' => $conflitClasse,
            'has_conflit' => $conflitProfesseur || $conflitClasse
        ];
    }
}