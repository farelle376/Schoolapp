<?php
// database/migrations/xxxx_xx_xx_xxxxxx_create_messages_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained('conversations')->onDelete('cascade');
            $table->foreignId('parent_id')->nullable()->constrained('familles')->onDelete('set null');
            // Changer 'users' en 'Utilisateurs' ou ce qui correspond à votre table d'admins
            $table->foreignId('admin_id')->nullable()->constrained('Utilisateurs')->onDelete('set null');
            $table->text('message');
            $table->boolean('est_lu')->default(false);
            $table->timestamp('lu_at')->nullable();
            $table->timestamps();
            
            $table->index(['conversation_id', 'created_at']);
            $table->index(['parent_id', 'est_lu']);
            $table->index(['admin_id', 'est_lu']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};