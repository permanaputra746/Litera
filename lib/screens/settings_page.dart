import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';
import '../utils/app_state.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  final StorageService _storage = StorageService();

  void _editName() {
    final TextEditingController controller = TextEditingController(text: AppState.adminNameNotifier.value);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppState.getString('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: AppState.getString('edit_name'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppState.getString('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                AppState.updateAdminName(newName);
                await _storage.saveAdminName(newName);
              }
              if(mounted) Navigator.pop(ctx);
            },
            child: Text(AppState.getString('save')),
          ),
        ],
      ),
    );
  }

  void _showSystemInfo() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Icon(CupertinoIcons.book_solid, size: 50, color: Color(0xFF007AFF)),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text('Admin: ${AppState.adminNameNotifier.value}\n\nLitera v1.0\nCreated with Flutter\n\nDatabase: MySQL via PHP REST API\nUI Engine: Liquid Glass Premium', style: const TextStyle(height: 1.5)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppState.getString('confirm_logout')),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn.instance.signOut();
              } catch (e) {
                debugPrint('Error signing out: $e');
              }
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              }
            },
            child: Text(AppState.getString('confirm')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppState.getString('cancel')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppState.themeNotifier,
          builder: (context, currentTheme, _) {
            return ValueListenableBuilder<String>(
              valueListenable: AppState.adminNameNotifier,
              builder: (context, currentName, _) {
                
                final isDark = currentTheme == ThemeMode.dark;
                final bgColor = isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6);
                final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

                return Column(
                  children: [
                    // Apple Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            AppState.getString('title'),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black, 
                              fontSize: 34, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: -0.5
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOutCubic),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Apple ID Profile Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: CupertinoColors.systemGrey5,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          currentName.isNotEmpty ? currentName.substring(0, 1).toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 28, color: CupertinoColors.systemGrey),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(currentName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(AppState.getString('admin_subtitle'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        child: const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey),
                                        onPressed: _editName,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                            
                            const SizedBox(height: 32),
                            
                            // Group 1: Preferences
                            _buildSettingsBlock(isDark, [
                              _buildAppleTile(
                                isDark: isDark,
                                icon: CupertinoIcons.bell_fill,
                                iconBg: CupertinoColors.systemRed,
                                title: AppState.getString('notif'),
                                trailing: CupertinoSwitch(
                                  value: _notificationsEnabled,
                                  activeTrackColor: CupertinoColors.systemGreen,
                                  onChanged: (v) {
                                    setState(() => _notificationsEnabled = v);
                                    if (v) {
                                      NotificationService.showSilentNotification(
                                        id: 1, 
                                        title: AppState.getString('notif'), 
                                        body: AppState.getString('notif_active_msg'),
                                      );
                                    }
                                  },
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildAppleTile(
                                isDark: isDark,
                                icon: isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                                iconBg: CupertinoColors.systemIndigo,
                                title: AppState.getString('dark'),
                                trailing: CupertinoSwitch(
                                  value: isDark,
                                  activeTrackColor: CupertinoColors.systemGreen,
                                  onChanged: (v) {
                                    HapticFeedback.lightImpact();
                                    AppState.toggleTheme(v);
                                  },
                                ),
                              ),
                              _buildDivider(isDark),
                              _buildAppleTile(
                                isDark: isDark,
                                icon: CupertinoIcons.globe,
                                iconBg: CupertinoColors.systemBlue,
                                title: AppState.getString('lang'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currentLang.toUpperCase(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 18),
                                  ],
                                ),
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final newLang = currentLang == 'id' ? 'en' : 'id';
                                  AppState.changeLanguage(newLang);
                                  await _storage.saveLanguage(newLang);
                                },
                              ),
                            ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                            
                            const SizedBox(height: 32),
                            
                            // Group 2: System
                            _buildSettingsBlock(isDark, [
                              _buildAppleTile(
                                isDark: isDark,
                                icon: CupertinoIcons.info_circle_fill,
                                iconBg: CupertinoColors.systemGrey,
                                title: AppState.getString('info'),
                                trailing: const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 18),
                                onTap: _showSystemInfo,
                              ),
                            ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),

                            const SizedBox(height: 32),
                            
                            // Group 3: Logout
                            _buildSettingsBlock(isDark, [
                              GestureDetector(
                                onTap: _logout,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      AppState.getString('logout'),
                                      style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 17, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ]).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildSettingsBlock(bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildAppleTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, 
                  fontSize: 17, 
                  fontWeight: FontWeight.w400
                ),
              )
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5, 
        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)
      ),
    );
  }
}
