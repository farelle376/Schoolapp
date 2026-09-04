<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_bulletins_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bulletins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('eleve_id')->constrained('eleves')->onDelete('cascade');
            $table->foreignId('classe_id')->constrained('classes')->onDelete('cascade');
            $table->string('trimestre', 2); // 1, 2, 3
            $table->decimal('moyenne_generale', 5, 2)->default(0);
            $table->string('mention')->nullable();
            $table->text('appreciation')->nullable();
            $table->integer('rang')->nullable();
            $table->integer('total_eleves')->nullable();
            $table->json('notes_data')->nullable(); // Stocker les notes en JSON
            $table->timestamps();
            
            // Un seul bulletin par élève et par trimestre
            $table->unique(['eleve_id', 'trimestre']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bulletins');
    }
};