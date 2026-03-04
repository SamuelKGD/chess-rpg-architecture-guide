// lib/presentation/screens/auth/register_screen.dart
// Écran d'inscription avec validation email étudiant bloquante

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/email_validator.dart';

/// Écran Register — Accès bloqué sans email institutionnel valide.
///
/// Implémente la vérification en deux temps :
/// 1. Validation regex côté client (UX immédiate)
/// 2. Envoi OTP après inscription serveur
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Validation en temps réel du domaine email (feedback immédiat)
  void _onEmailChanged(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final result = validateStudentEmail(value);
    setState(() => _emailError = emailValidationMessage(result));
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Vérification finale bloquante avant envoi
    final emailResult = validateStudentEmail(_emailController.text.trim());
    if (emailResult != EmailValidationResult.valid) {
      setState(() => _emailError = emailValidationMessage(emailResult));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: inject RegisterStudentUseCase via BLoC
      // await _registerUseCase(
      //   email: _emailController.text.trim(),
      //   password: _passwordController.text,
      //   fullName: _nameController.text.trim(),
      // );
      // Navigate to OTP verification screen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo / Titre
                Text(
                  'EduMarket',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Réservé aux étudiants vérifiés',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Champ Nom complet
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Champ Email étudiant (bloquant)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email universitaire',
                    hintText: 'prenom.nom@univ-paris.fr',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                    helperText: 'Obligatoire : email .edu ou institutionnel .fr',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: _onEmailChanged,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    final result = validateStudentEmail(v);
                    return emailValidationMessage(result);
                  },
                ),
                const SizedBox(height: 16),

                // Champ Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Minimum 8 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton d'inscription (désactivé si email invalide)
                FilledButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Créer mon compte étudiant',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // Lien vers login
                TextButton(
                  onPressed: () {
                    // TODO: Navigator.of(context).push(LoginScreen route)
                  },
                  child: const Text('Déjà un compte ? Se connecter'),
                ),

                const SizedBox(height: 24),
                // Note informative sur les domaines acceptés
                _DomainInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Domaines acceptés',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• Adresses se terminant en .edu\n'
              '• Adresses universitaires .fr (ex: univ-paris.fr)\n'
              '• Académies françaises (ac.xx.fr)\n'
              '• Grandes écoles partenaires',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
