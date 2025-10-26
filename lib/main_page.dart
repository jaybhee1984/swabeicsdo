import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'auth_provider.dart';
import 'profile_page.dart';
import 'service_record_screen.dart';
import 'route_observer.dart';
import 'profile_image_uploader.dart';
import 'view_pds_screen.dart'; // ✅ Import your View PDS screen

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with RouteAware {
  @override
  void didPopNext() {
    super.didPopNext();
    Provider.of<AuthProvider>(context, listen: false).loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final firstName = auth.userProfile?['first_name'] ?? 'user';
    final empNo = auth.employeeNumber;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.assignment,
        'label': 'View Service Record',
        'action': () {
          if (empNo.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee number not found.')),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ServiceRecordScreen(employeeNumber: empNo),
            ),
          );
        },
      },
      {
        'icon': Icons.credit_card,
        'label': 'View Service Credit',
        'action': () {
          // TO: Implement navigation
        },
      },
      {
        'icon': Icons.description,
        'label': 'Personnel Data Sheet',
        'action': () {
          _showPDSDialog(context);
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await fb_auth.FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 246, 248, 246), Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ProfileImageUploader(),
                const SizedBox(height: 16),
                Text(
                  'WELCOME, $firstName',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Profile'),
                    ),
                  ),
                ),
                for (var item in menuItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: item['action'] as VoidCallback,
                        icon: Icon(item['icon'] as IconData),
                        label: Text(item['label'] as String),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Modern PDS Dialog
  void _showPDSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Personnel Data Sheet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('View PDS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewPDSScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit PDS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Oooppss!'),
                      content: const Text(
                        'This feature is under development and will be available soon.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
