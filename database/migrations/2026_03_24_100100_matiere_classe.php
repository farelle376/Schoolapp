<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('matiere_classe', function (Blueprint $table) {
            $table->id();
            $table->foreignId('matiere_id')->constrained('matieres')->onDelete('cascade');
            $table->foreignId('classe_id')->constrained('classes')->onDelete('cascade');
            $table->integer('coefficient')->default(1);
            $table->timestamps();
            
            $table->unique(['matiere_id', 'classe_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('matiere_classe');
    }
};