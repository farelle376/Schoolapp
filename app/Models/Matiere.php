<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Matiere extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
    ];

    // Relation avec les classes via la table pivot avec coefficient
    public function classes()
    {
        return $this->belongsToMany(Classe::class, 'matiere_classe')
                    ->withPivot('coefficient')
                    ->withTimestamps();
    }

    public function notes()
    {
        return $this->hasMany(Note::class);
    }
    
    public function professeurs()
    {
        return $this->hasMany(Professeur::class);
    }
    
    // Obtenir le coefficient pour une classe spécifique
    public function getCoefficientForClasse($classeId)
    {
        $pivot = $this->classes()->where('classe_id', $classeId)->first();
        return $pivot ? $pivot->pivot->coefficient : 1;
    }
}