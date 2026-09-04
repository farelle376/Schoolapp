<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_tranches_paiement_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tranches_paiement', function (Blueprint $table) {
            $table->id();
            $table->foreignId('eleve_id')->constrained('eleves')->onDelete('cascade');
            $table->integer('numero_tranche'); // 1, 2, 3, 4
            $table->string('libelle'); // "Inscription", "1ère Tranche", etc.
            $table->decimal('montant', 10, 2);
            $table->text('description')->nullable();
            $table->date('date_limite')->nullable();
            $table->enum('statut', ['paye', 'non_paye', 'partiel'])->default('non_paye');
            $table->timestamps();
            
            $table->unique(['eleve_id', 'numero_tranche']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tranches_paiement');
    }
};