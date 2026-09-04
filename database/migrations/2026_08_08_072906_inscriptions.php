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
        Schema::create('inscriptions', function (Blueprint $table) { 
            $table->id();

            $table->foreignId('eleve_id') 
            ->constrained('eleves') 
            ->cascadeOnDelete();

            $table->foreignId('classe_annee_id') 
            ->constrained('classe_annees') 
            ->cascadeOnDelete();

            $table->date('date_inscription'); 
            
            $table->enum('statut', ['actif', 'transfere', 'abandon']) 
            ->default('actif'); $table->timestamps(); 
            
            $table->unique(['eleve_id', 'classe_annee_id']); 
            });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('inscriptions');
    }
};
