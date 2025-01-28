import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Pour parser le JSON
import '/components/components.dart'; // Vos composants personnalisés
import '/constants.dart'; // Vos constantes
import '/screens/home_screen.dart';
import '/screens/login_screen.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signup_screen';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/register'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        signUpAlert(
          context: context,
          title: 'Registration Successful',
          desc: 'You can now log in with your credentials',
          btnText: 'Login Now',
          onPressed: () {
            Navigator.pushReplacementNamed(context, LoginScreen.id);
          },
        ).show();
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to server (${response.body})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamed(context, HomeScreen.id);
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                  'assets/images/signup.png',
                  width: MediaQuery.of(context).size.width - 570,
                  ),
                  Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, right: 20, left: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ScreenTitle(title: 'Inscription'),
                            if (_errorMessage.isNotEmpty)
                              Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            Container(
                              width: 500, // Définir la largeur souhaitée
                              child: CustomTextField(
                                textField: TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(fontSize: 20),
                                  decoration: kTextInputDecoration.copyWith(
                                    hintText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
                            ),
                            Container(
                              width: 500, // Définir la largeur souhaitée
                              child: CustomTextField(
                                textField: TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible1,
                                  style: const TextStyle(fontSize: 20),
                                  decoration: kTextInputDecoration.copyWith(
                                    hintText: 'Mot de passe',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible1
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible1 =
                                              !_isPasswordVisible1;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            Container(
                              width: 500, // Définir la largeur souhaitée
                              child: CustomTextField(
                                textField: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isPasswordVisible2,
                                  style: const TextStyle(fontSize: 20),
                                  decoration: kTextInputDecoration.copyWith(
                                    hintText: 'Confirmer mot de passe',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible2
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible2 =
                                              !_isPasswordVisible2;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            CustomBottomScreen(
                              textButton: 'S\'inscrire',
                              heroTag: 'signup_btn',
                              question: 'Vous avez déjà un compte ?',
                              buttonPressed: _register,
                              questionPressed: () {
                                Navigator.pushNamed(context, LoginScreen.id);
                              },
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
    );
  }
}
