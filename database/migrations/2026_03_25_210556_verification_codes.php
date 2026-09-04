<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_verification_codes_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('verification_codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone_number', 20);
            $table->string('code', 4); // Changé de 6 à 4
            $table->enum('type', ['login', 'verification'])->default('login');
            $table->timestamp('expires_at');
            $table->boolean('is_used')->default(false);
            $table->timestamps();
            
            $table->index(['phone_number', 'code', 'is_used']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('verification_codes');
    }
};