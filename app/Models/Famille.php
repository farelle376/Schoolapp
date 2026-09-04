<?php
// app/Models/Famille.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Famille extends Model
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $table = 'familles';

    protected $fillable = [
        'nom',
        'prenom',
        'type_parent',
        'num_telephone',
        'email',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function eleves()
    {
        return $this->belongsToMany(Eleve::class, 'parent_eleves', 'parent_id', 'eleve_id')
                    ->withPivot('type_parent')
                    ->withTimestamps();
    }

    public function getFullNameAttribute()
    {
        return $this->prenom . ' ' . $this->nom;
    }

    public function getInitialesAttribute()
    {
        return strtoupper(substr($this->prenom, 0, 1) . substr($this->nom, 0, 1));
    }
}