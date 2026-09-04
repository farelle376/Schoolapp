<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Note extends Model
{
    use HasFactory;

    protected $fillable = [
        'eleve_id',
        'matiere_id',
        'note',
        'type_note',
        'trimestre',
        'is_validated',
    ];

    protected $casts = [
        'is_validated' => 'boolean',
        'note' => 'decimal:2',
    ];

    // Relations
    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function matiere()
    {
        return $this->belongsTo(Matiere::class);
    }

    // Accessors
    public function getNoteFormattedAttribute()
    {
        return number_format($this->note, 2);
    }

    public function getAppreciationAttribute()
    {
        if ($this->note >= 16) return 'Excellent';
        if ($this->note >= 14) return 'Très bien';
        if ($this->note >= 12) return 'Bien';
        if ($this->note >= 10) return 'Assez bien';
        return 'Insuffisant';
    }
}