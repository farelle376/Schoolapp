<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Classe extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'libelle',
        'niveau',
        'effectif',
    ];

    // La table `classes` stocke le nom de la classe dans la colonne
    // `libelle` (pas `nom`). Cet accesseur/mutateur permet à tout le code
    // existant qui lit/écrit `->nom` de continuer à fonctionner sans
    // modification, tout en enregistrant réellement dans `libelle`.
    public function getNomAttribute()
    {
        return $this->attributes['libelle'] ?? null;
    }

    public function setNomAttribute($value)
    {
        $this->attributes['libelle'] = $value;
    }

    public function eleves()
    {
        return $this->hasMany(Eleve::class);
    }

    // Relation avec les matières via la table pivot avec coefficient
    public function matieres()
    {
        return $this->belongsToMany(Matiere::class, 'matiere_classe')
                    ->withPivot('coefficient')
                    ->withTimestamps();
    }

    public function getNomCompletAttribute()
    {
        return "{$this->nom} {$this->effectif}";
    }

    public function getEffectifAttribute()
    {
        return $this->eleves()->count();
    }

    // Savoir si c'est un collège ou lycée
    public function isCollege()
    {
        $collegeLevels = ['6ème', '5ème', '4ème', '3ème'];
        return in_array($this->nom, $collegeLevels);
    }
     public function bulletins()
    {
        return $this->hasMany(Bulletin::class);
    }

    public function isLycée()
    {
        $lyceeLevels = ['Seconde_AB', 'Seconde_C', 'Seconde_D', 'Première_AB', 'Première_C', 'Première_D', 'Terminale_AB', 'Terminale_C', 'Terminale_D'];
        return in_array($this->nom, $lyceeLevels);
    }
}
