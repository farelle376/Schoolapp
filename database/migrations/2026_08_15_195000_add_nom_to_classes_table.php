<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * La table `classes` (migration 2026_08_08_071357_classes) ne contient
     * que `libelle` et `niveau`. Or tout le code applicatif (ClassmatController,
     * ProfesseurAdminController, le modèle Classe, et le Flutter add/edit
     * classe panel) lit/écrit `classes.nom`. Cette colonne manquante fait
     * échouer la création de classe avec "Unknown column 'nom'".
     */
    public function up(): void
    {
        if (!Schema::hasColumn('classes', 'nom')) {
            Schema::table('classes', function (Blueprint $table) {
                $table->string('nom')->nullable()->after('id');
            });

            // Récupère un nom pour les classes déjà existantes (créées avant
            // ce correctif) à partir de niveau/libelle, pour ne pas les
            // laisser sans nom affiché dans l'app.
            DB::table('classes')->whereNull('nom')->orderBy('id')->get()->each(function ($classe) {
                $nom = $classe->niveau ?: $classe->libelle;
                if ($nom) {
                    DB::table('classes')->where('id', $classe->id)->update(['nom' => $nom]);
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('classes', 'nom')) {
            Schema::table('classes', function (Blueprint $table) {
                $table->dropColumn('nom');
            });
        }
    }
};
