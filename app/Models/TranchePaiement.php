<?php
// app/Models/TranchePaiement.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TranchePaiement extends Model
{
    use HasFactory;

    protected $table = 'tranche_paiements';

    protected $fillable = [
        'eleve_id',
        'numero_tranche',
        'libelle',
        'montant',
        'description',
        'date_limite',
        'statut',
    ];

    protected $casts = [
        'date_limite' => 'date',
        'montant' => 'decimal:2',
    ];

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function paiements()
    {
        return $this->hasMany(Paiement::class, 'tranche_id');
    }

    public function getMontantFormattedAttribute()
    {
        return number_format($this->montant, 0, ',', ' ') . ' FCFA';
    }

     public function getClasseAttribute()
    {
        return $this->eleve->classe;
    }


    public function isPaye()
    {
        return $this->statut === 'paye';
    }
}