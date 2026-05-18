import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/profile_model.dart';
import '../../core/config/api_config.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données via le Provider
    Future.microtask(() => context.read<ProfileController>().loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.hasError) {
            return Center(
              key: const Key('profile_error_center'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${controller.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadProfile(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return _buildProfileContent(controller);
        },
      ),
    );
  }

  Widget _buildProfileContent(ProfileController controller) {
    final profile = controller.profile;
    if (profile == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(profile),
          const SizedBox(height: 24),
          _buildPersonalInfoForm(profile),
          const SizedBox(height: 24),
          _buildPasswordSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileModel profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile.photoUrl != null
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _showError('Fonctionnalité photo non disponible pour le moment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              profile.matricule ?? 'N/A',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (profile.filiere != null)
              Text(
                '${profile.filiere!.name} - ${profile.niveau?.label ?? ''}',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm(ProfileModel profile) {
    // Initialize controllers with current data
    _prenomController.text = profile.prenom ?? '';
    _nomController.text = profile.nom ?? '';
    _emailController.text = profile.studentEmail ?? profile.email;
    _phoneController.text = profile.phone ?? '';
    _adresseController.text = profile.adresse ?? '';

    return Card(
      key: const Key('personal_info_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations personnelles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _updateProfile(),
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mot de passe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showChangePasswordDialog(),
              icon: const Icon(Icons.lock),
              label: const Text('Changer le mot de passe'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProfileController>();
    await controller.updateProfile(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      adresse: _adresseController.text.trim(),
    );

    if (controller.hasError) {
      _showError(controller.errorMessage ?? 'Erreur lors de la mise à jour');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès'), backgroundColor: Colors.green),
      );
    }
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
            TextFormField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
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
                _showError('Les mots de passe ne correspondent pas');
                return;
              }
              if (newPasswordController.text.length < 8) {
                _showError('Le mot de passe doit contenir au moins 8 caractères');
                return;
              }

              final controller = context.read<ProfileController>();
              await controller.updatePassword(
                currentPassword: currentPasswordController.text,
                password: newPasswordController.text,
                passwordConfirmation: confirmPasswordController.text,
              );

              Navigator.pop(context);

              if (controller.hasError) {
                _showError(controller.errorMessage ?? 'Erreur lors du changement de mot de passe');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe changé avec succès'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
}
