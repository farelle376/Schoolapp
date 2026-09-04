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
        Schema::create('professeurs', function (Blueprint $table) { 
            $table->id(); 
            $table->foreignId('matiere_id') 
            ->constrained('matieres') 
            ->cascadeOnDelete(); 
            $table->string('nom'); 
            $table->string('prenom'); 
            $table->string('numero')->unique();
            $table->string('password')->unique(); 
            $table->string('email')->unique();
            $table->integer('code')->unique();
            $table->boolean('first_login')->default(1);
            $table->rememberToken();
            $table->timestamps(); });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('professeurs');
    }
};
