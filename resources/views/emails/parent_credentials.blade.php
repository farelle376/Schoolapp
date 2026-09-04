<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inscription - SchoolApp</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f7fc;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: linear-gradient(135deg, #0D2B4E 0%, #1F4E79 100%);
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            color: white;
            margin: 0;
            font-size: 28px;
        }
        .header span {
            color: #F47C3C;
        }
        .content {
            padding: 30px;
        }
        .info {
            background-color: #f0f2f5;
            padding: 20px;
            border-radius: 12px;
            margin: 20px 0;
        }
        .info p {
            margin: 10px 0;
        }
        .label {
            font-weight: bold;
            color: #0D2B4E;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #6c757d;
            border-top: 1px solid #dee2e6;
        }
        .warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 12px;
            margin: 20px 0;
            font-size: 13px;
        }
        .btn {
            display: inline-block;
            background-color: #F47C3C;
            color: white;
            padding: 12px 24px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: bold;
        }
        .steps {
            margin: 20px 0;
            padding-left: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>School<span>App</span></h1>
            <p style="color: #e0e0e0; margin-top: 10px;">Espace Parent</p>
        </div>
        
        <div class="content">
            <h2>Bonjour <strong>{{ $parent->prenom }} {{ $parent->nom }}</strong> !</h2>
            
            <p>Nous vous informons que vous avez été enregistré en tant que <strong>{{ $typeParent }}</strong> d'élève dans notre application SchoolApp Benin.</p>
            
            <div class="info">
                <p><span class="label">👨‍🎓 Élève :</span> {{ $eleve->prenom }} {{ $eleve->nom }}</p>
                <p><span class="label">🏫 Classe :</span> {{ $eleve->classe->nom }}</p>
                <p><span class="label">📧 Votre email de connexion :</span> {{ $parent->email }}</p>
                <p><span class="label">📱 Votre téléphone :</span> {{ $parent->num_telephone }}</p>
            </div>
            
            <p><strong>Comment accéder à votre espace ?</strong></p>
            <ol class="steps">
                <li>Téléchargez l'application SchoolApp Benin</li>
                <li>Cliquez sur "Connexion Parent"</li>
                <li>Saisissez votre adresse email : <strong>{{ $parent->email }}</strong></li>
                <li>Un code de vérification vous sera envoyé par email</li>
                <li>Saisissez le code reçu pour accéder à votre espace</li>
            </ol>
            
            <p><strong>Ce que vous pourrez faire :</strong></p>
            <ul>
                <li>📊 Consulter les notes et résultats de votre enfant</li>
                <li>📅 Visualiser l'emploi du temps</li>
                <li>💰 Suivre les paiements et frais de scolarité</li>
                <li>🔔 Recevoir les notifications de l'école</li>
                <li>💬 Communiquer avec l'administration</li>
            </ul>
            
            <div class="warning">
                ⚠️ <strong>À savoir :</strong> À chaque connexion, un nouveau code de vérification vous sera envoyé. 
                Ce code est à usage unique et expire après 10 minutes.
            </div>
            
            <p style="text-align: center;">
                <a href="#" class="btn">Accéder à l'application</a>
            </p>
        </div>
        
        <div class="footer">
            <p>&copy; {{ date('Y') }} SchoolApp Benin - Tous droits réservés</p>
            <p>Ceci est un message automatique, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>