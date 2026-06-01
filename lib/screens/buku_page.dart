import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/buku_model.dart';
import '../models/booking_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../utils/app_state.dart';
import '../widgets/buku_form_dialog.dart';

class BukuPage extends StatefulWidget {
  const BukuPage({super.key});

  @override
  State<BukuPage> createState() => _BukuPageState();
}

class _BukuPageState extends State<BukuPage> {
  final StorageService _storage = StorageService();
  List<Buku> _bukuList = [];
  List<Buku> _filteredBuku = [];
  String _searchQuery = '';
  int _filterIndex = 0; // 0: Semua, 1: Tersedia, 2: Habis

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.getBukuList();
    if (mounted) {
      setState(() {
        _bukuList = data;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBuku = _bukuList.where((b) {
        final matchesSearch = b.judul.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              b.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              b.penulis.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              b.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter = _filterIndex == 0 || 
                              (_filterIndex == 1 && b.stok > 0) || 
                              (_filterIndex == 2 && b.stok == 0);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _checkBookingNotifications(String bookId, String bookTitle, int newStock) async {
    if (newStock > 0) {
      final bookings = await _storage.getBookings();
      final pendingBookings = bookings.where((bk) => bk.bukuId == bookId && bk.status == 'menunggu').toList();
      if (pendingBookings.isNotEmpty) {
        final targetBooking = pendingBookings.first;
        
        final updatedBookings = bookings.map((bk) {
          if (bk.id == targetBooking.id) {
            return Booking(
              id: bk.id,
              nim: bk.nim,
              bukuId: bk.bukuId,
              judulBuku: bk.judulBuku,
              tanggalBooking: bk.tanggalBooking,
              status: 'siap',
            );
          }
          return bk;
        }).toList();
        await _storage.saveBookings(updatedBookings);
        
        // Notify student of book availability
        await NotificationService.showSilentNotification(
          id: 100 + targetBooking.hashCode,
          title: 'Buku Booking Tersedia!',
          body: 'Buku "${bookTitle}" yang Anda booking sudah tersedia. Silakan pinjam sekarang!',
        );
      }
    }
  }

  Future<void> _tambahBuku(Buku bukuBaru) async {
    HapticFeedback.lightImpact();
    setState(() => _bukuList.add(bukuBaru));
    await _storage.saveBukuList(_bukuList);
    await _checkBookingNotifications(bukuBaru.id, bukuBaru.judul, bukuBaru.stok);
    
    // Sync notification to remote DB for all users
    try {
      await ApiService.sendNotification(
        'all',
        'Buku Baru Tersedia!',
        'Buku baru "${bukuBaru.judul}" oleh ${bukuBaru.penulis} kini tersedia di perpustakaan!',
      );
    } catch (_) {}

    _applyFilters();
  }

  Future<void> _editBuku(int index, Buku bukuBaru) async {
    HapticFeedback.lightImpact();
    final realIndex = _bukuList.indexWhere((b) => b.id == _filteredBuku[index].id);
    if (realIndex != -1) {
      final oldStock = _bukuList[realIndex].stok;
      setState(() => _bukuList[realIndex] = bukuBaru);
      await _storage.saveBukuList(_bukuList);
      if (oldStock == 0 && bukuBaru.stok > 0) {
        await _checkBookingNotifications(bukuBaru.id, bukuBaru.judul, bukuBaru.stok);
      }
      
      // Sync notification to remote DB for all users
      try {
        await ApiService.sendNotification(
          'all',
          'Informasi Buku Diperbarui',
          'Data buku "${bukuBaru.judul}" telah diperbarui oleh Admin.',
        );
      } catch (_) {}

      _applyFilters();
    }
  }

  Future<void> _hapusBuku(int index) async {
    HapticFeedback.lightImpact();
    final realIndex = _bukuList.indexWhere((b) => b.id == _filteredBuku[index].id);
    if (realIndex != -1) {
      final deletedBookTitle = _bukuList[realIndex].judul;
      setState(() => _bukuList.removeAt(realIndex));
      await _storage.saveBukuList(_bukuList);
      
      // Sync notification to remote DB for all users
      try {
        await ApiService.sendNotification(
          'all',
          'Buku Dihapus dari Katalog',
          'Buku "$deletedBookTitle" telah dihapus dari sistem oleh Admin.',
        );
      } catch (_) {}

      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple Style Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppState.getString('books'),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOutCubic),
                      const SizedBox(height: 16),
                      
                      // Search Bar
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoSearchTextField(
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17),
                          placeholder: AppState.getString('search_books'),
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilters();
                          },
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                      const SizedBox(height: 16),
                      
                      // iOS Sliding Segmented Control
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          backgroundColor: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
                          thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                          groupValue: _filterIndex,
                          children: {
                            0: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(AppState.getString('all'), style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                            1: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(AppState.getString('available'), style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                            2: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(AppState.getString('out_of_stock'), style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                          },
                          onValueChanged: (int? value) {
                            if (value != null) {
                              setState(() {
                                _filterIndex = value;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
            
            // List View
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: Theme.of(context).primaryColor,
                child: _filteredBuku.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.search, size: 60, color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(height: 16),
                            Text(AppState.getString('no_books'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 17)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                        itemCount: _filteredBuku.length,
                        itemBuilder: (ctx, i) {
                          final b = _filteredBuku[i];
                          final isTersedia = b.stok > 0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (ctx) => CupertinoActionSheet(
                                    title: Text(b.judul),
                                    message: Text('${AppState.getString('writer')}: ${b.penulis}\n${AppState.getString('category')}: ${b.kategori}\n${AppState.getString('pub_year')}: ${b.tahunTerbit}\n${AppState.getString('shelf_loc')}: ${b.lokasiRak}'),
                                    actions: [
                                      CupertinoActionSheetAction(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          showDialog(
                                            context: context,
                                            builder: (dialogCtx) => BukuFormDialog(
                                              initialData: b,
                                              onSave: (bBaru) async {
                                                await _editBuku(i, bBaru);
                                                if(mounted) Navigator.pop(dialogCtx);
                                              },
                                            ),
                                          );
                                        },
                                        child: Text(AppState.getString('book_edit')),
                                      ),
                                      CupertinoActionSheetAction(
                                        isDestructiveAction: true,
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _hapusBuku(i);
                                        },
                                        child: Text(AppState.getString('book_delete')),
                                      ),
                                    ],
                                    cancelButton: CupertinoActionSheetAction(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(AppState.getString('cancel')),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(CupertinoIcons.book, color: Theme.of(context).primaryColor),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.judul,
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppState.getString('by')} ${b.penulis} • ${b.kategori}',
                                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                                              ),
                                              Text(
                                                '${AppState.getString('shelf')}: ${b.lokasiRak} • ${AppState.getString('year')}: ${b.tahunTerbit}',
                                                style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isTersedia ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isTersedia ? '${b.stok} ${AppState.getString('available')}' : AppState.getString('out_of_stock'),
                                                    style: TextStyle(
                                                      color: isTersedia ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        Column(
                                          children: [
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              child: const Icon(CupertinoIcons.pencil_circle_fill, color: Color(0xFF007AFF), size: 28),
                                              onPressed: () => showDialog(
                                                context: context,
                                                builder: (ctx) => BukuFormDialog(
                                                  initialData: b,
                                                  onSave: (bBaru) async {
                                                    await _editBuku(i, bBaru);
                                                    if(mounted) Navigator.pop(ctx);
                                                  },
                                                ),
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              child: const Icon(CupertinoIcons.minus_circle_fill, color: Color(0xFFFF3B30), size: 28),
                                              onPressed: () => _hapusBuku(i),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: (200 + (i * 50)).ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
                        },
                      ),
              ),
            ),
          ],
        ),

        // FAB replacement
        Positioned(
          bottom: 110,
          right: 24,
          child: GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => BukuFormDialog(
                onSave: (buku) async {
                  await _tambahBuku(buku);
                  if(mounted) Navigator.pop(ctx);
                },
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.plus, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(AppState.getString('new_book'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02), curve: Curves.easeInOutCubic, duration: 2.seconds),
          ),
        ),
      ],
    );
      }
    );
  }
}