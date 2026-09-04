<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PaymentController;

Route::get('/payment/kkiapay/{trancheId}', [PaymentController::class, 'showPaymentPage']);
Route::get('/', function () {
    return view('welcome');
});
Route::get('/simple-test', function() {
    return "Route simple fonctionne !";
});