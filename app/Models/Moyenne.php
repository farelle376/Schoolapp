<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Moyenne extends Model
{
    use HasFactory;

    protected $fillable = [
        'eleve_id',
        'matiere_id',
        'trimestre',
        'moyenne',
    ];
    protected $casts = [
        'moyenne' => 'decimal:2',
    ];

    // Relations
    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    // Accessors
    public function getMoyenneFormattedAttribute()
    {
        return number_format($this->moyenne, 2);
    }

    public function getAppreciationAttribute()
    {
        if ($this->moyenne >= 16) return 'Excellent';
        if ($this->moyenne >= 14) return 'Très bien';
        if ($this->moyenne >= 12) return 'Bien';
        if ($this->moyenne >= 10) return 'Assez bien';
        return 'Insuffisant';
    }
}