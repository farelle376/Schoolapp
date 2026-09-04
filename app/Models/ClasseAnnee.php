<?php
// app/Models/AnneeScolaire.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClasseAnnee extends Model
{
    use HasFactory;

    protected $table = 'classe_annees';

    protected $fillable = [
        'classe_id',
        'annee_scolaire_id',
        'effectif',
    ];

    public function classe() 
    { 
        return $this->belongsTo(Classe::class);
    }

    public function anneeScolaire() 
    { 
        return $this->belongsTo(AnneeScolaire::class); 
    }

    public function inscriptions()
    { 
        return $this->hasMany(Inscription::class);
    }

    public function classeAnneeMatieres() 
    { 
        return $this->hasMany(ClasseAnneeMatiere::class); 
    }

    public function getEffectifAttribute()
    {
        return $this->inscriptions()->count();
    }
    
}