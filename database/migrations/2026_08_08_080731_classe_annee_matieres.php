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
        Schema::create('classe_annee_matieres', function (Blueprint $table) { 
            $table->id(); 
            $table->foreignId('classe_annee_id') 
            ->constrained('classe_annees') 
            ->cascadeOnDelete(); 
            
            $table->foreignId('matiere_id') 
            ->constrained('matieres') 
            ->cascadeOnDelete(); 
            
            $table->foreignId('professeur_id') 
            ->constrained('professeurs')
            ->cascadeOnDelete(); 
        
            $table->unsignedTinyInteger('coefficient')->default(1); 
            $table->timestamps(); 
            $table->unique(['classe_annee_id', 'matiere_id']); 
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
