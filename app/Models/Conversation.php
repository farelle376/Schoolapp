<?php
// app/Models/Conversation.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'parent_id',
        'admin_id',
        'eleve_id',
        'sujet',
        'type',
        'statut',
        'dernier_message_at',
    ];

    protected $casts = [
        'dernier_message_at' => 'datetime',
    ];

    public function parent()
    {
        return $this->belongsTo(Famille::class, 'parent_id');
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function eleve()
    {
        return $this->belongsTo(Eleve::class);
    }

    public function messages()
    {
        return $this->hasMany(Message::class)->orderBy('created_at', 'asc');
    }

    public function dernierMessage()
    {
        return $this->hasOne(Message::class)->latest();
    }

    public function getMessagesNonLusCountAttribute()
    {
        return $this->messages()->where('est_lu', false)->where('parent_id', null)->count();
    }
}