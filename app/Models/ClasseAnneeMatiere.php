<?php
// app/Models/AnneeScolaire.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClasseAnneeMatiere extends Model
{
    use HasFactory;

    protected $table = 'classe_annee_matieres';

    protected $fillable = [
        'classe_annee_id',
        'matiere_id',
        'professeur_id',
        'coefficient',
    ];

    public function classeAnnee() 
    { 
        return $this->belongsTo(ClasseAnnee::class);
    }

    public function matiere() 
    { 
        return $this->belongsTo(Matiere::class); 
    }

    public function professeur() 
    { 
        return $this->belongsTo(Professeur::class); 
    }

    public function notes() 
    {
         return $this->hasMany(Note::class); 
    }

    public function moyennes() 
    { 
        return $this->hasMany(Moyenne::class); 
    }

    public function emploisDuTemps() 
    { 
        return $this->hasMany(EmploiDuTemps::class); 
    }
}