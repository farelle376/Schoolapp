<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
class Professeur extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'password',
        'numero',
        'matiere_id',
        'code',
        'first_login',

    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Relations
    public function matiere()
    {
        return $this->belongsTo(Matiere::class);
    }

    // L'association professeur ↔ classe se fait via classe_annee_matieres
    // (classe + année scolaire + matière + professeur). Il n'y a plus de
    // table pivot classe_professeur.
    public function classeAnneeMatieres()
    {
        return $this->hasMany(ClasseAnneeMatiere::class);
    }
}
