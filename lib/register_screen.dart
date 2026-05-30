import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'utils/app_state.dart';
import 'models/mahasiswa_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  final int initialRoleIndex;
  const RegisterScreen({super.key, this.initialRoleIndex = 0});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _kelasController = TextEditingController();
  final _jurusanController = TextEditingController();
  final _umurController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showFaceIdMock = false;
  late int _roleIndex;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleIndex;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showFaceIdMock = true;
      });

      // Simulating FaceID delay
      await Future.delayed(const Duration(seconds: 2));

      String name = _nameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (_roleIndex == 1) {
        // --- REGISTER ADMIN (Firebase Auth) ---
        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
          
          if (userCredential.user != null) {
            await userCredential.user!.updateDisplayName(name);
          }

          AppState.updateAdminName(name);
          await _storage.saveAdminName(name);

          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
          });

          if (mounted) {
            _showSuccessDialog('Admin Account Created', 'Akun admin Litera Anda berhasil dibuat. Silakan masuk.');
          }
        } on FirebaseAuthException catch (e) {
          String msg = 'Pendaftaran gagal';
          if (e.code == 'weak-password') {
            msg = 'Password terlalu lemah (minimal 6 karakter).';
          } else if (e.code == 'email-already-in-use') {
            msg = 'Email sudah digunakan oleh akun lain.';
          } else {
            msg = e.message ?? 'Terjadi kesalahan.';
          }
          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
            _errorMessage = msg;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
            _errorMessage = 'Terjadi kesalahan: $e';
          });
        }
      } else {
        // --- REGISTER SISWA/MAHASISWA (Local Storage + PHP API Sync) ---
        String nim = _nimController.text.trim();
        String kelas = _kelasController.text.trim();
        String jurusan = _jurusanController.text.trim();
        int umur = int.tryParse(_umurController.text.trim()) ?? 0;

        final newStudent = Mahasiswa(
          nim: nim,
          nama: name,
          kelas: kelas,
          jurusan: jurusan,
          umur: umur,
        );

        // 1. Save locally to student contacts list
        final studentList = await _storage.getMahasiswaList();
        // Check if nim already exists
        if (studentList.any((s) => s.nim == nim)) {
          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
            _errorMessage = 'NIM sudah terdaftar.';
          });
          return;
        }

        studentList.add(newStudent);
        await _storage.saveMahasiswaList(studentList);

        // We can also save their password credentials locally in SharedPreferences for verification
        // Map structure: student_creds_{nim} = password
        // Let's store password or credentials. In local mode, default password is '123456' but we can also store the input password
        // so they can login using whatever password they set! Let's do that!
        final sprefs = await SharedPreferences.getInstance();
        await sprefs.setString('student_pwd_$nim', password);

        // 2. Sync to PHP API if reachable
        try {
          await ApiService.registerStudent({
            'nim': nim,
            'nama': name,
            'kelas': kelas,
            'jurusan': jurusan,
            'umur': umur,
            'password': password,
            'email': email,
          });
        } catch (_) {}

        setState(() {
          _isLoading = false;
          _showFaceIdMock = false;
        });

        if (mounted) {
          _showSuccessDialog('Student Account Created', 'Akun Mahasiswa Anda berhasil dibuat. Silakan masuk menggunakan NIM dan Password Anda.');
        }
      }
    }
  }

  void _showSuccessDialog(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Mesh Gradient Background
          Positioned.fill(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D6)).withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF32ADE6) : const Color(0xFF32ADE6)).withValues(alpha: 0.2),
              ),
            ),
          ),
          // Heavy glass blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 100, 24, 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Icon(
                      _roleIndex == 0 ? CupertinoIcons.person_crop_circle_fill_badge_plus : CupertinoIcons.person_badge_plus_fill,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Daftar Akun Baru',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 4),
                  Text(
                    _roleIndex == 0 ? 'Registrasi Siswa / Mahasiswa' : 'Registrasi Admin Litera',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 15, letterSpacing: -0.2),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 30),

                  // Liquid Glassmorphism Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30)],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.exclamationmark_circle_fill, color: Theme.of(context).colorScheme.error, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14))),
                                    ],
                                  ),
                                ).animate().fadeIn().shakeX(),
                              
                              _buildAppleTextField(
                                controller: _nameController,
                                placeholder: 'Nama Lengkap',
                                icon: CupertinoIcons.person_solid,
                                isDark: isDark,
                              ),
                              
                              if (_roleIndex == 0) ...[
                                const SizedBox(height: 14),
                                _buildAppleTextField(
                                  controller: _nimController,
                                  placeholder: 'NIM (Nomor Induk Mahasiswa)',
                                  icon: CupertinoIcons.creditcard_fill,
                                  isDark: isDark,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAppleTextField(
                                        controller: _kelasController,
                                        placeholder: 'Kelas (e.g. 5A)',
                                        icon: CupertinoIcons.group_solid,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildAppleTextField(
                                        controller: _umurController,
                                        placeholder: 'Umur (Tahun)',
                                        icon: CupertinoIcons.time_solid,
                                        isDark: isDark,
                                        isNumber: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildAppleTextField(
                                  controller: _jurusanController,
                                  placeholder: 'Jurusan (e.g. Teknik Informatika)',
                                  icon: CupertinoIcons.doc_text_fill,
                                  isDark: isDark,
                                ),
                              ],
                              
                              const SizedBox(height: 14),
                              _buildAppleTextField(
                                controller: _emailController,
                                placeholder: 'Email',
                                icon: CupertinoIcons.mail_solid,
                                isDark: isDark,
                                isEmail: true,
                              ),
                              const SizedBox(height: 14),
                              
                              _buildAppleTextField(
                                controller: _passwordController,
                                placeholder: 'Password',
                                icon: CupertinoIcons.lock_fill,
                                isDark: isDark,
                                isPassword: true,
                                isConfirm: false,
                              ),
                              const SizedBox(height: 14),

                              _buildAppleTextField(
                                controller: _confirmPasswordController,
                                placeholder: 'Konfirmasi Password',
                                icon: CupertinoIcons.lock_shield_fill,
                                isDark: isDark,
                                isPassword: true,
                                isConfirm: true,
                              ),
                              const SizedBox(height: 28),
                              
                              _showFaceIdMock
                                  ? Column(
                                      children: [
                                        Icon(LucideIcons.scanFace, size: 50, color: Theme.of(context).primaryColor)
                                            .animate(onPlay: (c) => c.repeat(reverse: true))
                                            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds)
                                            .fade(begin: 0.5, end: 1),
                                        const SizedBox(height: 12),
                                        Text('Creating ID...', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                                      ],
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: CupertinoButton(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(16),
                                        onPressed: _register,
                                        child: const Text('Daftar Akun', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool isConfirm = false,
    bool isEmail = false,
    bool isNumber = false,
  }) {
    final obscureVar = isConfirm ? _obscureConfirmPassword : _obscurePassword;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscureVar,
        keyboardType: isEmail 
            ? TextInputType.emailAddress 
            : (isNumber ? TextInputType.number : TextInputType.text),
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black45, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: isPassword
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    obscureVar ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Wajib diisi';
          if (isEmail) {
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Format email salah';
            }
          }
          if (isConfirm && value != _passwordController.text) return 'Password tidak cocok';
          if (isPassword && value.length < 6) return 'Minimal 6 karakter';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _kelasController.dispose();
    _jurusanController.dispose();
    _umurController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
