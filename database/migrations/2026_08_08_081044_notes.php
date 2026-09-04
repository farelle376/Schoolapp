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
        Schema::create('notes', function (Blueprint $table) { 
            $table->id();

            $table->foreignId('inscription_id') 
            ->constrained('inscriptions') 
            ->cascadeOnDelete(); 
            
            $table->foreignId('classe_annee_matiere_id') 
            ->constrained('classe_annee_matieres') 
            ->cascadeOnDelete(); 
            
            $table->decimal('note', 4, 2); 
            $table->string('type_note'); // devoir, composition...
            $table->enum('trimestre', ['1', '2', '3']);  
            $table->timestamps(); });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notes');
    }
};
