<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_parent_eleve_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('parent_eleve', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->constrained('familles')->onDelete('cascade');
            $table->foreignId('eleve_id')->constrained('eleves')->onDelete('cascade');
            $table->enum('type_parent', ['pere', 'mere'])->default('pere');
            $table->timestamps();
            
            $table->unique(['parent_id', 'eleve_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parent_eleve');
    }
};