import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'utils/app_state.dart';
import 'screens/home_page.dart';
import 'screens/student_home_page.dart';
import 'models/mahasiswa_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _showFaceIdMock = false;
  int _roleIndex = 0; // 0: Siswa/Mahasiswa, 1: Admin Perpustakaan
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    // Default credentials helper
    _nimController.text = '09030015'; // Joko's NIM for easy login
    _passwordController.text = '123456';
  }

  void _loginWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Force account selection by signing out first
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String email = user.email ?? '';
        String name = user.displayName ?? 'Google User';

        if (_roleIndex == 1) {
          // --- ADMIN GOOGLE LOGIN ---
          bool isAdminSuccess = false;
          String errMsg = "Email Anda tidak terdaftar sebagai Admin.";
          try {
            final res = await ApiService.loginWithGoogle(email, name, 'admin');
            if (res['status'] == 'success') {
              isAdminSuccess = true;
            } else {
              errMsg = res['message'] ?? errMsg;
            }
          } catch (e) {
            errMsg = "Gagal terhubung ke server.";
          }

          if (!isAdminSuccess) {
            setState(() {
              _isLoading = false;
              _errorMessage = errMsg;
            });
            return;
          }

          String adminName = name;
          AppState.updateAdminName(adminName);
          AppState.updateUserRole('admin');
          await _storage.saveAdminName(adminName);

          setState(() {
            _isLoading = false;
          });

          // Trigger local notification
          try {
            await NotificationService.showSilentNotification(
              id: 997,
              title: 'Login Google Admin Berhasil',
              body: 'Selamat datang kembali, $adminName!',
            );
          } catch (_) {}

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        } else {
          // --- STUDENT/MAHASISWA GOOGLE LOGIN ---
          String studentNim = email;
          String studentName = name;
          bool isNewUser = false;

          try {
            final res = await ApiService.loginWithGoogle(email, name, 'siswa');
            if (res['status'] == 'success') {
              if (res['user'] != null) {
                studentNim = res['user']['nim'] ?? email;
                studentName = res['user']['nama'] ?? name;
              }
            } else if (res['status'] == 'new_user') {
              isNewUser = true;
            }
          } catch (_) {}

          if (isNewUser) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              _showCompleteProfileSheet(email, name);
            }
            return;
          }

          // Also save in local storage list of students just in case
          final studentList = await _storage.getMahasiswaList();
          if (!studentList.any((s) => s.nim == studentNim)) {
            studentList.add(Mahasiswa(
              nim: studentNim,
              nama: studentName,
              kelas: '-',
              jurusan: '-',
              umur: 0,
            ));
            await _storage.saveMahasiswaList(studentList);
          }

          AppState.updateUserRole('siswa');
          AppState.updateStudentData(studentNim, studentName);

          setState(() {
            _isLoading = false;
          });

          // Trigger local notification
          try {
            await NotificationService.showSilentNotification(
              id: 996,
              title: 'Login Google Mahasiswa Berhasil',
              body: 'Selamat datang kembali, $studentName!',
            );
          } catch (_) {}

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const StudentHomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      }
    } catch (error) {
      String msg = "Google Login failed: $error";
      if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) {
        msg = "Login Google dibatalkan";
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  void _showCompleteProfileSheet(String email, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    final sheetNimController = TextEditingController();
    final sheetKelasController = TextEditingController();
    final sheetJurusanController = TextEditingController();
    final sheetUmurController = TextEditingController();
    final sheetFormKey = GlobalKey<FormState>();
    bool sheetSaving = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                    ),
                    child: Form(
                      key: sheetFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          Text(
                            'Lengkapi Profil Siswa',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Silakan isi data berikut untuk menyelesaikan pendaftaran.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (sheetError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.exclamationmark_circle_fill, color: Theme.of(context).colorScheme.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      sheetError!,
                                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _buildAppleTextField(
                            controller: sheetNimController,
                            placeholder: 'NIM (Nomor Induk Mahasiswa)',
                            icon: CupertinoIcons.creditcard_fill,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildAppleTextField(
                            controller: sheetKelasController,
                            placeholder: 'Kelas (contoh: 5A)',
                            icon: CupertinoIcons.square_grid_2x2_fill,
                            isDark: isDark,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 16),
                          _buildAppleTextField(
                            controller: sheetJurusanController,
                            placeholder: 'Jurusan (contoh: Teknik Informatika)',
                            icon: CupertinoIcons.book_fill,
                            isDark: isDark,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 16),
                          _buildAppleTextField(
                            controller: sheetUmurController,
                            placeholder: 'Umur',
                            icon: CupertinoIcons.calendar,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: sheetSaving
                                ? const Center(child: CupertinoActivityIndicator())
                                : CupertinoButton(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                    onPressed: () async {
                                      if (sheetFormKey.currentState!.validate()) {
                                        setSheetState(() {
                                          sheetSaving = true;
                                          sheetError = null;
                                        });

                                        final nimStr = sheetNimController.text.trim();
                                        final kelasStr = sheetKelasController.text.trim();
                                        final jurusanStr = sheetJurusanController.text.trim();
                                        final umurInt = int.tryParse(sheetUmurController.text.trim()) ?? 0;

                                        // Register via API
                                        final regRes = await ApiService.registerStudent({
                                          'nim': nimStr,
                                          'nama': name,
                                          'email': email,
                                          'kelas': kelasStr,
                                          'jurusan': jurusanStr,
                                          'umur': umurInt,
                                          'password': '123456',
                                        });

                                        if (regRes['status'] == 'success') {
                                          // Also save locally
                                          final studentList = await _storage.getMahasiswaList();
                                          if (!studentList.any((s) => s.nim == nimStr)) {
                                            studentList.add(Mahasiswa(
                                              nim: nimStr,
                                              nama: name,
                                              kelas: kelasStr,
                                              jurusan: jurusanStr,
                                              umur: umurInt,
                                            ));
                                            await _storage.saveMahasiswaList(studentList);
                                          }

                                          // Send notification to admin
                                          try {
                                            await ApiService.sendNotification(
                                              'admin',
                                              'Mahasiswa Baru Terdaftar',
                                              'Mahasiswa $name (NIM: $nimStr) telah terdaftar via Google.',
                                            );
                                          } catch (_) {}

                                          AppState.updateUserRole('siswa');
                                          AppState.updateStudentData(nimStr, name);

                                          // Close sheet
                                          if (context.mounted) {
                                            Navigator.pop(ctx);
                                          }

                                          // Trigger success notification
                                          try {
                                            await NotificationService.showSilentNotification(
                                              id: 996,
                                              title: 'Login Google Mahasiswa Berhasil',
                                              body: 'Selamat datang kembali, $name!',
                                            );
                                          } catch (_) {}

                                          // Navigate to student home
                                          if (mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation, secondaryAnimation) => const StudentHomePage(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                  return FadeTransition(opacity: animation, child: child);
                                                },
                                                transitionDuration: const Duration(milliseconds: 800),
                                              ),
                                            );
                                          }
                                        } else {
                                          setSheetState(() {
                                            sheetSaving = false;
                                            sheetError = regRes['message'] ?? 'Gagal menyimpan profil.';
                                          });
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Simpan & Masuk',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showFaceIdMock = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (_roleIndex == 1) {
        // --- ADMIN LOGIN (Firebase Auth) ---
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();

        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          
          User? user = userCredential.user;
          String adminName = "Admin Litera";
          if (user != null) {
            adminName = user.displayName ?? user.email ?? "Admin Litera";
            AppState.updateAdminName(adminName);
            AppState.updateUserRole('admin');
            await _storage.saveAdminName(adminName);
          }

          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
          });

          // Trigger local notification
          try {
            await NotificationService.showSilentNotification(
              id: 995,
              title: 'Login Admin Berhasil',
              body: 'Selamat datang kembali, $adminName!',
            );
          } catch (_) {}

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          String msg = 'Login gagal';
          if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
            msg = 'Email atau password salah.';
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
        // --- STUDENT/MAHASISWA LOGIN (Local DB / PHP Sync) ---
        String nim = _nimController.text.trim();
        String password = _passwordController.text.trim();

        // 1. Try PHP API login first if possible
        bool loginSuccessful = false;
        String studentName = 'Mahasiswa';
        
        try {
          final res = await ApiService.loginStudent(nim, password);
          if (res['status'] == 'success') {
            loginSuccessful = true;
            studentName = res['mahasiswa']['nama'] ?? 'Mahasiswa';
          }
        } catch (_) {
          // Fallback to local storage verification if server is unreachable
        }

        if (!loginSuccessful) {
          // Local storage verification:
          // Check student list. Default password is '123456' for default accounts
          final students = await _storage.getMahasiswaList();
          final matchingStudent = students.where((s) => s.nim == nim).toList();
          
          if (matchingStudent.isNotEmpty) {
            // For simplicity, passwords for students are stored as '123456' or whatever they configured
            // We also support saving custom student credentials in local storage
            loginSuccessful = (password == '123456');
            studentName = matchingStudent.first.nama;
          }
        }

        if (loginSuccessful) {
          AppState.updateUserRole('siswa');
          AppState.updateStudentData(nim, studentName);

          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
          });

          // Trigger local notification
          try {
            await NotificationService.showSilentNotification(
              id: 994,
              title: 'Login Mahasiswa Berhasil',
              body: 'Selamat datang kembali, $studentName!',
            );
          } catch (_) {}

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const StudentHomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _showFaceIdMock = false;
            _errorMessage = 'NIM atau password salah. (Default: 123456)';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Ambient Mesh Gradient Background
          Positioned.fill(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)).withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D6)).withValues(alpha: 0.15),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // App Icon (Classical Book Sketch Logo)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Litera',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih peran Anda dan masuk untuk memulai',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54, 
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 30),

                  // Role Chooser
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
                      thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                      groupValue: _roleIndex,
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.person_solid, size: 18, color: _roleIndex == 0 ? (isDark ? Colors.white : Colors.black) : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Siswa / Mahasiswa', style: TextStyle(fontWeight: FontWeight.w600, color: _roleIndex == 0 ? (isDark ? Colors.white : Colors.black) : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.briefcase_fill, size: 18, color: _roleIndex == 1 ? (isDark ? Colors.white : Colors.black) : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Admin Litera', style: TextStyle(fontWeight: FontWeight.w600, color: _roleIndex == 1 ? (isDark ? Colors.white : Colors.black) : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _roleIndex = value;
                            _errorMessage = null;
                            _passwordController.clear();
                          });
                        }
                      },
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),

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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 30,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.exclamationmark_circle_fill, color: Theme.of(context).colorScheme.error, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().shakeX(),
                            
                            // Google Login Option (Semua User)
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                              ),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                child: _isLoading
                                    ? const Center(child: CupertinoActivityIndicator())
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.chrome, color: isDark ? Colors.white : Colors.black, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Masuk dengan Google',
                                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (kIsWeb) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    if (_roleIndex == 1) {
                                      // Bypass as Admin
                                      AppState.updateAdminName('Admin (Developer)');
                                      AppState.updateUserRole('admin');
                                      Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(builder: (ctx) => const HomePage()),
                                      );
                                    } else {
                                      // Bypass as Student
                                      AppState.updateStudentData('09030015', 'Mahasiswa (Developer)');
                                      AppState.updateUserRole('siswa');
                                      Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(builder: (ctx) => const StudentHomePage()),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Bypass Login (Developer)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleTextField({
    Key? key,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool isEmail = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType ?? (isEmail ? TextInputType.emailAddress : (isPassword ? TextInputType.text : TextInputType.number)),
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
                    _obscurePassword ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
