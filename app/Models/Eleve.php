<?php
// app/Models/Eleve.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Eleve extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'prenom',
        'sexe',
        'num_papa',
        'num_maman',
        'classe_id',
    ];

    // Relations
    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    public function notes()
    {
        return $this->hasMany(Note::class);
    }

    public function paiements()
    {
        return $this->hasMany(Paiement::class);
    }

    public function getFullNameAttribute()
    {
        return $this->prenom . ' ' . $this->nom;
    }
     public function bulletins()
    {
        return $this->hasMany(Bulletin::class);
    }

    public function parents()
    {
        return $this->belongsToMany(Famille::class, 'parent_eleves', 'eleve_id', 'parent_id')
                    ->withPivot('type_parent')
                    ->withTimestamps();
    }
}