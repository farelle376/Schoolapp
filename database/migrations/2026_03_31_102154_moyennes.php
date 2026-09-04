<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('moyennes', function (Blueprint $table) {
            $table->id();

            // 🔹 Élève
            $table->foreignId('eleve_id')
                  ->constrained('eleves')
                  ->onDelete('cascade');

            // 🔹 Matière (AJOUT)
            $table->foreignId('matiere_id')
                  ->constrained('matieres')
                  ->onDelete('cascade');

            // 🔹 Trimestre
            $table->enum('trimestre', ['1', '2', '3']);

            // 🔹 Moyenne
            $table->decimal('moyenne', 5, 2);

            $table->timestamps();

            // 🔥 Optionnel (mais TRÈS important)
            // Empêche doublon élève + matière + trimestre
            $table->unique(['eleve_id', 'matiere_id', 'trimestre']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('moyennes');
    }
};