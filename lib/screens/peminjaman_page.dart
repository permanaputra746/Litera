import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/buku_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/peminjaman_model.dart';
import '../models/booking_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../utils/app_state.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final StorageService _storage = StorageService();
  List<Buku> _bukuList = [];
  List<Mahasiswa> _mahasiswaList = [];
  List<Peminjaman> _peminjamanList = [];

  String? _selectedNIM;
  String? _selectedIdBuku;
  int _durasiHari = 7;
  int _segmentedControlGroupValue = 0; // 0: Pengajuan, 1: Aktif, 2: Riwayat, 3: Buat Baru

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final buku = await _storage.getBukuList();
    final mahasiswa = await _storage.getMahasiswaList();
    final peminjaman = await _storage.getPeminjamanList();

    if (mounted) {
      setState(() {
        _bukuList = buku;
        _mahasiswaList = mahasiswa;
        _peminjamanList = peminjaman;
      });
    }
  }

  Future<void> _savePeminjaman() async {
    await _storage.savePeminjamanList(_peminjamanList);
  }

  int _hitungPeminjamanMahasiswa(String nim) {
    return _peminjamanList.where((p) => p.nim == nim && (p.status == 'diproses' || p.status == 'disetujui')).length;
  }

  // Check booking queue when a book is returned or stock is available
  Future<void> _checkBookingNotifications(String bookId, String bookTitle) async {
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
      
      // Trigger notification for student
      await NotificationService.showSilentNotification(
        id: 200 + targetBooking.hashCode,
        title: 'Buku Booking Tersedia!',
        body: 'Buku "${bookTitle}" yang Anda booking sudah tersedia. Silakan lakukan peminjaman.',
      );

      // Sync notification to remote DB
      try {
        await ApiService.sendNotification(
          targetBooking.nim,
          'Buku Booking Tersedia!',
          'Buku "${bookTitle}" yang Anda booking sudah tersedia. Silakan lakukan peminjaman.',
        );
      } catch (_) {}
    }
  }

  // Admin approves loan request
  void _setujuiPeminjaman(int index, Peminjaman p) async {
    HapticFeedback.lightImpact();
    
    // Check book stock first
    final bookIdx = _bukuList.indexWhere((b) => b.id == p.bukuId);
    if (bookIdx == -1) {
      _showSnackbar(AppState.getString('no_books'), CupertinoColors.systemRed);
      return;
    }

    final book = _bukuList[bookIdx];
    if (book.stok <= 0) {
      _showSnackbar(AppState.getString('loan_msg_out_of_stock'), CupertinoColors.systemRed);
      return;
    }

    setState(() {
      _peminjamanList[index] = Peminjaman(
        id: p.id,
        nim: p.nim,
        bukuId: p.bukuId,
        judulBuku: p.judulBuku,
        tanggal: DateTime.now().toString().split(' ')[0], // Date approved starts now
        durasiHari: p.durasiHari,
        status: 'disetujui',
      );
      book.stok = book.stok - 1;
    });

    await _savePeminjaman();
    await _storage.saveBukuList(_bukuList);

    // Trigger local notification
    await NotificationService.showSilentNotification(
      id: p.hashCode,
      title: AppState.getString('notif_approved_title'),
      body: '${AppState.getString('notif_approved_body')}: "${p.judulBuku}".',
    );

    // Sync notification to remote DB
    try {
      await ApiService.sendNotification(
        p.nim,
        AppState.getString('notif_approved_title'),
        '${AppState.getString('notif_approved_body')}: "${p.judulBuku}".',
      );
    } catch (_) {}

    _showSnackbar(AppState.getString('notif_approved_title'), CupertinoColors.systemGreen);
  }

  // Admin rejects loan request
  void _tolakPeminjaman(int index, Peminjaman p) async {
    HapticFeedback.lightImpact();
    
    setState(() {
      _peminjamanList[index] = Peminjaman(
        id: p.id,
        nim: p.nim,
        bukuId: p.bukuId,
        judulBuku: p.judulBuku,
        tanggal: p.tanggal,
        durasiHari: p.durasiHari,
        status: 'ditolak',
      );
    });

    await _savePeminjaman();
    
    // Trigger notification
    await NotificationService.showSilentNotification(
      id: p.hashCode + 1,
      title: AppState.getString('notif_rejected_title'),
      body: '${AppState.getString('notif_rejected_body')}: "${p.judulBuku}".',
    );

    // Sync notification to remote DB
    try {
      await ApiService.sendNotification(
        p.nim,
        AppState.getString('notif_rejected_title'),
        '${AppState.getString('notif_rejected_body')}: "${p.judulBuku}".',
      );
    } catch (_) {}

    _showSnackbar(AppState.getString('notif_rejected_title'), CupertinoColors.systemRed);
  }

  // Admin confirms return of a book
  void _konfirmasiPengembalian(int index, Peminjaman p) async {
    HapticFeedback.lightImpact();
    final book = _bukuList.firstWhere((b) => b.id == p.bukuId, orElse: () => Buku(id: '', judul: '', penulis: '', kategori: '', tahunTerbit: '', lokasiRak: '', cover: '', stok: 0));

    // Calculate late fine
    double dendaCalculated = 0.0;
    try {
      final tglPinjam = DateTime.parse(p.tanggal);
      final tglTenggat = tglPinjam.add(Duration(days: p.durasiHari));
      final hariIni = DateTime.now();
      
      if (hariIni.isAfter(tglTenggat)) {
        final selisih = hariIni.difference(tglTenggat).inDays;
        dendaCalculated = selisih * 1000.0; // Rp 1.000 / day
      }
    } catch (_) {}

    setState(() {
      _peminjamanList[index] = Peminjaman(
        id: p.id,
        nim: p.nim,
        bukuId: p.bukuId,
        judulBuku: p.judulBuku,
        tanggal: p.tanggal,
        durasiHari: p.durasiHari,
        tanggalKembali: DateTime.now().toString().split(' ')[0],
        status: 'dikembalikan',
        denda: dendaCalculated,
      );

      if (book.id.isNotEmpty) {
        book.stok = book.stok + 1;
      }
    });

    await _savePeminjaman();
    if (book.id.isNotEmpty) {
      await _storage.saveBukuList(_bukuList);
      await _checkBookingNotifications(book.id, book.judul);
    }

    // Trigger return notification
    await NotificationService.showSilentNotification(
      id: p.hashCode + 2,
      title: AppState.getString('notif_return_title'),
      body: '${AppState.getString('notif_return_body')} "${p.judulBuku}".${dendaCalculated > 0 ? ' ' + AppState.getString('loans_fine') + ': Rp ' + dendaCalculated.toStringAsFixed(0) : ''}',
    );

    // Sync notification to remote DB
    try {
      await ApiService.sendNotification(
        p.nim,
        'Pengembalian Dikonfirmasi',
        'Terima kasih telah mengembalikan buku "${p.judulBuku}".${dendaCalculated > 0 ? ' Denda: Rp ' + dendaCalculated.toStringAsFixed(0) : ''}',
      );
    } catch (_) {}

    _showSnackbar('Pengembalian Berhasil', CupertinoColors.activeBlue);
  }

  // Create manual loan
  void _buatManualPinjam() async {
    HapticFeedback.lightImpact();
    if (_selectedNIM == null || _selectedIdBuku == null) {
      _showSnackbar(AppState.getString('loan_msg_fill_fields'), CupertinoColors.systemOrange);
      return;
    }

    final jumlahPinjam = _hitungPeminjamanMahasiswa(_selectedNIM!);
    if (jumlahPinjam >= 2) {
      _showSnackbar(AppState.getString('loan_msg_limit_exceeded'), CupertinoColors.systemRed);
      return;
    }

    final buku = _bukuList.firstWhere((b) => b.id == _selectedIdBuku);
    if (buku.stok <= 0) {
      _showSnackbar(AppState.getString('loan_msg_out_of_stock'), CupertinoColors.systemRed);
      return;
    }

    final tanggal = DateTime.now().toString().split(' ')[0];

    setState(() {
      _peminjamanList.add(
        Peminjaman(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nim: _selectedNIM!,
          bukuId: buku.id,
          judulBuku: buku.judul,
          tanggal: tanggal,
          durasiHari: _durasiHari,
          status: 'disetujui', // Automatically approved
        ),
      );
      buku.stok = buku.stok - 1;
      _segmentedControlGroupValue = 1; // Switch to Active tab
    });

    await _savePeminjaman();
    await _storage.saveBukuList(_bukuList);

    // Sync notification to remote DB for student
    try {
      await ApiService.sendNotification(
        _selectedNIM!,
        AppState.getString('notif_approved_title'),
        'Admin: ${AppState.getString('notif_approved_body')} "${buku.judul}".',
      );
    } catch (_) {}

    setState(() {
      _selectedNIM = null;
      _selectedIdBuku = null;
      _durasiHari = 7;
    });

    _showSnackbar(AppState.getString('loan_msg_success'), CupertinoColors.systemGreen);
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildStatusBadge(Peminjaman p) {
    try {
      final tglPinjam = DateTime.parse(p.tanggal);
      final tglTenggat = tglPinjam.add(Duration(days: p.durasiHari));
      final hariIni = DateTime.now();
      
      final selisih = hariIni.difference(tglTenggat).inDays;

      if (selisih > 0) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Terlambat $selisih Hari',
            style: const TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1);
      } else {
        final sisaHari = selisih.abs();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            sisaHari == 0 ? 'Tempo Hari Ini' : '$sisaHari hari tersisa',
            style: const TextStyle(color: CupertinoColors.systemBlue, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      }
    } catch (e) {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Sliding Segmented Control
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppState.getString('loan_title'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black, 
                      fontSize: 34, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: -0.5
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),
                  
                  // Custom Admin sliding segments
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.6) : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
                      thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                      groupValue: _segmentedControlGroupValue,
                      children: {
                        0: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(AppState.getString('loan_tab_request'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        1: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(AppState.getString('loan_tab_active'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        2: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(AppState.getString('loan_tab_history'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        3: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(AppState.getString('loan_tab_manual'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      },
                      onValueChanged: (int? value) {
                        if (value != null) {
                          setState(() => _segmentedControlGroupValue = value);
                        }
                      },
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),
        
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildSegmentContent(isDark),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSegmentContent(bool isDark) {
    switch (_segmentedControlGroupValue) {
      case 0:
        return _buildPengajuanList(isDark);
      case 1:
        return _buildActiveLoansList(isDark);
      case 2:
        return _buildHistoryLoansList(isDark);
      case 3:
        return _buildManualBorrowForm(isDark);
      default:
        return const SizedBox();
    }
  }

  // 1. PENGAJUAN (Pending student requests)
  Widget _buildPengajuanList(bool isDark) {
    final pending = _peminjamanList.where((p) => p.status == 'diproses').toList();

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.question_circle, size: 50, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(AppState.getString('loan_no_pending'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: pending.length,
      itemBuilder: (ctx, i) {
        final p = pending[i];
        final realIndex = _peminjamanList.indexOf(p);
        String studentName = p.nim;
        try {
          studentName = _mahasiswaList.firstWhere((m) => m.nim == p.nim).nama;
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppState.getString('loans_date')}: ${p.tanggal}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(AppState.getString('loan_status_pending').toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(p.judulBuku, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('${AppState.getString('student')}: $studentName (NIM: ${p.nim})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _tolakPeminjaman(realIndex, p),
                          child: Text(AppState.getString('loan_action_reject'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: CupertinoColors.systemGreen,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _setujuiPeminjaman(realIndex, p),
                          child: Text(AppState.getString('loan_action_approve'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
    );
  }

  // 2. ACTIVE LOANS (Approved/Active)
  Widget _buildActiveLoansList(bool isDark) {
    final active = _peminjamanList.where((p) => p.status == 'disetujui').toList();

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.checkmark_seal, size: 50, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(AppState.getString('loan_no_active'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: active.length,
      itemBuilder: (ctx, i) {
        final p = active[i];
        final realIndex = _peminjamanList.indexOf(p);
        String studentName = p.nim;
        try {
          studentName = _mahasiswaList.firstWhere((m) => m.nim == p.nim).nama;
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppState.getString('loans_date')}: ${p.tanggal}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        _buildStatusBadge(p),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(p.judulBuku, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('${AppState.getString('student')}: $studentName (NIM: ${p.nim})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: CupertinoColors.systemGreen,
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () => _konfirmasiPengembalian(realIndex, p),
                          child: Text(AppState.getString('loan_confirm_return'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
    );
  }

  // 3. HISTORY LOANS (Returned/Rejected)
  Widget _buildHistoryLoansList(bool isDark) {
    final history = _peminjamanList.where((p) => p.status == 'dikembalikan' || p.status == 'ditolak').toList();

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.archivebox, size: 50, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(AppState.getString('loan_no_history'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final p = history[i];
        String studentName = p.nim;
        try {
          studentName = _mahasiswaList.firstWhere((m) => m.nim == p.nim).nama;
        } catch (_) {}

        final isDitolak = p.status == 'ditolak';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppState.getString('loans_date')}: ${p.tanggal}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDitolak ? Colors.red : Colors.blue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDitolak ? AppState.getString('loan_status_rejected') : AppState.getString('loan_status_returned'),
                            style: TextStyle(color: isDitolak ? Colors.red : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(p.judulBuku, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('${AppState.getString('student')}: $studentName (NIM: ${p.nim})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    
                    if (!isDitolak && p.tanggalKembali.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('${AppState.getString('return')}: ${p.tanggalKembali}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if (p.denda > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${AppState.getString('loans_fine')}: Rp ${p.denda.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ]
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

  // 4. MANUAL CREATION (Existing manual builder flow)
  Widget _buildManualBorrowForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                ),
                child: Column(
                  children: [
                    _buildCupertinoDropdown(
                      isDark: isDark,
                      value: _selectedNIM,
                      title: AppState.getString('loan_select_student'),
                      icon: CupertinoIcons.person_solid,
                      items: _mahasiswaList.map((m) => DropdownMenuItem(value: m.nim, child: Text('${m.nim} - ${m.nama}'))).toList(),
                      onChanged: (v) => setState(() => _selectedNIM = v),
                    ),
                    _buildDivider(isDark),
                    _buildCupertinoDropdown(
                      isDark: isDark,
                      value: _selectedIdBuku,
                      title: AppState.getString('loan_select_book'),
                      icon: CupertinoIcons.book_solid,
                      items: _bukuList.map((b) => DropdownMenuItem(
                        value: b.id,
                        enabled: b.stok > 0,
                        child: Text('${b.judul} (${AppState.getString('stock')}: ${b.stok})', style: TextStyle(color: b.stok > 0 ? (isDark ? Colors.white : Colors.black) : CupertinoColors.systemRed)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIdBuku = v),
                    ),
                    _buildDivider(isDark),
                    _buildCupertinoDropdown<int>(
                      isDark: isDark,
                      value: _durasiHari,
                      title: AppState.getString('loan_duration_select'),
                      icon: CupertinoIcons.time_solid,
                      items: [
                        DropdownMenuItem(value: 3, child: Text('3 ${AppState.getString('days')}')),
                        DropdownMenuItem(value: 7, child: Text('7 ${AppState.getString('days')}')),
                        DropdownMenuItem(value: 14, child: Text('14 ${AppState.getString('days')}')),
                      ],
                      onChanged: (v) => setState(() => _durasiHari = v ?? 7),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: CupertinoButton(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
              onPressed: _buatManualPinjam,
              child: Text(AppState.getString('loan_submit_btn'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildCupertinoDropdown<T>({
    required bool isDark,
    required T? value,
    required String title,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 22),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16),
                icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                isExpanded: true,
                hint: Text(AppState.getString('choose'), style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Container(height: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
    );
  }
}