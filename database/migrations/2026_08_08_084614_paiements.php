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
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();

            $table->foreignId('inscription_id')
            ->constrained('inscriptions')
            ->onDelete('cascade');

            $table->foreignId('tranche_id')
            ->nullable()
            ->constrained('tranche_paiements')
            ->nullonDelete();

            $table->string('reference')->unique();
            $table->integer('numero_tranche');
            $table->string('libelle');
            $table->decimal('montant', 10, 2);
            $table->enum('statut', ['en_attente', 'valide', 'refuse'])->default('en_attente');
            $table->text('description')->nullable();
            $table->timestamp('date_paiement')->nullable();
            $table->string('pdf_path')->nullable();
            $table->string('mode_paiement')->nullable();
            $table->string('telephone')->nullable();
            $table->timestamps();           
            $table->index(['inscription_id', 'statut']);
            $table->index(['inscription_id', 'numero_tranche']);

        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};
