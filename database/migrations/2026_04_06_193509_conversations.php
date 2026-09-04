<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_conversations_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->constrained('familles')->onDelete('cascade');
            $table->foreignId('admin_id')->nullable()->constrained('users')->onDelete('set null');
            $table->foreignId('eleve_id')->nullable()->constrained('eleves')->onDelete('set null');
            $table->string('sujet', 255);
            $table->enum('type', ['general', 'eleve'])->default('general');
            $table->enum('statut', ['ouvert', 'ferme'])->default('ouvert');
            $table->timestamp('dernier_message_at')->nullable();
            $table->timestamps();
            
            $table->index(['parent_id', 'statut']);
            $table->index(['parent_id', 'type']);
            $table->index(['eleve_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};