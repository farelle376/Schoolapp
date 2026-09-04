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
        Schema::create('emploi_du_temps', function (Blueprint $table) { 
            $table->id(); 

            $table->foreignId('classe_annee_matiere_id') 
            ->constrained('classe_annee_matieres') 
            ->cascadeOnDelete(); 
            
            $table->enum('jour', ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']);
            $table->time('heure_debut'); 
            $table->time('heure_fin'); 
            $table->enum('type_cours', ['cours', 'td', 'tp', 'evaluation'])->default('cours');
            $table->boolean('est_active')->default(true);
            $table->timestamps(); 
            
            // Index pour optimiser les recherches
            $table->index(['classe_annee_matiere_id', 'jour']);
            $table->unique(['classe_annee_matiere_id', 'jour', 'heure_debut'], 'unique_emploi');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('emploi_du_temps');
    }
};
