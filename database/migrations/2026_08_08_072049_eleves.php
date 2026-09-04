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
        Schema::create('eleves', function (Blueprint $table) { 
        $table->id(); 
        $table->string('nom', 20); 
        $table->string('prenom', 10); 
        $table->string('sexe', 10); 
        $table->string('num_papa')->nullable(); 
        $table->string('num_maman')->nullable(); 
        $table->timestamps(); });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('eleves');
    }
};
