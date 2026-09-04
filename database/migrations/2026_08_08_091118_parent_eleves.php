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
        Schema::create('parent_eleves', function (Blueprint $table) {
            $table->id();

            $table->foreignId('parent_id')
            ->constrained('parents')
            ->onDelete('cascade');

            $table->foreignId('eleve_id')
            ->constrained('eleves')
            ->onDelete('cascade');

            $table->enum('type_parent', ['pere', 'mere'])->default('pere');
            $table->timestamps();
            
            $table->unique(['parent_id', 'eleve_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('parent_eleves');
    }
};
