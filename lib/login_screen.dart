import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();
  final TextEditingController _employeeNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Show reminder dialog when switching to Sign-Up tab
    _tabController.addListener(() {
      if (_tabController.index == 1 && _tabController.previousIndex != 1) {
        Future.delayed(Duration.zero, () {
          if (!mounted || Navigator.canPop(context)) return;
          _showGradientDialog('Reminder', 'Please use your DepEd email');
        });
      }
    });
  }

  bool get _isSignUpFormComplete {
    return _signUpEmailController.text.isNotEmpty &&
        _signUpPasswordController.text.isNotEmpty &&
        _signUpConfirmPasswordController.text.isNotEmpty &&
        _employeeNumberController.text.isNotEmpty;
  }

  bool get _isEmailValid {
    return _signUpEmailController.text.toLowerCase().endsWith('@deped.gov.ph');
  }

  void _showGradientDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black, // ✅ Black font
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ), // ✅ Black font
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text.trim();
    final confirmPassword = _signUpConfirmPasswordController.text.trim();
    final employeeNumber = _employeeNumberController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        employeeNumber.isEmpty) {
      _showGradientDialog('Error', 'Please fill all fields.');
      return;
    }
    if (password != confirmPassword) {
      _showGradientDialog('Error', 'Passwords do not match.');
      return;
    }

    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      final user = result.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'employee_number': employeeNumber,
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      _signUpEmailController.clear();
      _signUpPasswordController.clear();
      _signUpConfirmPasswordController.clear();
      _employeeNumberController.clear();

      _showGradientDialog('Success', 'Account created successfully!');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'An error occurred.';
      if (e.code == 'email-already-in-use') {
        message = 'Account already exists.';
      }
      _showGradientDialog('Error', message);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showGradientDialog('Error', 'Please enter email and password.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Login failed.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      }
      _showGradientDialog('Error', message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 246, 248, 246), Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset('assets/logo.png', height: 400),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ✅ Sign-In Tab
                        Column(
                          children: [
                            const SizedBox(height: 32),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.email),
                                hintText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Add reset password logic here
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity, // ✅ Full width
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ElevatedButton(
                                      onPressed: _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ), // ✅ Bigger
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ), // ✅ Bigger font
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        // ✅ Sign-Up Tab
                        Column(
                          children: [
                            const SizedBox(height: 32),
                            TextField(
                              controller: _signUpEmailController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.email),
                                hintText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        (!_isEmailValid &&
                                            _signUpEmailController
                                                .text
                                                .isNotEmpty)
                                        ? Colors.red
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _signUpPasswordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.lock),
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _signUpConfirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _employeeNumberController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.badge),
                                hintText: 'Employee Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity, // ✅ Full width
                              decoration:
                                  (_isSignUpFormComplete && _isEmailValid)
                                  ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.green, Colors.white],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                              child: ElevatedButton(
                                onPressed:
                                    (_isSignUpFormComplete && _isEmailValid)
                                    ? _createAccount
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/bp.png', height: 80),
                    const SizedBox(width: 15),
                    Image.asset('assets/deped.png', height: 80),
                    const SizedBox(width: 15),
                    Image.asset('assets/isabelasdo.png', height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
