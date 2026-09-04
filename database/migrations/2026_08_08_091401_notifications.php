<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();

            $table->foreignId('inscription_id')
            ->constrained('inscriptions')
            ->onDelete('cascade');

            $table->string('type'); // note, paiement, absence, etc.
            $table->string('titre');
            $table->text('contenu');
            $table->json('data')->nullable();
            $table->string('destinataire_phone', 20); // numéro du parent qui a reçu
            $table->enum('statut', ['envoye', 'echoue'])->default('envoye');
            $table->timestamp('envoye_at')->nullable();
            $table->timestamps();
            
            $table->index(['inscription_id', 'destinataire_phone']);
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
