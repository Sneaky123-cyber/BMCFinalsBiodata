import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const StudentProfileApp());
}

class StudentProfileApp extends StatelessWidget {
  const StudentProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Biodata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Personal
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthdate = TextEditingController();
  final _age = TextEditingController();
  String? _gender;
  bool _genderError = false;

  // Contact
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  // School
  final _school = TextEditingController();
  final _program = TextEditingController();
  final _gradYear = TextEditingController();
  String? _yearLevel;

  // More about me
  final _skills = TextEditingController();
  final _hobbies = TextEditingController();
  final _goal = TextEditingController();

  final _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  List<TextEditingController> get _all => [
        _firstName, _middleName, _lastName, _birthdate, _age, _phone,
        _email, _address, _school, _program, _gradYear, _skills, _hobbies,
        _goal,
      ];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState!.validate();
    setState(() => _genderError = _gender == null);
    if (!ok || _gender == null) return;

    setState(() => _saving = true);
    try {
      final first = _firstName.text.trim();
      final middle = _middleName.text.trim();
      final last = _lastName.text.trim();

      await FirebaseFirestore.instance.collection('student_profiles').add({
        'name': {'first': first, 'middle': middle, 'last': last},
        'fullName': [first, middle, last].where((e) => e.isNotEmpty).join(' '),
        'birthdate': _birthdate.text.trim(),
        'age': int.tryParse(_age.text.trim()) ?? 0,
        'gender': _gender,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'school': {
          'name': _school.text.trim(),
          'program': _program.text.trim(),
          'yearLevel': _yearLevel,
          'expectedGraduation': _gradYear.text.trim(),
        },
        'skills': _skills.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'hobbies': _hobbies.text.trim(),
        'goal': _goal.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile submitted successfully.')),
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    for (final c in _all) {
      c.clear();
    }
    _formKey.currentState?.reset();
    setState(() {
      _gender = null;
      _genderError = false;
      _yearLevel = null;
    });
  }

  // ---------- UI helpers ----------

  Widget _section(String number, String title) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number  ${title.toUpperCase()}',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 2, color: color),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
    TextInputType? type,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'This field is required' : null
              : null),
    );
  }

  Widget _gap([double h = 14]) => SizedBox(height: h);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              children: [
                // 1. Personal details
                _section('01', 'Personal Details'),
                _field(_firstName, 'First Name'),
                _gap(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(_middleName, 'Middle Name', required: false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_lastName, 'Last Name')),
                  ],
                ),
                _gap(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _field(
                        _birthdate,
                        'Birthdate',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _field(
                        _age,
                        'Age',
                        type: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) {
                            return 'Numbers only';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                _gap(18),
                const Text('Gender'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(value: 'Male', label: Text('Male')),
                      ButtonSegment(value: 'Female', label: Text('Female')),
                      ButtonSegment(value: 'Other', label: Text('Other')),
                    ],
                    selected: _gender == null ? <String>{} : {_gender!},
                    onSelectionChanged: (s) => setState(() {
                      _gender = s.isEmpty ? null : s.first;
                      _genderError = false;
                    }),
                  ),
                ),
                if (_genderError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Please choose one',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                // 2. Contact
                _section('02', 'Contact Information'),
                _field(_phone, 'Mobile Number', type: TextInputType.phone),
                _gap(),
                _field(
                  _email,
                  'Email Address',
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'This field is required';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                _gap(),
                _field(_address, 'Complete Address', maxLines: 2),

                // 3. School
                _section('03', 'School Information'),
                _field(_school, 'School / University'),
                _gap(),
                _field(_program, 'Program / Course'),
                _gap(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _yearLevel,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Year Level',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        items: _yearLevels
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) => setState(() => _yearLevel = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _gradYear,
                        'Expected Graduation',
                        type: TextInputType.number,
                        required: false,
                      ),
                    ),
                  ],
                ),

                // 4. More about me
                _section('04', 'More About Me'),
                _field(
                  _skills,
                  'Skills',
                ),
                _gap(),
                _field(_hobbies, 'Hobbies & Interests', required: false),
                _gap(),
                _field(
                  _goal,
                  'Future Goal / Ambition',
                  required: false,
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(_saving ? 'SUBMITTING...' : 'SUBMIT PROFILE'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _saving ? null : _reset,
                    child: const Text('Reset Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}