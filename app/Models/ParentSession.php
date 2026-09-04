<?php
// app/Models/ParentSession.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ParentSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'parent_id',
        'token',
        'eleves_ids',
        'expires_at',
        'last_activity',
    ];

    protected $casts = [
        'eleves_ids' => 'array',
        'expires_at' => 'datetime',
        'last_activity' => 'datetime',
    ];

    public function parent()
    {
        return $this->belongsTo(Famille::class, 'parent_id');
    }
}