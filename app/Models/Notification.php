<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'utilisateur_id',
        'titre',
        'contenu',
        'lu',
    ];

    protected $casts = [
        'lu' => 'boolean',
    ];

    // Relations
    public function utilisateur()
    {
        return $this->belongsTo(User::class);
    }
    public function eleve()
    {
        return $this->belongsTo(Eleve::class, 'eleve_id');
    }

    // Scopes
    public function scopeNonLu($query)
    {
        return $query->where('lu', false);
    }

    public function scopeLu($query)
    {
        return $query->where('lu', true);
    }

    // Methods
    public function markAsRead()
    {
        $this->update(['lu' => true]);
    }

    public function markAsUnread()
    {
        $this->update(['lu' => false]);
    }
}