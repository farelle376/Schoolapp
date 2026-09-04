<?php
// app/Models/NotificationParent.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationParent extends Model
{
    use HasFactory;

    protected $table = 'notifications_parents';

    protected $fillable = [
        'parent_id',
        'titre',
        'message',
        'type',
        'est_lu',
        'lu_at',
    ];

    protected $casts = [
        'est_lu' => 'boolean',
        'lu_at' => 'datetime',
    ];

    // Relations
    public function parent()
    {
        return $this->belongsTo(Famille::class, 'parent_id');
    }
     public function eleve()
    {
        return $this->belongsTo(Eleve::class, 'eleve_id');
    }


    public function markAsRead()
    {
        $this->update([
            'est_lu' => true,
            'lu_at' => now(),
        ]);
    }
}