<?php
// app/Models/Paiement.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Paiement extends Model
{
    use HasFactory;

    protected $fillable = [
        'eleve_id',
        'tranche_id',
        'reference',
        'numero_tranche',
        'libelle',
        'montant',
        'statut',
        'description',
        'date_paiement',
        'pdf_path',
        'mode_paiement',
        'telephone',
    ];

    protected $casts = [
        'date_paiement' => 'datetime',
        'montant' => 'decimal:2',
    ];

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function tranche()
    {
        return $this->belongsTo(TranchePaiement::class, 'tranche_id');
    }

    public function getMontantFormattedAttribute()
    {
        return number_format($this->montant, 0, ',', ' ') . ' FCFA';
    }

    public function getClasseAttribute()
    {
        return $this->eleve->classe;
    }

    public function getClasseNomAttribute()
    {
        return $this->eleve->classe->nom ?? 'Non assigné';
    }

    public function isValide()
    {
        return $this->statut === 'valide';
    }
}