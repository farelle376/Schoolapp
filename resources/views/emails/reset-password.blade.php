<!-- resources/views/emails/reset-password.blade.php -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Réinitialisation mot de passe</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: #0D2B4E;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 10px;
        }
        .code {
            font-size: 32px;
            font-weight: bold;
            color: #F47C3C;
            text-align: center;
            letter-spacing: 10px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 12px;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>SchoolApp</h2>
        </div>
        <div class="content">
            <h3>Bonjour {{ $name }},</h3>
            <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
            <p>Voici votre code de vérification :</p>
            <div class="code">{{ $code }}</div>
            <p>Ce code est valable pendant 15 minutes.</p>
            <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
        </div>
        <div class="footer">
            <p>&copy; {{ date('Y') }} SchoolApp. Tous droits réservés.</p>
        </div>
    </div>
</body>
</html>