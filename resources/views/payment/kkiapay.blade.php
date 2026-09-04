<!DOCTYPE html>
<html>
<head>
    <title>Paiement - SchoolApp</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- SDK officiel KKiaPay : c'est lui qui affiche le vrai formulaire de
         paiement (mobile money / carte) et gère la saisie/l'OTP. Remplace
         l'ancienne page "simulation" (choix MTN/Moov/Celtis + bouton qui
         fait juste semblant d'avoir payé) qui ne passait jamais par KKiaPay. -->
    <script src="https://cdn.kkiapay.me/k.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #0D2B4E 0%, #1F4E79 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
            margin: 0;
        }
        .container {
            max-width: 500px;
            width: 100%;
            background: white;
            border-radius: 24px;
            padding: 24px;
            text-align: center;
        }
        .info-card {
            background: #f5f7fa;
            padding: 16px;
            border-radius: 16px;
            margin: 20px 0;
            text-align: left;
        }
        .info-card p { margin: 6px 0; }
        .sandbox-badge {
            display: inline-block;
            background: #fff3e0;
            color: #b45309;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        button {
            background: #F47C3C;
            color: white;
            border: none;
            padding: 16px 32px;
            border-radius: 40px;
            font-size: 18px;
            cursor: pointer;
            margin-top: 10px;
            width: 100%;
        }
        button:disabled { opacity: 0.6; cursor: default; }
        .cancel-link {
            display: block;
            margin-top: 16px;
            color: #888;
            font-size: 13px;
            text-decoration: none;
        }
        #statusMsg { margin-top: 14px; font-size: 14px; color: #555; min-height: 18px; }
    </style>
</head>
<body>
    <div class="container">
        @if($kkiapaySandbox)
            <div class="sandbox-badge">🧪 MODE TEST (sandbox)</div><br>
        @endif
        <h1>School<span style="color:#F47C3C">App</span></h1>
        <h2>{{ number_format($amount, 0, ',', ' ') }} FCFA</h2>

        <div class="info-card">
            <p>📱 Téléphone : {{ $phone }}</p>
            <p>👤 Payeur : {{ $name }}</p>
            <p>📧 Email : {{ $email }}</p>
            <p>🧾 Tranche : {{ $tranche->libelle }}</p>
        </div>

        <button id="payBtn">PAYER {{ number_format($amount, 0, ',', ' ') }} FCFA</button>
        <a href="#" class="cancel-link" onclick="annuler(); return false;">Annuler</a>
        <div id="statusMsg"></div>
    </div>

    <script>
        const paiementId = {{ $paiementId ?? 'null' }};

        document.getElementById('payBtn').addEventListener('click', function () {
            this.disabled = true;
            document.getElementById('statusMsg').innerText = 'Ouverture du paiement...';

            // Ouvre le vrai widget KKiaPay (mobile money / carte / wallet).
            // 'data' est renvoyé tel quel dans la réponse : on y glisse notre
            // paiement_id pour pouvoir le retrouver côté serveur.
            const widgetConfig = {
                amount: {{ (int) $amount }},
                key: "{{ $kkiapayPublicKey }}",
                sandbox: {{ $kkiapaySandbox ? 'true' : 'false' }},
                phone: "{{ $phone }}",
                name: "{{ $name }}",
                email: "{{ $email }}",
                data: JSON.stringify({ paiement_id: paiementId }),
                position: "center",
            };
            openKkiapayWidget(widgetConfig);
        });

        // Déclenché par le SDK KKiaPay quand la transaction est terminée côté
        // widget. On renvoie l'app Flutter vers la vérification serveur.
        addSuccessListener(function (response) {
            const transactionId = response.transactionId || response.transaction_id;
            document.getElementById('statusMsg').innerText = 'Vérification du paiement...';
            window.location.href =
                "schoolapp://payment/success?transaction_id=" + encodeURIComponent(transactionId) +
                "&paiement_id=" + paiementId;
        });

        // Déclenché par le SDK KKiaPay quand la transaction échoue DANS le
        // widget lui-même (numéro invalide, fonds insuffisants, refus...).
        addFailedListener(function (response) {
            document.getElementById('statusMsg').innerText = 'Paiement échoué...';
            window.location.href = "schoolapp://payment/failed?paiement_id=" + paiementId;
        });

        function annuler() {
            window.location.href = "schoolapp://payment/cancel?paiement_id=" + paiementId;
        }
    </script>
</body>
</html>
