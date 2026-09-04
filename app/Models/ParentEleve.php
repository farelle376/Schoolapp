<?php
// app/Models/AnneeScolaire.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ParentEleve extends Pivot
{
    use HasFactory;

    protected $table = 'parent_eleves';

    protected $fillable = [
        'type_parent',
    ];
}