import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  void showCustomDialog(String message, {Color color = Colors.blueAccent}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          Center(
            child: SizedBox(
              width: 100,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> changePassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      showCustomDialog('New passwords do not match');
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String email = user?.email ?? '';

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user?.reauthenticateWithCredential(credential);
      await user?.updatePassword(newPassword);

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Success',
          pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
          transitionBuilder: (context, anim1, anim2, child) {
            return Transform.scale(
              scale: anim1.value,
              child: AlertDialog(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 20),
                    Expanded(child: Text('Password successfully updated')),
                  ],
                ),
                actions: [
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context, 'success'); // Return to previous screen
                        },
                        child: const Text('OK', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      showCustomDialog('Incorrect current password or input error.', color: Colors.redAccent);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 249, 250, 251), Color.fromARGB(255, 18, 186, 232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Change Password')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: !showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showCurrentPassword = !showCurrentPassword;
                      });
                    },
                  ),
                ),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: !showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showNewPassword = !showNewPassword;
                      });
                    },
                  ),
                ),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: changePassword,
                      child: const Text('Change Password'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}