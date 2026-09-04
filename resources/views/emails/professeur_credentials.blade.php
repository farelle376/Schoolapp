<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue - SchoolApp</title>
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
        .credentials, .info {
            background-color: #f0f2f5;
            padding: 20px;
            border-radius: 12px;
            margin: 20px 0;
        }
        .credentials p, .info p {
            margin: 10px 0;
        }
        .steps {
            margin: 20px 0;
            padding-left: 20px;
        }
        .label {
            font-weight: bold;
            color: #0D2B4E;
        }
        .code {
            font-size: 24px;
            font-weight: bold;
            letter-spacing: 4px;
            color: #F47C3C;
            text-align: center;
            padding: 10px;
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>School<span>App</span></h1>
            <p style="color: #e0e0e0; margin-top: 10px;">Espace Professeur</p>
        </div>
        
        <div class="content">
            <h2>Bonjour <strong>{{ $professeur->prenom }} {{ $professeur->nom }}</strong>,</h2>

            <p>Vous avez été enregistré(e) en tant que professeur sur notre application. Vos informations sont les suivantes :</p>

            <div class="info">
                <p><span class="label">📧 Email :</span> {{ $professeur->email }}</p>
                <p><span class="label">🔑 Mot de passe :</span> <strong>{{ $plainPassword }}</strong></p>
                <p><span class="label">🔐 Code de validation :</span></p>
                <div class="code">{{ $plainCode }}</div>
                <p style="font-size: 12px; text-align: center; margin: 0;">Ce code vous permettra de valider les notes des élèves.</p>
            </div>

            <ol class="steps">
                <li>Pour votre sécurité, vous serez invité(e) à changer vos identifiants à la première connexion</li>
            </ol>

            <div class="warning">
                ⚠️ <strong>À savoir :</strong> Ne partagez jamais vos identifiants avec personne.
                Nous vous recommandons de changer votre mot de passe dès votre première connexion.
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