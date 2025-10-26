import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:swabeicsdo/auth_provider.dart' as app_auth;
import 'constants.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final familyNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final employeeNumberController = TextEditingController();
  final tinController = TextEditingController();
  final gsisController = TextEditingController();
  final philhealthController = TextEditingController();
  final pagibigController = TextEditingController();
  final emailController = TextEditingController();

  String? gender;
  String? position;
  String? school;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        familyNameController.text = data['family_name'] ?? '';
        firstNameController.text = data['first_name'] ?? '';
        middleNameController.text = data['middle_name'] ?? '';
        birthdateController.text = data['birthdate'] ?? '';
        gender = data['gender'];
        position = data['position'];
        school = data['school'];
        employeeNumberController.text = data['employee_number'] ?? '';
        tinController.text = data['TIN number'] ?? '';
        gsisController.text = data['GSIS number'] ?? '';
        philhealthController.text = data['Philhealth number'] ?? '';
        pagibigController.text = data['Pag-ibig number'] ?? '';
        emailController.text = data['email'] ?? '';
      });
    }
  }

  Future<void> saveProfileToFirebase() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    Map<String, dynamic> updatedData = {
      'family_name': familyNameController.text,
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'birthdate': birthdateController.text,
      'gender': gender ?? '',
      'position': position ?? '',
      'school': school ?? '',
      'employee_number': employeeNumberController.text,
      'TIN number': tinController.text,
      'GSIS number': gsisController.text,
      'Philhealth number': philhealthController.text,
      'Pag-ibig number': pagibigController.text,
      'email': emailController.text,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(updatedData, SetOptions(merge: true));
  }

  void _validateAndSave() async {
    if (familyNameController.text.isEmpty || firstNameController.text.isEmpty) {
      _showDialog(
        'Validation Error',
        'Family Name and First Name are required.',
      );
      return;
    }
    await saveProfileToFirebase();

    if (!mounted) return;
    {
      await Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      ).loadUserProfile();
      if (!mounted) return;
      Navigator.pop(context);
    }

    _showDialog('Success', 'Profile updated successfully.', success: true);
  }

  void _showDialog(String title, String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: success ? Colors.green : Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lime],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.lightBlue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(familyNameController, 'Family Name', true),
                    _buildTextField(firstNameController, 'First Name', true),
                    _buildTextField(middleNameController, 'Middle Name', true),
                    _buildDateField(),
                    _buildDropdown(
                      'Gender',
                      gender,
                      ['Male', 'Female'],
                      (val) => setState(() => gender = val),
                      isGender: true,
                    ),
                    _buildDropdown(
                      'Position',
                      position,
                      positions,
                      (val) => setState(() => position = val),
                    ),
                    _buildDropdown(
                      'School',
                      school,
                      schools,
                      (val) => setState(() => school = val),
                    ),
                    _buildTextField(
                      employeeNumberController,
                      'Employee Number',
                      false,
                      readOnly: true,
                    ),
                    _buildTextField(
                      emailController,
                      'Email',
                      false,
                      readOnly: true,
                    ),
                    _buildTextField(
                      tinController,
                      'TIN number (000-000-000)',
                      false,
                    ),
                    _buildTextField(gsisController, 'GSIS number', false),
                    _buildTextField(
                      philhealthController,
                      'Philhealth number',
                      false,
                    ),
                    _buildTextField(
                      pagibigController,
                      'Pag-ibig number',
                      false,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _validateAndSave,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          87,
                          174,
                          125,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool uppercase, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: uppercase
            ? (value) {
                controller.value = TextEditingValue(
                  text: value.toUpperCase(),
                  selection: controller.selection,
                );
              }
            : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: birthdateController,
        readOnly: true,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: 'Birthdate',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              birthdateController.text = DateFormat(
                'MM-dd-yyyy',
              ).format(pickedDate);
            });
          }
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool isGender = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                if (isGender)
                  Icon(
                    item == 'Male' ? Icons.male : Icons.female,
                    color: item == 'Male' ? Colors.blue : Colors.red,
                  ),
                if (isGender) const SizedBox(width: 8),
                Text(item),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
