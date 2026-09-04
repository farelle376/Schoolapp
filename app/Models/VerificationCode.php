<?php
// app/Models/VerificationCode.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VerificationCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'phone_number',
        'code',
        'type',
        'expires_at',
        'is_used',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'is_used' => 'boolean',
    ];

    public function isValid()
    {
        return !$this->is_used && now()->lessThan($this->expires_at);
    }

    public function markAsUsed()
    {
        $this->update(['is_used' => true]);
    }
}