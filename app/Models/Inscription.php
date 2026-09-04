<?php
// app/Models/Inscription.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Inscription extends Model
{
    use HasFactory;

    protected $table = 'inscriptions';

    protected $fillable = [
        'eleve_id',
        'classe_annee_id',
        'date_inscription',
        'statut',
    ];

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function classeAnnee()
    {
        return $this->belongsTo(ClasseAnnee::class);
    }

    public function notes()
    {
        return $this->hasMany(Note::class);
    }

    public function moyennes() 
    { 
        return $this->hasMany(Moyenne::class); 
    }

public function bulletins()
{
    return $this->hasMany(Bulletin::class);
}

public function paiements()
{
    return $this->hasMany(Paiement::class);
}
}