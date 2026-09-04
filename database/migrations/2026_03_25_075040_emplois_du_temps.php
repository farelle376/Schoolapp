<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('emplois_du_temps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('classe_id')->constrained('classes')->onDelete('cascade');
            $table->foreignId('matiere_id')->constrained('matieres')->onDelete('cascade');
            $table->foreignId('professeur_id')->constrained('professeurs')->onDelete('cascade');
            $table->enum('jour', ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']);
            $table->time('heure_debut');
            $table->time('heure_fin');
            $table->enum('type_cours', ['cours', 'td', 'tp', 'evaluation'])->default('cours');
            $table->boolean('est_active')->default(true);
            $table->timestamps();
            
            // Index pour optimiser les recherches
            $table->index(['classe_id', 'jour']);
            $table->index(['professeur_id', 'jour', 'heure_debut']);
            $table->unique(['classe_id', 'jour', 'heure_debut'], 'unique_emploi');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('emplois_du_temps');
    }
};