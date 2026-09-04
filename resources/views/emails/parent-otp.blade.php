<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code de connexion - SchoolApp</title>
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
        .otp-code {
            background-color: #f0f2f5;
            padding: 20px;
            text-align: center;
            border-radius: 12px;
            margin: 20px 0;
        }
        .otp-code .code {
            font-size: 42px;
            font-weight: bold;
            letter-spacing: 8px;
            color: #0D2B4E;
            font-family: monospace;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #6c757d;
            border-top: 1px solid #dee2e6;
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
        .warning {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 12px;
            margin: 20px 0;
            font-size: 13px;
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
            <h2>Bonjour {{ $parent->prenom }} {{ $parent->nom }} !</h2>
            
            <p>Vous avez demandé à vous connecter à votre espace parent SchoolApp.</p>
            
            <p>Voici votre code de vérification à usage unique :</p>
            
            <div class="otp-code">
                <div class="code">{{ $otp }}</div>
                <p style="margin-top: 10px; color: #6c757d; font-size: 12px;">Code valable 10 minutes</p>
            </div>
            
            <p>Ce code vous permettra d'accéder à :</p>
            <ul>
                <li>📊 Les notes et résultats de votre/vos enfant(s)</li>
                <li>📅 L'emploi du temps</li>
                <li>💰 Le suivi des paiements</li>
                <li>🔔 Les notifications de l'école</li>
            </ul>
            
            <div class="warning">
                ⚠️ <strong>Attention :</strong> Ne partagez jamais ce code avec personne. Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet email.
            </div>
            
            <p style="text-align: center;">
                <a href="#" class="btn">Ouvrir l'application</a>
            </p>
        </div>
        
        <div class="footer">
            <p>&copy; {{ date('Y') }} SchoolApp - Tous droits réservés</p>
            <p>Ceci est un message automatique, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>