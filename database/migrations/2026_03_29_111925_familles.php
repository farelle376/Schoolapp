<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_parents_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('familles', function (Blueprint $table) {
            $table->id();
            $table->string('nom', 100);
            $table->string('prenom', 100);
            $table->enum('type_parent', ['pere', 'mere'])->default('pere');
            $table->string('num_telephone', 20)->unique(); // Numéro unique pour le parent
            $table->string('email')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('familles');
    }
};