<?php
// app/Mail/ResetPasswordMail.php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ResetPasswordMail extends Mailable
{
    use Queueable, SerializesModels;

    public $code;
    public $name;

    public function __construct($code, $name)
    {
        $this->code = $code;
        $this->name = $name;
    }

    public function build()
    {
        return $this->subject('Réinitialisation de votre mot de passe - SchoolApp')
                    ->view('emails.reset-password')
                    ->with([
                        'code' => $this->code,
                        'name' => $this->name,
                    ]);
    }
}