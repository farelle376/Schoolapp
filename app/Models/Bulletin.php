<?php
// app/Models/Bulletin.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bulletin extends Model
{
    use HasFactory;

    protected $fillable = [
        'eleve_id',
        'classe_id',
        'trimestre',
        'moyenne_generale',
        'mention',
        'appreciation',
        'rang',
        'total_eleves',
        'notes_data',
    ];

    protected $casts = [
        'notes_data' => 'array',
        'moyenne_generale' => 'float',
    ];

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function classe()
    {
        return $this->belongsTo(Classe::class);
    }

    // Calculer la mention en fonction de la moyenne
    public static function getMention($moyenne)
    {
        if ($moyenne >= 16) return 'Très Bien';
        if ($moyenne >= 14) return 'Bien';
        if ($moyenne >= 12) return 'Assez Bien';
        if ($moyenne >= 10) return 'Passable';
        return 'Insuffisant';
    }
}