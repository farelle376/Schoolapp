<?php
// app/Http/Controllers/PaymentController.php

namespace App\Http\Controllers;

use App\Models\TranchePaiement;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function showPaymentPage($trancheId, Request $request)
    {
        $tranche = TranchePaiement::findOrFail($trancheId);

        $amount = $request->query('amount', $tranche->montant);
        $phone = $request->query('phone', '97000000');
        $name = $request->query('name', 'Parent');
        $email = $request->query('email', 'parent@schoolapp.com');
        $paiementId = $request->query('paiement_id');
        // ⚠️ Ces deux valeurs manquaient : sans elles, la vue affichait le
        // widget KKiaPay avec une clé publique vide ($kkiapayPublicKey non
        // définie), ce qui l'empêchait de fonctionner.
        $kkiapayPublicKey = config('services.kkiapay.public_key');
        $kkiapaySandbox = config('services.kkiapay.sandbox');

        return view('payment.kkiapay', compact(
            'tranche', 'amount', 'phone', 'name', 'email', 'trancheId', 'paiementId',
            'kkiapayPublicKey', 'kkiapaySandbox'
        ));
    }
}
