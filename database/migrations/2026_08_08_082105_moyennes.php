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
        Schema::create('moyennes', function (Blueprint $table) { 
            $table->id(); 
            
            $table->foreignId('inscription_id') 
            ->constrained('inscriptions') 
            ->cascadeOnDelete(); 
            
            $table->foreignId('classe_annee_matiere_id') 
            ->constrained('classe_annee_matieres')            
            ->cascadeOnDelete();
            
            $table->enum('trimestre', ['1', '2', '3']);
            $table->decimal('moyenne', 5, 2);  
            $table->timestamps();

        $table->unique([ 
            'inscription_id', 
            'classe_annee_matiere_id', 
            'trimestre' ]); 
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('moyennes');
    }
};
