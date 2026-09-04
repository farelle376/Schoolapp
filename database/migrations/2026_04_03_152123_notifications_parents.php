<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_notifications_parents_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications_parents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->constrained('familles')->onDelete('cascade');
            $table->string('titre');
            $table->text('message');
            $table->enum('type', ['info', 'avertissement', 'succès', 'dangereux'])->default('info');
            $table->boolean('est_lu')->default(false);
            $table->timestamp('lu_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications_parents');
    }
};