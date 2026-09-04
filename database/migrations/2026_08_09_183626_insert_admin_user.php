<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void { 
        DB::table('utilisateurs')->insert([
             'name' => 'Admin', 
             'email' => 'irisgrace905@gmail.com', 
             'password' => Hash::make('admin124'), 
             'created_at' => now(), 
             'updated_at' => now(), 
             ]); 
        }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('utilisateurs') 
        ->where('email', 'irisgrace905@gmail.com') 
        ->delete();
    }
};
