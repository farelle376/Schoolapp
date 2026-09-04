<?php
// app/Models/Parent.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class ParentModel extends Model
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $table = 'parents';

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
        // Laravel dérive par défaut la clé étrangère du pivot depuis le nom
        // de la classe : ParentModel -> 'parent_model_id'. Mais la colonne
        // réelle dans `parent_eleves` s'appelle 'parent_id'. On précise donc
        // explicitement les deux clés du pivot.
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

    public function conversations() 
    { 
        return $this->hasMany(Conversation::class); 
    }
    public function notifications() 
    { 
        return $this->hasMany(Notification::class); 
    }
}