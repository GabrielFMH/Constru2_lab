import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:organoai/logica/logicaRegister.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (user != null && mounted) {
        _showVerificationDialog(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Hemos enviado un enlace de verificación a tu correo electrónico.'),
            const SizedBox(height: 15),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('¿No recibiste el correo?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => _resendVerification(user),
            child: const Text('Reenviar correo'),
          ),
        ],
      ),
    ).then((_) => Navigator.pop(context));
  }

  Future<void> _resendVerification(User user) async {
    try {
      await AuthService().resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de verificación reenviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ListView(
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.eco, size: 80, color: Color(0xFF1DB954)),
                  SizedBox(height: 8),
                  Text(
                    'OreganoAI',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB954),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Diagnóstico inteligente para cultivos de orégano',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Nombre completo',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => !value!.contains('@')
                        ? 'Ingresa un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (value) =>
                        value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Registrarse',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
