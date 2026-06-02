import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/buku_model.dart';
import '../models/peminjaman_model.dart';
import '../models/booking_model.dart';
import '../models/mahasiswa_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../utils/app_state.dart';
import '../login_screen.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;

  String _txt(String key) {
    return AppState.getString(key);
  }

  final StorageService _storage = StorageService();

  List<Buku> _bukuList = [];
  List<Peminjaman> _myLoansList = [];
  List<String> _favBookIds = [];
  List<Booking> _myBookings = [];
  bool _isLoading = true;

  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    
    // Start polling for Student notifications
    final myNim = AppState.studentNIMNotifier.value;
    NotificationService.startPolling(myNim, (list) {
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

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final books = await _storage.getBukuList();
    final allLoans = await _storage.getPeminjamanList();
    final favs = await _storage.getFavorites();
    final bookings = await _storage.getBookings();

    final myNim = AppState.studentNIMNotifier.value;
    final myLoans = allLoans.where((p) => p.nim == myNim).toList();
    final myBks = bookings.where((b) => b.nim == myNim).toList();

    if (mounted) {
      setState(() {
        _bukuList = books;
        _myLoansList = myLoans;
        _favBookIds = favs;
        _myBookings = myBks;
        _isLoading = false;
      });
    }
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
                                _txt('notif_title'),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              if (currentUnread > 0)
                                Text(
                                  '$currentUnread ${_txt('notif_unread')}',
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
                              child: Text(_txt('notif_mark_read'), style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
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
                                    Text(_txt('notif_empty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
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

  void _changePage(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
    _loadAllData(); // Reload stats when changing tab
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
                  // Ambient Glass Background
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
                        color: (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)).withValues(alpha: 0.15),
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
                        color: (isDark ? const Color(0xFF5E5CE6) : const Color(0xFF5856D6)).withValues(alpha: 0.1),
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
                        // Apple style Header (Dynamic Island vibe)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.book_solid, color: Theme.of(context).primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _txt('app_title'),
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  ValueListenableBuilder<String>(
                                    valueListenable: AppState.studentNameNotifier,
                                    builder: (context, name, _) {
                                      return Container(
                                        constraints: const BoxConstraints(maxWidth: 85),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          name,
                                          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      );
                                    }
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      final myNim = AppState.studentNIMNotifier.value;
                                      _showNotificationsOverlay(context, _notifications, myNim);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          ),
                                          child: Icon(CupertinoIcons.bell_fill, color: Theme.of(context).primaryColor, size: 16),
                                        ),
                                        if (_unreadCount > 0)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 14,
                                                minHeight: 14,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$_unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
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
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                        
                        // Tab Content
                        Expanded(
                          child: _isLoading
                              ? Center(child: CupertinoActivityIndicator(radius: 18, color: Theme.of(context).primaryColor))
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(_selectedIndex),
                                    child: _buildSubPage(isDark, currentLang),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Apple-style Floating Nav Dock
              bottomNavigationBar: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        height: 68,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: _buildDockItem(isDark, 0, CupertinoIcons.square_grid_2x2_fill, _txt('dock_main'))),
                            Expanded(child: _buildDockItem(isDark, 1, CupertinoIcons.search, _txt('dock_search'))),
                            Expanded(child: _buildDockItem(isDark, 2, CupertinoIcons.bookmark_fill, _txt('dock_fav'))),
                            Expanded(child: _buildDockItem(isDark, 3, CupertinoIcons.time_solid, _txt('dock_loans'))),
                            Expanded(child: _buildDockItem(isDark, 4, CupertinoIcons.person_fill, _txt('dock_options'))),
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
      onTap: () => _changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubPage(bool isDark, String lang) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(isDark);
      case 1:
        return _buildSearchTab(isDark);
      case 2:
        return _buildFavoritesTab(isDark);
      case 3:
        return _buildLoansTab(isDark);
      case 4:
        return _buildSettingsTab(isDark);
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // SUBPAGE 1: STUDENT DASHBOARD
  // ==========================================
  Widget _buildDashboardTab(bool isDark) {
    final availableBooksCount = _bukuList.where((b) => b.stok > 0).length;
    final activeLoansCount = _myLoansList.where((l) => l.status == 'disetujui').length;
    
    // Sort popular books based on frequency of occurrence in all loans (mocking popularity)
    final Map<String, int> popularCount = {};
    for (var l in _myLoansList) {
      popularCount[l.judulBuku] = (popularCount[l.judulBuku] ?? 0) + 1;
    }
    final sortedPopularBooks = [..._bukuList];
    sortedPopularBooks.sort((a, b) => (popularCount[b.judul] ?? 0).compareTo(popularCount[a.judul] ?? 0));
    final popularBooks = sortedPopularBooks.take(5).toList();

    final latestBooks = _bukuList.reversed.take(6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Info Blocks
          Row(
            children: [
              Expanded(
                child: _buildGlassStatCard(
                  _txt('db_avail'),
                  availableBooksCount.toString(),
                  CupertinoIcons.book_fill,
                  const Color(0xFF34C759),
                  isDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGlassStatCard(
                  _txt('db_borrowed'),
                  activeLoansCount.toString(),
                  CupertinoIcons.time_solid,
                  const Color(0xFF007AFF),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // popular books carousel header
          Text(
            _txt('db_pop'),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularBooks.length,
              itemBuilder: (ctx, idx) {
                final b = popularBooks[idx];
                return GestureDetector(
                  onTap: () => _showBookDetailDialog(b, isDark),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              alignment: Alignment.center,
                              child: Stack(
                                children: [
                                  Center(child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor, size: 36)),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      _favBookIds.contains(b.id) ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                      color: Theme.of(context).primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(b.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(b.penulis, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),
          // Latest Books Grid header
          Text(
            _txt('db_latest'),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: latestBooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (ctx, idx) {
              final b = latestBooks[idx];
              return GestureDetector(
                onTap: () => _showBookDetailDialog(b, isDark),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                alignment: Alignment.center,
                                child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor, size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(b.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(b.penulis, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b.stok > 0 ? '${_txt('db_stock')}: ${b.stok}' : _txt('db_stock_out'),
                                style: TextStyle(
                                  color: b.stok > 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                _favBookIds.contains(b.id) ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard(String title, String val, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SUBPAGE 2: SEARCH & DETAILS
  // ==========================================
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  Widget _buildSearchTab(bool isDark) {
    // Get unique categories
    final categories = ['Semua', ..._bukuList.map((b) => b.kategori).toSet().toList()];

    final filtered = _bukuList.where((b) {
      final matchesSearch = b.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.penulis.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || b.kategori == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // Search Bar & Categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoSearchTextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17),
              placeholder: _txt('search_placeholder'),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
        ),
        
        // Category list
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel 
                        ? Theme.of(context).primaryColor 
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSel ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)),
                  ),
                  child: Center(
                    child: Text(
                      cat == 'Semua' ? _txt('all') : cat,
                      style: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Book list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.search, size: 50, color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(height: 12),
                      Text(_txt('search_empty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final b = filtered[idx];
                    final isBooked = _myBookings.any((bk) => bk.bukuId == b.id && bk.status == 'menunggu');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => _showBookDetailDialog(b, isDark),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 55,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(b.penulis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kategori: ${b.kategori} • Rak: ${b.lokasiRak}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _favBookIds.contains(b.id) ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                          color: Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          HapticFeedback.lightImpact();
                                          await _storage.toggleFavorite(b.id);
                                          _loadAllData();
                                        },
                                      ),
                                      if (b.stok == 0 && isBooked)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('Booked', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Book Detail Dialog Sheet
  void _showBookDetailDialog(Buku b, bool isDark) {
    final currentLang = AppState.langNotifier.value;
    HapticFeedback.mediumImpact();
    final isFavorite = _favBookIds.contains(b.id);
    final isBooked = _myBookings.any((bk) => bk.bukuId == b.id && bk.status == 'menunggu');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
              ),
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
                  
                  // Book details layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 125,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor, size: 40),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.judul, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                            const SizedBox(height: 6),
                            Text('${_txt('writer')}: ${b.penulis}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${_txt('category')}: ${b.kategori}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${_txt('pub_year')}: ${b.tahunTerbit}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${_txt('shelf_loc')}: ${b.lokasiRak}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Synopsis
                  Text(_txt('detail_synopsis'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _txt('detail_synopsis_text'),
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Stock & Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_txt('detail_stock'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            '${b.stok} ${currentLang == 'id' ? 'Buku' : 'Books'}',
                            style: TextStyle(
                              color: b.stok > 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Bookmark toggle
                          CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            child: Icon(
                              isFavorite ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () async {
                              await _storage.toggleFavorite(b.id);
                              Navigator.pop(ctx);
                              _loadAllData();
                            },
                          ),
                          const SizedBox(width: 12),

                          // Borrow or Book
                          b.stok > 0
                              ? CupertinoButton(
                                  color: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: () => _showBorrowDurationDialog(b, ctx),
                                  child: Text(_txt('detail_borrow'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                )
                              : CupertinoButton(
                                  color: isBooked ? Colors.grey : Colors.orange,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: isBooked ? null : () => _requestBooking(b, ctx),
                                  child: Text(isBooked ? _txt('detail_already_booked') : _txt('detail_booking'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _showBorrowDurationDialog(Buku b, BuildContext sheetCtx) {
    final currentLang = AppState.langNotifier.value;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(_txt('detail_dur_title')),
        message: Text('${currentLang == 'id' ? 'Buku' : 'Book'}: ${b.judul}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _requestBorrow(b, sheetCtx, 3);
            },
            child: Text('3 ${_txt('detail_days')}'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _requestBorrow(b, sheetCtx, 7);
            },
            child: Text('7 ${_txt('detail_days')} (${currentLang == 'id' ? 'Rekomendasi' : 'Recommended'})'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _requestBorrow(b, sheetCtx, 14);
            },
            child: Text('14 ${_txt('detail_days')}'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _requestBorrow(b, sheetCtx, 30);
            },
            child: Text('30 ${_txt('detail_days')}'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(_txt('cancel')),
        ),
      ),
    );
  }

  // Request borrow request (pending status 'diproses')
  void _requestBorrow(Buku b, BuildContext sheetCtx, int duration) async {
    HapticFeedback.lightImpact();
    final myNim = AppState.studentNIMNotifier.value;
    
    // Check limit
    final activeLoansCount = _myLoansList.where((l) => l.status == 'diproses' || l.status == 'disetujui').length;
    if (activeLoansCount >= 2) {
      Navigator.pop(sheetCtx);
      _showAppleSnackbar(_txt('err_loan_limit'), CupertinoColors.systemRed);
      return;
    }

    final newLoan = Peminjaman(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nim: myNim,
      bukuId: b.id,
      judulBuku: b.judul,
      tanggal: DateTime.now().toString().split(' ')[0],
      durasiHari: duration,
      status: 'diproses',
    );

    // Save locally
    final allLoans = await _storage.getPeminjamanList();
    allLoans.add(newLoan);
    await _storage.savePeminjamanList(allLoans);

    // Trigger local notification
    await NotificationService.showSilentNotification(
      id: 2, 
      title: _txt('notif_loan_requested'), 
      body: '${_txt('notif_loan_pending_body_1')} "${b.judul}" ${_txt('notif_loan_pending_body_2')}',
    );

    // Sync notification to remote DB for admin
    try {
      final studentName = AppState.studentNameNotifier.value;
      await ApiService.sendNotification(
        'admin',
        _txt('notif_new_loan_request_title'),
        '$studentName (NIM: $myNim) ${_txt('notif_new_loan_request_body')} "${b.judul}".',
      );
    } catch (_) {}

    Navigator.pop(sheetCtx);
    _showAppleSnackbar(_txt('msg_loan_request_success'), CupertinoColors.systemGreen);
    _loadAllData();
  }

  // Request book booking if out of stock
  void _requestBooking(Buku b, BuildContext sheetCtx) async {
    HapticFeedback.lightImpact();
    final myNim = AppState.studentNIMNotifier.value;

    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nim: myNim,
      bukuId: b.id,
      judulBuku: b.judul,
      tanggalBooking: DateTime.now().toString().split(' ')[0],
      status: 'menunggu',
    );

    await _storage.addBooking(newBooking);

    // Trigger notification
    await NotificationService.showSilentNotification(
      id: 3,
      title: _txt('notif_booking_success_title'),
      body: '${_txt('notif_booking_success_body_1')} "${b.judul}" ${_txt('notif_booking_success_body_2')}',
    );

    // Sync notification to remote DB for admin
    try {
      final studentName = AppState.studentNameNotifier.value;
      await ApiService.sendNotification(
        'admin',
        _txt('notif_new_booking_request_title'),
        '$studentName (NIM: $myNim) ${_txt('notif_new_booking_request_body')} "${b.judul}".',
      );
    } catch (_) {}

    Navigator.pop(sheetCtx);
    _showAppleSnackbar(_txt('msg_booking_success'), CupertinoColors.systemOrange);
    _loadAllData();
  }

  // ==========================================
  // SUBPAGE 3: FAVORITES TAB
  // ==========================================
  Widget _buildFavoritesTab(bool isDark) {
    final favBooks = _bukuList.where((b) => _favBookIds.contains(b.id)).toList();

    if (favBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.bookmark, size: 50, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(_txt('fav_empty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      itemCount: favBooks.length,
      itemBuilder: (ctx, idx) {
        final b = favBooks[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () => _showBookDetailDialog(b, isDark),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(b.penulis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.bookmark_fill, color: Colors.red),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _storage.toggleFavorite(b.id);
                          _loadAllData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SUBPAGE 4: MY LOANS (STATUS & HISTORY)
  // ==========================================
  Widget _buildLoansTab(bool isDark) {
    if (_myLoansList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.ticket, size: 50, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(_txt('loans_empty'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
      itemCount: _myLoansList.length,
      itemBuilder: (ctx, idx) {
        final p = _myLoansList[idx];
        
        // Calculate late fine dynamically if status is 'disetujui' (active)
        double calculatedFine = p.denda;
        String statusLabel = _txt('loan_status_pending');
        Color statusColor = Colors.orange;
        
        if (p.status == 'disetujui') {
          statusLabel = _txt('loan_status_approved');
          statusColor = const Color(0xFF34C759);
          
          try {
            final datePinjam = DateTime.parse(p.tanggal);
            final dateDue = datePinjam.add(Duration(days: p.durasiHari));
            final today = DateTime.now();
            if (today.isAfter(dateDue)) {
              final daysOverdue = today.difference(dateDue).inDays;
              calculatedFine = daysOverdue * 1000.0; // Rp 1.000 per day
            }
          } catch (_) {}
        } else if (p.status == 'dikembalikan') {
          statusLabel = _txt('loan_status_returned');
          statusColor = Colors.blue;
        } else if (p.status == 'ditolak') {
          statusLabel = _txt('loan_status_rejected');
          statusColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF1C1C1E).withValues(alpha: 0.8), const Color(0xFF2C2C2E).withValues(alpha: 0.6)]
                      : [Colors.white.withValues(alpha: 0.9), Colors.grey.shade100.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_txt('loans_date')}: ${p.tanggal}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(p.judulBuku, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_txt('loans_duration')}: ${p.durasiHari} ${_txt('detail_days')}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                    
                    if (calculatedFine > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_txt('loans_fine')}: Rp ${calculatedFine.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SUBPAGE 5: PROFILE & SETTINGS
  // ==========================================
  void _editName() {
    final TextEditingController controller = TextEditingController(text: AppState.studentNameNotifier.value);
    final lang = AppState.langNotifier.value;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_txt('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _txt('edit_name'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_txt('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newName = controller.text.trim();
                AppState.updateStudentData(AppState.studentNIMNotifier.value, newName);
                
                // Also update local list of students cache
                final studentList = await _storage.getMahasiswaList();
                final idx = studentList.indexWhere((s) => s.nim == AppState.studentNIMNotifier.value);
                if (idx != -1) {
                  studentList[idx] = Mahasiswa(
                    nim: studentList[idx].nim,
                    nama: newName,
                    kelas: studentList[idx].kelas,
                    jurusan: studentList[idx].jurusan,
                    umur: studentList[idx].umur,
                  );
                  await _storage.saveMahasiswaList(studentList);
                }
              }
              if(mounted) Navigator.pop(ctx);
            },
            child: Text(_txt('save')),
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
          child: Text('Siswa: ${AppState.studentNameNotifier.value}\nNIM: ${AppState.studentNIMNotifier.value}\n\nLitera v1.0\nCreated with Flutter\n\nDatabase: MySQL via PHP REST API\nUI Engine: Liquid Glass Premium', style: const TextStyle(height: 1.5)),
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

  Widget _buildSettingsTab(bool isDark) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<String>(
          valueListenable: AppState.studentNameNotifier,
          builder: (context, currentName, _) {
            final nim = AppState.studentNIMNotifier.value;
            final bgColor = isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6);
            final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 120),
              child: Column(
                children: [
                  // Profile Card
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
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF34C759), Color(0xFF007AFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(CupertinoIcons.person_solid, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('NIM: $nim', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  Text(_txt('level_student'), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
                  ),
                  const SizedBox(height: 24),

                  // Preferences Group
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              isDark: isDark,
                              icon: CupertinoIcons.bell_fill,
                              iconBg: CupertinoColors.systemRed,
                              title: _txt('notif'),
                              trailing: CupertinoSwitch(
                                value: _notificationsEnabled,
                                activeTrackColor: CupertinoColors.systemGreen,
                                onChanged: (v) {
                                  setState(() => _notificationsEnabled = v);
                                  if (v) {
                                    NotificationService.showSilentNotification(
                                      id: 1, 
                                      title: _txt('notif'), 
                                      body: _txt('notif_active_msg'),
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Container(height: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
                            ),
                            _buildSettingsTile(
                              isDark: isDark,
                              icon: isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                              iconBg: CupertinoColors.systemIndigo,
                              title: _txt('dark'),
                              trailing: CupertinoSwitch(
                                value: isDark,
                                activeTrackColor: CupertinoColors.systemGreen,
                                onChanged: (v) {
                                  HapticFeedback.lightImpact();
                                  AppState.toggleTheme(v);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Container(height: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
                            ),
                            _buildSettingsTile(
                              isDark: isDark,
                              icon: CupertinoIcons.globe,
                              iconBg: CupertinoColors.systemBlue,
                              title: _txt('lang'),
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
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Container(height: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1)),
                            ),
                            _buildSettingsTile(
                              isDark: isDark,
                              icon: CupertinoIcons.info_circle_fill,
                              iconBg: CupertinoColors.systemGrey,
                              title: _txt('info'),
                              trailing: const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 16),
                              onTap: _showSystemInfo,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: GestureDetector(
                          onTap: _showLogoutConfirm,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                _txt('logout'),
                                style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSettingsTile({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    final lang = AppState.langNotifier.value;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(_txt('confirm_logout')),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (ctx2) => const LoginScreen()),
                );
              }
            },
            child: Text(_txt('confirm')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_txt('cancel')),
        ),
      ),
    );
  }

  // Common Snackbar helper
  void _showAppleSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      ),
    );
  }
}
