// lib/widgets/edit_profile_panel.dart

import 'package:flutter/material.dart';
import '../services/admin_profile_service.dart';

class EditProfilePanel extends StatefulWidget {
  final VoidCallback onUpdate;

  const EditProfilePanel({
    Key? key,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditProfilePanelState createState() => _EditProfilePanelState();
}

class _EditProfilePanelState extends State<EditProfilePanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isLoading = true;
  bool _isSaving = false;
  
  String _currentName = '';
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final response = await AdminProfileService.getProfile();
    
    if (response['success'] == true && response['data'] != null) {
      setState(() {
        _currentName = response['data']['name'] ?? '';
        _currentEmail = response['data']['email'] ?? '';
        _nameController.text = _currentName;
        _emailController.text = _currentEmail;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur lors du chargement du profil', Colors.red);
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Le nom ne peut pas être vide', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final response = await AdminProfileService.updateProfile(
      _nameController.text,
      _currentEmail,
    );

    setState(() => _isSaving = false);

    if (response['success'] == true) {
      setState(() {
        _currentName = _nameController.text;
        _isEditingName = false;
      });
      _showSnackBar('Nom modifié avec succès', Colors.green);
      widget.onUpdate();
    } else {
      _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
    }
  }

  Future<void> _saveEmail() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('L\'email ne peut pas être vide', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final response = await AdminProfileService.updateProfile(
      _currentName,
      _emailController.text,
    );

    setState(() => _isSaving = false);

    if (response['success'] == true) {
      setState(() {
        _currentEmail = _emailController.text;
        _isEditingEmail = false;
      });
      _showSnackBar('Email modifié avec succès', Colors.green);
      widget.onUpdate();
    } else {
      _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _controller.reverse().then((_) => Navigator.pop(context)),
      child: Container(
        color: Colors.black54,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () {},
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2B4E),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => _controller.reverse().then((_) => Navigator.pop(context)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Modifier le profil',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Color(0xFFF47C3C),
                                          child: Icon(Icons.person, size: 50, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      
                                      // Champ Nom
                                      _buildEditableField(
                                        label: 'Nom',
                                        currentValue: _currentName,
                                        isEditing: _isEditingName,
                                        controller: _nameController,
                                        onEdit: () {
                                          setState(() {
                                            _isEditingName = true;
                                            _nameController.text = _currentName;
                                          });
                                        },
                                        onSave: _saveName,
                                        onCancel: () {
                                          setState(() {
                                            _isEditingName = false;
                                            _nameController.text = _currentName;
                                          });
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Champ Email
                                      _buildEditableField(
                                        label: 'Email',
                                        currentValue: _currentEmail,
                                        isEditing: _isEditingEmail,
                                        controller: _emailController,
                                        onEdit: () {
                                          setState(() {
                                            _isEditingEmail = true;
                                            _emailController.text = _currentEmail;
                                          });
                                        },
                                        onSave: _saveEmail,
                                        onCancel: () {
                                          setState(() {
                                            _isEditingEmail = false;
                                            _emailController.text = _currentEmail;
                                          });
                                        },
                                      ),
                                      
                                      if (_isSaving)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 20),
                                          child: Center(child: CircularProgressIndicator()),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String currentValue,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Valeur actuelle avec bouton modifier
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18, color: Color(0xFFF47C3C)),
                    tooltip: 'Modifier',
                  ),
              ],
            ),
          ),
          
          if (isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nouveau $label',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}