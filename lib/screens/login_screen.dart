import '/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/components/components.dart';
import '/constants.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final bool _saving = false;
  final String _errorMessage = '';

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        Navigator.pushReplacementNamed(context, ScanScreen.id);

        if (token != null) {
          // Stockage du token dans FlutterSecureStorage
          const storage = FlutterSecureStorage();
          await storage.write(key: 'auth_token', value: token);
          print("Token stocké : $token");

          // Redirection vers la page suivante
          Navigator.pushReplacementNamed(context, ScanScreen.id);
        } else {
          print("Erreur : Token non trouvé dans la réponse.");
        }
      } else {
        print(
            "Erreur lors du login (HTTP ${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("Erreur réseau lors du login : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingOverlay(
        isLoading: _saving,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TopScreenImage(screenImageName: 'welcome.png'),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, right: 15, left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const ScreenTitle(title: 'Login'),
                        CustomTextField(
                          textField: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 20),
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Email'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        CustomTextField(
                          textField: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(fontSize: 20),
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        Hero(
                          tag: 'login_btn',
                          child: CustomButton(
                            buttonText: 'Login',
                            onPressed: _login,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Sign in using',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: CircleAvatar(
                                radius: 25,
                                child: Image.asset(
                                    'assets/images/icons/facebook.png'),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: CircleAvatar(
                                radius: 25,
                                child: Image.asset(
                                    'assets/images/icons/google.png'),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: CircleAvatar(
                                radius: 25,
                                child: Image.asset(
                                    'assets/images/icons/linkedin.png'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
