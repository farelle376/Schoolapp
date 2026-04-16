// lib/screens/parametres_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import '../services/admin_profile_service.dart';
import '../services/admin_auth_service.dart';
import '../widgets/edit_profile_panel.dart';

class ParametresPage extends StatefulWidget {
  @override
  _ParametresPageState createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  String? _adminName;
  String? _adminEmail;
  final AdminAuthService _authService = AdminAuthService();

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final admin = await _authService.currentAdmin;
    setState(() {
      _adminName = admin?.name;
      _adminEmail = admin?.email;
    });
  }
// Modifie la méthode _showEditProfileDialog

void _showEditProfileDialog() {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EditProfilePanel(
        onUpdate: () {
          _loadAdminInfo(); // Recharger les infos après modification
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
                );
                return;
              }
              final response = await AdminProfileService.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe modifié'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['message'] ?? 'Erreur'), backgroundColor: Colors.red),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarde manuelle'),
        content: const Text('Voulez-vous effectuer une sauvegarde des données ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sauvegarde en cours...'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les données'),
        content: const Text('Attention : Cette action remplacera toutes les données actuelles. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restauration en cours...'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des connexions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: FutureBuilder(
            future: AdminProfileService.getLoginHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final response = snapshot.data as Map<String, dynamic>?;
            
            if (response != null && response['success'] == true) {
                final history = List<Map<String, dynamic>>.from(response['data']);
                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      leading: Icon(
                        item['status'] == 'success' ? Icons.check_circle : Icons.error,
                        color: item['status'] == 'success' ? Colors.green : Colors.red,
                      ),
                      title: Text(item['date']),
                      subtitle: Text('IP: ${item['ip']}'),
                      trailing: Text(
                        item['status'] == 'success' ? 'Succès' : 'Échec',
                        style: TextStyle(
                          color: item['status'] == 'success' ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('Aucune donnée'));
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Section Profil
          _buildSectionHeader('Profil administrateur', Icons.person),
          _buildProfileCard(),
          
          const SizedBox(height: 16),
          
          // Section Préférences
          _buildSectionHeader('Préférences', Icons.settings),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Recevoir les alertes et notifications',
            value: settingsProvider.notifications,
            onChanged: (value) => settingsProvider.toggleNotifications(value),
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: 'Mode sombre',
            subtitle: 'Activer le thème sombre',
            value: settingsProvider.isDarkMode,
            onChanged: (value) => settingsProvider.toggleDarkMode(value),
          ),
          
          _buildDropdownTile(
           icon: Icons.language,
           title: 'Langue',
           subtitle: 'Changer la langue de l\'application',
          value: settingsProvider.language == 'fr' ? 'Français' : (settingsProvider.language == 'en' ? 'English' : 'Español'),
          items: const ['Français', 'English', 'Español'],
          onChanged: (value) {
          if (value == 'Français') {
          settingsProvider.setLanguage('fr');
          } else if (value == 'English') {
           settingsProvider.setLanguage('en');
           } else if (value == 'Español') {
          settingsProvider.setLanguage('es');
        }
      },
    ),
          
          const SizedBox(height: 16),
          
          // Section Données
          _buildSectionHeader('Données', Icons.storage),
          _buildSwitchTile(
            icon: Icons.backup,
            title: 'Sauvegarde automatique',
            subtitle: 'Sauvegarder les données automatiquement',
            value: settingsProvider.autoBackup,
            onChanged: (value) => settingsProvider.toggleAutoBackup(value),
          ),
          _buildActionTile(
            icon: Icons.backup_outlined,
            title: 'Sauvegarde manuelle',
            subtitle: 'Effectuer une sauvegarde maintenant',
            color: Colors.blue,
            onTap: _showBackupDialog,
          ),
          _buildActionTile(
            icon: Icons.restore,
            title: 'Restaurer les données',
            subtitle: 'Restaurer à partir d\'une sauvegarde',
            color: Colors.orange,
            onTap: _showRestoreDialog,
          ),
          
          const SizedBox(height: 16),
          
          // Section Sécurité
          _buildSectionHeader('Sécurité', Icons.security),
          _buildActionTile(
            icon: Icons.lock_reset,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe',
            color: Colors.red,
            onTap: _showChangePasswordDialog,
          ),
          _buildActionTile(
            icon: Icons.history,
            title: 'Historique des connexions',
            subtitle: 'Voir les dernières connexions',
            color: Colors.purple,
            onTap: _showHistoryDialog,
          ),
          
          const SizedBox(height: 16),
          
          // Section À propos
          _buildSectionHeader('À propos', Icons.info),
          _buildInfoTile(
            icon: Icons.code,
            title: 'Version',
            value: '1.0.0',
          ),
          _buildInfoTile(
            icon: Icons.build,
            title: 'Développé par',
            value: 'SchoolApp Team',
          ),
          _buildInfoTile(
            icon: Icons.email,
            title: 'Contact',
            value: 'support@schoolapp.com',
          ),
          _buildInfoTile(
            icon: Icons.web,
            title: 'Site web',
            value: 'www.schoolapp.com',
          ),
          
          const SizedBox(height: 24),
          
          // Bouton déconnexion
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('DÉCONNEXION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF47C3C)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF47C3C),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(_adminName ?? 'Administrateur'),
        subtitle: Text(_adminEmail ?? 'admin@schoolapp.com'),
        trailing: OutlinedButton(
          onPressed: _showEditProfileDialog,
          child: const Text('Modifier'),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFFF47C3C)),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFF47C3C),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF47C3C)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF47C3C)),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}