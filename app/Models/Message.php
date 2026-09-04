<?php
// app/Models/Message.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'conversation_id',
        'parent_id',
        'admin_id',
        'message',
        'type',
        'est_lu',
        'lu_at',
    ];

    protected $casts = [
        'est_lu' => 'boolean',
        'lu_at' => 'datetime',
    ];

    public function conversation()
    {
        return $this->belongsTo(Conversation::class);
    }

    public function parent()
    {
        return $this->belongsTo(Famille::class, 'parent_id');
    }

    public function admin()
    {
        return $this->belongsTo(Utilisateur::class, 'admin_id');
    }

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function getEstDeParentAttribute()
    {
        return $this->parent_id !== null;
    }

    public function getEstDeAdminAttribute()
    {
        return $this->admin_id !== null;
    }

    public function getExpediteurAttribute()
    {
        if ($this->parent) {
            return $this->parent->prenom . ' ' . $this->parent->nom;
        }
        if ($this->admin) {
            return $this->admin->name;
        }
        return 'Système';
    }

    public function getTypeLabelAttribute()
    {
        return $this->type === 'general' ? 'Message général' : 'Message pour ' . ($this->eleve->prenom ?? 'élève');
    }
}