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
        Schema::create('tranche_paiements', function (Blueprint $table) { 
            $table->id();

            $table->foreignId('classe_annee_id') 
            ->constrained('classe_annees') 
            ->cascadeOnDelete();

            $table->integer('numero_tranche'); // 1, 2, 3, 4
            $table->string('libelle'); // 1, 2, 3, 4
            $table->decimal('montant', 10, 2);
            $table->text('description')->nullable();
            $table->date('date_limite')->nullable();
            $table->enum('statut', ['paye', 'non_paye', 'partiel'])->default('non_paye');
            $table->timestamps();

            $table->unique(['classe_annee_id', 'numero_tranche']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tranche_paiements');
    }
};
