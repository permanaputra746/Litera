import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mahasiswa_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../utils/app_state.dart';
import '../widgets/mahasiswa_form_dialog.dart';

class MahasiswaPage extends StatefulWidget {
  const MahasiswaPage({super.key});

  @override
  State<MahasiswaPage> createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  final StorageService _storage = StorageService();
  List<Mahasiswa> _mahasiswaList = [];
  List<Mahasiswa> _filteredMahasiswa = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.getMahasiswaList();
    if (mounted) {
      setState(() {
        _mahasiswaList = data;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMahasiswa = _mahasiswaList.where((m) {
        return m.nama.toLowerCase().contains(_searchQuery.toLowerCase()) || 
               m.nim.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _tambahMahasiswa(Mahasiswa mhs) async {
    HapticFeedback.lightImpact();
    setState(() => _mahasiswaList.add(mhs));
    await _storage.saveMahasiswaList(_mahasiswaList);

    // Sync notification to remote DB for admin
    try {
      await ApiService.sendNotification(
        'admin',
        'Mahasiswa Baru Terdaftar',
        'Mahasiswa baru bernama "${mhs.nama}" (NIM: ${mhs.nim}) telah didaftarkan.',
      );
    } catch (_) {}

    _applyFilters();
  }

  Future<void> _editMahasiswa(int index, Mahasiswa mhs) async {
    HapticFeedback.lightImpact();
    final realIndex = _mahasiswaList.indexWhere((m) => m.nim == _filteredMahasiswa[index].nim);
    if (realIndex != -1) {
      setState(() => _mahasiswaList[realIndex] = mhs);
      await _storage.saveMahasiswaList(_mahasiswaList);
      _applyFilters();
    }
  }

  Future<void> _hapusMahasiswa(int index) async {
    HapticFeedback.lightImpact();
    final realIndex = _mahasiswaList.indexWhere((m) => m.nim == _filteredMahasiswa[index].nim);
    if (realIndex != -1) {
      setState(() => _mahasiswaList.removeAt(realIndex));
      await _storage.saveMahasiswaList(_mahasiswaList);
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
                // Apple Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppState.getString('students'),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black, 
                          fontSize: 34, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: -0.5
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
                          placeholder: AppState.getString('search_students'),
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilters();
                          },
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
            
            // List View
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: Theme.of(context).colorScheme.secondary,
                child: _filteredMahasiswa.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_3, size: 60, color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(height: 16),
                            Text(AppState.getString('no_students'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 17)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                        itemCount: _filteredMahasiswa.length,
                        itemBuilder: (ctx, i) {
                          final m = _filteredMahasiswa[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (ctx) => CupertinoActionSheet(
                                    title: Text(m.nama),
                                    message: Text(AppState.getString('student_action_title')),
                                    actions: [
                                      CupertinoActionSheetAction(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          showDialog(
                                            context: context,
                                            builder: (dialogCtx) => MahasiswaFormDialog(
                                              initialData: m,
                                              onSave: (mBaru) async {
                                                await _editMahasiswa(i, mBaru);
                                                if(mounted) Navigator.pop(dialogCtx);
                                              },
                                            ),
                                          );
                                        },
                                        child: Text(AppState.getString('student_edit')),
                                      ),
                                      CupertinoActionSheetAction(
                                        isDestructiveAction: true,
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _hapusMahasiswa(i);
                                        },
                                        child: Text(AppState.getString('student_delete')),
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
                                        // Avatar Mock
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF5E5CE6), Color(0xFF32ADE6)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(CupertinoIcons.person_solid, color: Colors.white, size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.nama,
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'ID: ${m.nim} • ${m.kelas}',
                                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${AppState.getString('form_label_major')}: ${m.jurusan} • ${AppState.getString('form_label_age')}: ${m.umur} ${AppState.getString('years_old_abbr')}',
                                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Actions
                                        Column(
                                          children: [
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              child: Icon(CupertinoIcons.pencil_circle_fill, color: Theme.of(context).colorScheme.secondary, size: 28),
                                              onPressed: () => showDialog(
                                                context: context,
                                                builder: (ctx) => MahasiswaFormDialog(
                                                  initialData: m,
                                                  onSave: (mBaru) async {
                                                    await _editMahasiswa(i, mBaru);
                                                    if(mounted) Navigator.pop(ctx);
                                                  },
                                                ),
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              child: const Icon(CupertinoIcons.minus_circle_fill, color: Color(0xFFFF3B30), size: 28),
                                              onPressed: () => _hapusMahasiswa(i),
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
              builder: (ctx) => MahasiswaFormDialog(
                onSave: (mhs) async {
                  await _tambahMahasiswa(mhs);
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
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(AppState.getString('new_student'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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