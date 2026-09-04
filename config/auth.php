<?php
// config/auth.php

return [
    'defaults' => [
        'guard' => 'web',
        'passwords' => 'users',
    ],

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'sanctum',
            'provider' => 'parents',  // ← Pour les parents
        ],
          'professeur' => [
        'driver' => 'sanctum',
        'provider' => 'professeurs',
    ],
    ],

    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Models\Utilisateur::class,
        ],

        'parents' => [
            'driver' => 'eloquent',
            'model' => App\Models\ParentModel::class,
        ],
         'professeurs' => [
        'driver' => 'eloquent',
        'model' => App\Models\Professeur::class,
    ],
       
    ],

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_resets',
            'expire' => 60,
            'throttle' => 60,
        ],
    ],

    
];