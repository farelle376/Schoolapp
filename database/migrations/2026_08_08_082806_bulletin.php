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
        Schema::create('bulletins', function (Blueprint $table) { 
            $table->id(); 
            
            $table->foreignId('inscription_id') 
            ->constrained('inscriptions') 
            ->cascadeOnDelete(); 
            
            $table->enum('trimestre', ['1', '2', '3']); 
            $table->decimal('moyenne_generale', 5, 2); 
            $table->string('mention')->nullable();
            $table->integer('rang')->nullable();
            $table->text('appreciation')->nullable(); 
            $table->integer('total_eleves')->nullable();
            $table->json('notes_data')->nullable(); // Stocker les notes en JSON
            $table->timestamps(); 
            // Un seul bulletin par élève et par trimestre
            $table->unique(['inscription_id', 'trimestre']);
            });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bulletins');
    }
};
