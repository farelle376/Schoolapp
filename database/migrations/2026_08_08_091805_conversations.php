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
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('parent_id')
            ->constrained('parents')
            ->onDelete('cascade');

            $table->foreignId('admin_id')
            ->nullable()
            ->constrained('utilisateurs')
            ->onDelete('set null');
            
            $table->foreignId('inscription_id')->nullable()
            ->constrained('inscriptions')
            ->onDelete('set null');

            $table->string('sujet', 255);
            $table->enum('type', ['general', 'eleve'])->default('general');
            $table->enum('statut', ['ouvert', 'ferme'])->default('ouvert');
            $table->timestamp('dernier_message_at')->nullable();
            $table->timestamps();
            
            $table->index(['parent_id', 'statut']);
            $table->index(['parent_id', 'type']);
            $table->index(['inscription_id']);
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
