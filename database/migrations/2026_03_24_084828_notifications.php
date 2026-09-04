<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('eleve_id')->constrained('eleves')->onDelete('cascade');
            $table->string('type'); // note, paiement, absence, etc.
            $table->string('titre');
            $table->text('contenu');
            $table->json('data')->nullable();
            $table->string('destinataire_phone', 20); // numéro du parent qui a reçu
            $table->enum('statut', ['envoye', 'echoue'])->default('envoye');
            $table->timestamp('envoye_at')->nullable();
            $table->timestamps();
            
            $table->index(['eleve_id', 'destinataire_phone']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};