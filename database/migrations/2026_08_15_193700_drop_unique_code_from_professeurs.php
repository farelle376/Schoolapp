<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Le code par défaut d'un professeur (1234) est le même pour tous les
     * nouveaux professeurs tant qu'ils n'ont pas changé leur code à la
     * première connexion (first_login). La contrainte UNIQUE sur `code`
     * empêchait donc la création de tout professeur au-delà du premier.
     */
    public function up(): void
    {
        Schema::table('professeurs', function (Blueprint $table) {
            $table->dropUnique('professeurs_code_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('professeurs', function (Blueprint $table) {
            $table->unique('code');
        });
    }
};
