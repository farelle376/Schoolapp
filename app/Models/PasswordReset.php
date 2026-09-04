<?php
// app/Models/PasswordReset.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PasswordReset extends Model
{
    use HasFactory;

    protected $table = 'password_resets';

    protected $fillable = [
        'email',
        'token',
        'created_at',
    ];

    public $timestamps = false;

    // Relation avec l'utilisateur
    public function user()
    {
        return $this->belongsTo(Utilisateur::class, 'email', 'email');
    }
}