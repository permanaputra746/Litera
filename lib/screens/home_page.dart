import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dashboard_page.dart';
import 'buku_page.dart';
import 'mahasiswa_page.dart';
import 'peminjaman_page.dart';
import 'settings_page.dart';
import '../utils/app_state.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Start polling for Admin notifications
    NotificationService.startPolling('admin', (list) {
      if (mounted) {
        setState(() {
          _notifications = list;
          _unreadCount = list.where((n) => n['is_read'] == 0).length;
        });
      }
    });
  }

  @override
  void dispose() {
    NotificationService.stopPolling();
    super.dispose();
  }

  void _showNotificationsOverlay(BuildContext context, List<dynamic> list, String userId) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final currentUnread = list.where((n) => n['is_read'] == 0).length;

            return ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                  ),
                  child: Column(
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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppState.getString('notif_title'),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              if (currentUnread > 0)
                                Text(
                                  '$currentUnread ${AppState.getString('notif_unread')}',
                                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                          if (currentUnread > 0)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await ApiService.markNotificationsAsRead(userId);
                                final updated = await ApiService.getNotifications(userId);
                                setSheetState(() {
                                  list = updated;
                                });
                                if (mounted) {
                                  setState(() {
                                    _notifications = updated;
                                    _unreadCount = 0;
                                  });
                                }
                              },
                              child: Text(AppState.getString('notif_mark_read'), style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.bell_slash, size: 50, color: isDark ? Colors.white24 : Colors.black26),
                                    const SizedBox(height: 12),
                                    Text(AppState.getString('notif_empty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (itemCtx, idx) {
                                  final item = list[idx];
                                  final isUnread = item['is_read'] == 0;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isUnread 
                                          ? primaryColor.withValues(alpha: 0.08) 
                                          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isUnread 
                                            ? primaryColor.withValues(alpha: 0.2) 
                                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isUnread) ...[
                                          Container(
                                            margin: const EdgeInsets.only(top: 5, right: 12),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
                                          ),
                                        ] else ...[
                                          const SizedBox(width: 8),
                                        ],
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'] ?? 'Info',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['body'] ?? '',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                  fontSize: 13,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item['created_at'] ?? '',
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppState.themeNotifier,
          builder: (context, currentMode, _) {
            final isDark = currentMode == ThemeMode.dark;
            
            return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          body: Stack(
            children: [
              // Liquid Glass Ambient Background
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
                    color: (isDark ? const Color(0xFF5E5CE6) : const Color(0xFF007AFF)).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: -150,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? const Color(0xFF32ADE6) : const Color(0xFF34C759)).withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
              
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Dynamic Island inspired Header
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.book_solid, color: Theme.of(context).primaryColor, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                AppState.getString('library'),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showNotificationsOverlay(context, _notifications, 'admin'),
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(CupertinoIcons.bell_fill, color: Theme.of(context).primaryColor, size: 18),
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                    
                    // Page Content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedIndex),
                          child: const [
                            DashboardPage(),
                            BukuPage(),
                            MahasiswaPage(),
                            PeminjamanPage(),
                            SettingsPage(),
                          ][_selectedIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // macOS / visionOS style Floating Dock
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 32, right: 32, bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDockItem(isDark, 0, CupertinoIcons.square_grid_2x2_fill, AppState.getString('hub')),
                        _buildDockItem(isDark, 1, CupertinoIcons.book_fill, AppState.getString('books')),
                        _buildDockItem(isDark, 2, CupertinoIcons.person_2_fill, AppState.getString('students')),
                        _buildDockItem(isDark, 3, CupertinoIcons.arrow_right_arrow_left, AppState.getString('loans')),
                        _buildDockItem(isDark, 4, CupertinoIcons.gear_alt_fill, AppState.getString('settings')),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
          ),
        );
      }
    );
      }
    );
  }

  Widget _buildDockItem(bool isDark, int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? Theme.of(context).primaryColor 
        : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onTap: () => changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            if (!isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}