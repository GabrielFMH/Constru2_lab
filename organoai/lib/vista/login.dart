import 'package:flutter/material.dart';
import 'package:organoai/vista/register.dart';
import '../vista/foto.dart';
import '../logica/LogicaLogin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
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
                  SizedBox(height: 16), // MÁS ESPACIO AQUÍ
                  Text(
                    'Diagnóstico inteligente para cultivos de orégano',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSocialButton(
              icon: Icons.account_circle_outlined,
              text: 'Continuar como invitado',
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoGallery(esInvitado: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[400])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('O', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 32),
            _buildInputField(
              'Correo electrónico',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              'Contraseña',
              isPassword: true,
              controller: _passwordController,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                '¿Se te ha olvidado la contraseña?',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text(
                '¿No tienes cuenta? Crea una',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().loginWithEmail(email, password);
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PhotoGallery(esInvitado: false)),
        );
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

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: const Color.fromARGB(255, 12, 12, 12),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: const Color.fromARGB(255, 10, 10, 10)),
      label: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    bool isPassword = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
