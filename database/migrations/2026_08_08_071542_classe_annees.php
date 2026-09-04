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
        Schema::create('classe_annees', function (Blueprint $table) { 
            $table->id(); 

            $table->foreignId('classe_id') 
            ->constrained('classes') 
            ->cascadeOnDelete();

            $table->foreignId('annee_scolaire_id') 
            ->constrained('annee_scolaires') 
            ->cascadeOnDelete();

            $table->date('effectif')->nullable();
            $table->timestamps(); 
            $table->unique(['classe_id', 'annee_scolaire_id']); });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
      Schema::dropIfExists('classe_annees');  
    }
};
