<?php
// routes/api.php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ParentAuthController;
use App\Http\Controllers\Api\ParentController;
use App\Http\Controllers\Api\KKiaPayController;
use App\Http\Controllers\Api\EmploiDuTempsController;
use App\Http\Controllers\Api\PaiementController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\AdminAuthController;
use App\Http\Controllers\Api\AdminParentController;
use App\Http\Controllers\Api\AdminPaiementController;
use App\Http\Controllers\Api\AdminEmploiController;
use App\Http\Controllers\Api\AdminConversationController;
use App\Http\Controllers\Api\AdminNotificationController;
use App\Http\Controllers\Api\AdminScolariteController;
use App\Http\Controllers\Api\AdminBulletinController;
use App\Http\Controllers\Api\EleveAdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfesseurDashboardController;
use App\Http\Controllers\Api\ProfesseurAdminController;
use App\Http\Controllers\Api\ProfesseurNoteAdminController;
use App\Http\Controllers\Api\AdminProfileController;
use App\Http\Controllers\Api\NoteAdminController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\Api\ClassmatController;
use App\Http\Controllers\Api\NoteController;
use App\Http\Controllers\Api\AdminNoteController;
use App\Http\Controllers\Api\AnneeScolaireController;

Route::prefix('parent')->group(function () {
    Route::post('send-code', [ParentAuthController::class, 'sendCode']);
    Route::post('verify-code', [ParentAuthController::class, 'verifyCode']);
});

// Webhook KKiaPay
Route::post('kkiapay/webhook', [KKiaPayController::class, 'webhook']);

// Test JSON
Route::get('/test-json', function () {
    return response()->json([
        'success' => true,
        'message' => 'Test OK',
        'data' => ['id' => 1, 'name' => 'Test']
    ]);
});
Route::get('/payment-page/{trancheId}', [PaymentController::class, 'showPaymentPage']);
// ==============================================
// ROUTES PARENT PROTÉGÉES (avec auth:sanctum)
// ==============================================
Route::middleware(['auth:sanctum'])->prefix('parent')->group(function () {
    
    // Enfants
    Route::get('children', [ParentController::class, 'getChildren']);
    Route::get('children/{eleveId}', [ParentController::class, 'getChildDetails']);
    Route::get('children/{eleveId}/notes', [ParentController::class, 'getNotes']);
    Route::get('children/{eleveId}/schedule', [ParentController::class, 'getSchedule']);
    Route::get('children/{eleveId}/reports', [ParentController::class, 'getReports']);
    Route::get('children/{eleveId}/matieres-notes', [ParentController::class, 'getMatieresWithNote']);
     Route::get('/children/{childId}/bulletins', [ParentController::class, 'getChildBulletins']);
    // Paiements
    Route::get('/children/{eleveId}/tranches-paiement', [PaiementController::class, 'getTranches']);
    Route::get('/children/{eleveId}/historique-paiements', [PaiementController::class, 'getHistorique']);
    Route::post('/payer-kkiapay', [PaiementController::class, 'payerAvecKKiaPay']);
    Route::post('/verifier-paiement-kkiapay', [PaiementController::class, 'verifierPaiementKKiaPay']);
    Route::post('/paiements/initier', [PaiementController::class, 'initierPaiement']);
    Route::post('/paiements/confirmer', [PaiementController::class, 'confirmerPaiement']);
    
    // KKiaPay
    
    // Notifications
    Route::get('notifications', [ParentController::class, 'getNotifications']);
    Route::get('notifications/unread-count', [ParentController::class, 'getUnreadCount']);
    Route::put('notifications/{id}/read', [ParentController::class, 'markNotificationRead']);
     Route::get('/conversations/unread-count', [ParentController::class, 'getUnreadMessagesCount']);
    // Conversations
    Route::get('conversations', [ConversationController::class, 'index']);
    Route::post('conversations', [ConversationController::class, 'store']);
    Route::get('conversations/{id}/messages', [ConversationController::class, 'getMessages']);
    Route::post('conversations/{id}/messages', [ConversationController::class, 'sendMessage']);
    
    // Déconnexion
    Route::post('logout', [ParentAuthController::class, 'logout']);
});

// ==============================================
// ROUTES EMPLOIS DU TEMPS
// ==============================================
Route::middleware(['auth:sanctum'])->prefix('emplois-du-temps')->group(function () {
    Route::get('/', [EmploiDuTempsController::class, 'index']);
    Route::get('/classe/{classeId}', [EmploiDuTempsController::class, 'getByClasse']);
    Route::get('/professeur/{professeurId}', [EmploiDuTempsController::class, 'getByProfesseur']);
    Route::post('/check-conflits', [EmploiDuTempsController::class, 'checkConflits']);
    
    // Routes admin
    Route::middleware(['role:admin'])->group(function () {
        Route::post('/', [EmploiDuTempsController::class, 'store']);
        Route::get('/{id}', [EmploiDuTempsController::class, 'show']);
        Route::put('/{id}', [EmploiDuTempsController::class, 'update']);
        Route::delete('/{id}', [EmploiDuTempsController::class, 'destroy']);
        Route::patch('/{id}/toggle', [EmploiDuTempsController::class, 'toggleStatus']);
    });
});

// ==============================================
// ROUTES ADMIN (authentification)
// ==============================================
Route::prefix('admin')->group(function () {
      Route::post('/login', [AdminAuthController::class, 'loginAdmin']);
    Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('check',[AdminAuthController::class, 'check']);
     Route::post('/forgot-password', [AdminAuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AdminAuthController::class, 'resetPassword']);
    Route::post('/verify-code', [AdminAuthController::class, 'verifyCode']);
});
// ==============================================
// ROUTES ADMIN PROTÉGÉES
// ==============================================
Route::middleware(['auth:sanctum'])->prefix('admin')->group(function () {
    
    // Gestion des parents
    Route::get('/parents', [AdminParentController::class, 'index']);
    Route::get('/parents/stats', [AdminParentController::class, 'getStats']);
    Route::post('/parents', [AdminParentController::class, 'store']);
    Route::get('/parents/{id}', [AdminParentController::class, 'show']);
    Route::put('/parents/{id}', [AdminParentController::class, 'update']);
    Route::delete('/parents/{id}', [AdminParentController::class, 'destroy']);
    
    // Gestion des paiements
    Route::get('/paiements/classes', [AdminPaiementController::class, 'getClasses']);
    Route::get('/paiements/classe/{classeId}/tranche/{tranche}', [AdminPaiementController::class, 'getPaiementsByClasseAndTranche']);
    Route::get('/paiements/{id}/recu', [AdminPaiementController::class, 'telechargerRecu']);
    
    // Gestion des emplois du temps
    Route::get('emplois-du-temps', [AdminEmploiController::class, 'index']);
    Route::post('emplois-du-temps', [AdminEmploiController::class, 'store']);
    Route::put('/emplois/{id}', [EmploiController::class, 'update']);
    Route::delete('emplois-du-temps/{id}', [AdminEmploiController::class, 'destroy']);
    Route::patch('emplois-du-temps/{id}/toggle', [AdminEmploiController::class, 'toggleActive']);
    
    // Données pour formulaires
    Route::get('classes', [AdminEmploiController::class, 'getClasses']);
    Route::get('matieres', [AdminEmploiController::class, 'getMatieres']);
    Route::get('professeurs', [AdminEmploiController::class, 'getProfesseurs']);
    
    // Gestion de la scolarité
    Route::get('/tranches/classe/{classeId}', [AdminScolariteController::class, 'getTranchesByClasse']);
    Route::post('/tranches/classe/{classeId}', [AdminScolariteController::class, 'saveTranchesByClasse']);
    Route::post('/tranches/generate-for-classe', [AdminScolariteController::class, 'generateTranchesForClasse']);
    Route::get('scolarite/classes', [AdminScolariteController::class, 'getClasses']);
    Route::get('scolarite/classe/{classeId}/tranche/{tranche}', [AdminScolariteController::class, 'getElevesByClasseAndTranche']);
     Route::get('/scolarite/eleves/{classeId}/toutes-tranches', [AdminScolariteController::class, 'getElevesWithAllTranches']);
    
    // Gestion des notifications
    Route::get('notifications', [AdminNotificationController::class, 'index']);
    Route::post('notifications', [AdminNotificationController::class, 'store']);
     Route::post('/notifications/send-to-all', [AdminNotificationController::class, 'sendToAllParents']); // ← AJOUTER
    Route::post('/notifications/send-to-selected', [AdminNotificationController::class, 'sendToSelectedParents']);
    Route::delete('notifications/{id}', [AdminNotificationController::class, 'destroy']);
    Route::get('parents-list', [AdminNotificationController::class, 'getParents']);
    Route::get('eleves-list', [AdminNotificationController::class, 'getEleves']);
    
    // Gestion des conversations
    Route::get('conversations', [AdminConversationController::class, 'index']);
    Route::get('conversations/{id}/messages', [AdminConversationController::class, 'getMessages']);
    Route::post('conversations/{id}/messages', [AdminConversationController::class, 'sendMessage']);
    
    // Gestion des bulletins
    Route::get('/bulletins/classes', [AdminBulletinController::class, 'getClasses']);
    Route::get('/bulletins/classe/{classeId}/eleves', [AdminBulletinController::class, 'getElevesByClasse']);
    Route::get('/bulletins/classe/{classeId}/trimestre/{trimestre}', [AdminBulletinController::class, 'getBulletinsByClasse']);
    Route::get('/eleves/{eleveId}/notes', [AdminNoteController::class, 'getNotesByEleveAndTrimestre']);
    Route::get('/bulletins/check-notes/{eleveId}/{trimestre}', [AdminBulletinController::class, 'checkNotesDisponibles']);
    Route::post('/bulletins/generate', [AdminBulletinController::class, 'generateBulletin']);
    Route::get('/bulletins/{id}', [AdminBulletinController::class, 'getBulletin']);
    Route::put('/bulletins/{id}', [AdminBulletinController::class, 'updateBulletin']);
    Route::delete('/bulletins/{id}', [AdminBulletinController::class, 'deleteBulletin']);
});

Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('classes', ClasseController::class);
    Route::apiResource('eleves', EleveAdminController::class);
     Route::get('/eleves-complet', [EleveAdminController::class, 'getAllData']);
    Route::get('/classes', [EleveAdminController::class, 'getClasses']);
    Route::get('/eleves/tous', [EleveAdminController::class, 'getAllEleves']);
    Route::get('/classes/{classeId}/eleves', [EleveAdminController::class, 'getElevesByClasse']);
    Route::post('/eleves', [EleveAdminController::class, 'addEleve']);
    Route::put('/eleves/{eleveId}', [EleveAdminController::class, 'updateEleve']);
    Route::delete('/eleves/{eleveId}', [EleveAdminController::class, 'deleteEleve']);
});

// Routes pour la gestion des professeurs coté admin
Route::middleware(['auth:sanctum'])->prefix('admin')->group(function () {
    Route::get('/professeurs', [ProfesseurAdminController::class, 'index']);
    Route::post('/professeurs', [ProfesseurAdminController::class, 'store']);
    Route::put('/professeurs/{id}', [ProfesseurAdminController::class, 'update']);
    Route::delete('/professeurs/{id}', [ProfesseurAdminController::class, 'destroy']);
    Route::post('/professeurs/{id}/classes', [ProfesseurAdminController::class, 'assignClasses']);
    Route::get('/matieres', [ProfesseurAdminController::class, 'getMatieres']);
    Route::get('/classes/list', [ProfesseurAdminController::class, 'getClassesList']);
});

Route::middleware(['auth:sanctum'])->prefix('admin')->group(function () {
    Route::get('/notes', [NoteAdminController::class, 'index']);
    Route::get('/notes/stats', [NoteAdminController::class, 'stats']);
    Route::get('/classes/list', [NoteAdminController::class, 'getClasses']);
    Route::get('/matieres', [NoteAdminController::class, 'getMatieres']);
    Route::delete('/notes/{id}', [NoteAdminController::class, 'destroy']);
    Route::put('/notes/{id}', [NoteAdminController::class, 'update']);
});

Route::middleware(['auth:sanctum'])->prefix('admin')->group(function () {
    // Profil admin
     Route::post('/Classmat/matieres/multiple', [ClassmatController::class, 'addMultipleMatieres']);
    Route::get('/profile', [AdminAuthController::class, 'profile']);
    Route::put('/profile', [AdminProfileController::class, 'updateProfile']);
    Route::post('/change-password', [AdminProfileController::class, 'changePassword']);
    Route::get('/login-history', [AdminProfileController::class, 'getLoginHistory']);
});

Route::middleware(['auth:sanctum'])->group(function () {
    // Routes unifiées pour les classes et matières
    Route::get('/Classmat/classes', [ClassmatController::class, 'getClasses']);
    Route::post('/Classmat/classes', [ClassmatController::class, 'addClasse']);
    Route::put('/Classmat/classes/{id}', [ClassmatController::class, 'updateClasse']);
    Route::delete('/Classmat/classes/{id}', [ClassmatController::class, 'deleteClasse']);
    
    Route::get('/Classmat/matieres', [ClassmatController::class, 'getMatieres']);
    Route::post('/Classmat/matieres', [ClassmatController::class, 'addMatiere']);
    Route::put('/Classmat/matieres/{id}', [ClassmatController::class, 'updateMatiere']);
    Route::delete('/Classmat/matieres/{id}', [ClassmatController::class, 'deleteMatiere']);
});
// Professeur

Route::middleware(['auth:sanctum'])->prefix('professeur')->group(function () {
Route::post('/change-password', [AuthController::class, 'changePassword']);
});
Route::post('/login-professeur', [AuthController::class, 'loginProfesseur']);
Route::get('/professeur/classes', [ProfesseurDashboardController::class, 'getClasses']);
Route::get('/professeur/classes/{classeId}/eleves', [ProfesseurDashboardController::class, 'getElevesByClasse']);
Route::get('/eleves/{eleveId}/notes', [ProfesseurDashboardController::class, 'getEleveNotes']);
Route::get('/professeur/emploi-du-temps', [ProfesseurDashboardController::class, 'getEmploiDuTemps']);
Route::post('/professeur/notes', [ProfesseurDashboardController::class, 'saveNotes']);
Route::put('/professeur/notes/{noteId}', [ProfesseurDashboardController::class, 'updateNote']);
Route::delete('/professeur/notes/{noteId}', [ProfesseurDashboardController::class, 'deleteNote']);

// Années scolaires
Route::prefix('annees-scolaires')->group(function () {
    Route::get('/', [AnneeScolaireController::class, 'index']);
    Route::get('/en-cours', [AnneeScolaireController::class, 'anneeEnCours']);
    Route::post('/', [AnneeScolaireController::class, 'store']);
    Route::get('/{id}', [AnneeScolaireController::class, 'show']);
    Route::put('/{id}', [AnneeScolaireController::class, 'update']);
    Route::delete('/{id}', [AnneeScolaireController::class, 'destroy']);
});
