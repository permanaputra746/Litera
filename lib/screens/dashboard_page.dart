import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../utils/app_state.dart';
import '../models/buku_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/peminjaman_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final StorageService _storage = StorageService();
  List<Buku> _bukuList = [];
  List<Mahasiswa> _mahasiswaList = [];
  List<Peminjaman> _allLoans = [];

  int _totalBuku = 0;
  int _totalMahasiswa = 0;
  int _totalPeminjaman = 0; // Active Loans count
  bool _isLoading = true;
  
  // Data for chart
  List<FlSpot> _chartData = [];
  double _maxY = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final buku = await _storage.getBukuList();
    final mahasiswa = await _storage.getMahasiswaList();
    final peminjaman = await _storage.getPeminjamanList();

    // Process Chart Data (Last 7 Days)
    List<FlSpot> spots = [];
    double maxY = 1;
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dateStr = targetDate.toString().split(' ')[0];
      
      // Count transactions on this date
      final count = peminjaman.where((p) => p.tanggal == dateStr).length;
      
      spots.add(FlSpot(6 - i.toDouble(), count.toDouble()));
      if (count > maxY) maxY = count.toDouble();
    }

    if (mounted) {
      setState(() {
        _bukuList = buku;
        _mahasiswaList = mahasiswa;
        _allLoans = peminjaman;
        _totalBuku = buku.length;
        _totalMahasiswa = mahasiswa.length;
        _totalPeminjaman = peminjaman.where((p) => p.status == 'disetujui').length;
        _chartData = spots;
        _maxY = maxY + 1; // Add some headroom
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.langNotifier,
      builder: (context, currentLang, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return _isLoading
            ? Center(child: CupertinoActivityIndicator(radius: 20, color: Theme.of(context).primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: AppState.adminNameNotifier,
                      builder: (context, adminName, _) {
                        return Text(
                          'Hello, $adminName',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
                      }
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppState.getString('overview'),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: _buildAppleStatCard(AppState.getString('books'), _totalBuku.toString(), CupertinoIcons.book_fill, const Color(0xFF007AFF), 100, isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAppleStatCard(AppState.getString('students'), _totalMahasiswa.toString(), CupertinoIcons.person_2_fill, const Color(0xFF5856D6), 200, isDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAppleStatCard(AppState.getString('active_loans'), _totalPeminjaman.toString(), CupertinoIcons.arrow_right_arrow_left, const Color(0xFFFF2D55), 300, isDark),
                    
                    const SizedBox(height: 16),
                    // Monthly Report Button
                    _buildReportButton(isDark),
                    
                    const SizedBox(height: 40),

                    Text(
                      AppState.getString('activity'),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic),
                    const SizedBox(height: 16),
                    _buildAppleChart(isDark).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic),
                    const SizedBox(height: 120),
                  ],
                ),
              );
      }
    );
  }

  Widget _buildAppleStatCard(String title, String value, IconData icon, Color color, int delayMs, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildReportButton(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showMonthlyReportSheet(isDark);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_text_fill, color: Colors.orange, size: 24),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppState.getString('report_title'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(AppState.getString('report_subtitle'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Icon(CupertinoIcons.right_chevron, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
 
  void _showMonthlyReportSheet(bool isDark) {
    // 1. Total borrowings
    final totalLoansCount = _allLoans.length;
 
    // 2. Most frequently borrowed books (popular)
    final Map<String, int> bookCount = {};
    for (var loan in _allLoans) {
      bookCount[loan.judulBuku] = (bookCount[loan.judulBuku] ?? 0) + 1;
    }
    final sortedBooks = bookCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
 
    // 3. Most active students
    final Map<String, int> studentCount = {};
    for (var loan in _allLoans) {
      studentCount[loan.nim] = (studentCount[loan.nim] ?? 0) + 1;
    }
    final sortedStudents = studentCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
 
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
              height: MediaQuery.of(context).size.height * 0.75,
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
                  Text(AppState.getString('report_heading'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(AppState.getString('report_desc'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),
                  
                  // Summary Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppState.getString('report_total_loans'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('$totalLoansCount ${AppState.getString("report_times")}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // Section 1: Most borrowed books
                  Text(AppState.getString('report_popular_books'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: sortedBooks.isEmpty
                        ? Center(child: Text(AppState.getString('report_no_data'), style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: sortedBooks.length > 3 ? 3 : sortedBooks.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (c, idx) {
                              final item = sortedBooks[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
                                  child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                                ),
                                title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Text('${item.value} ${AppState.getString("report_times_borrowed")}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  
                  // Section 2: Most active students
                  Text(AppState.getString('report_active_students'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: sortedStudents.isEmpty
                        ? Center(child: Text(AppState.getString('report_no_data'), style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: sortedStudents.length > 3 ? 3 : sortedStudents.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (c, idx) {
                              final item = sortedStudents[idx];
                              String name = item.key;
                              try {
                                name = _mahasiswaList.firstWhere((m) => m.nim == item.key).nama;
                              } catch (_) {}
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF5856D6).withValues(alpha: 0.1),
                                  child: Text('${idx + 1}', style: const TextStyle(color: Color(0xFF5856D6), fontWeight: FontWeight.bold)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('NIM: ${item.key}'),
                                trailing: Text('${item.value} ${AppState.getString("report_books_borrowed")}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
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

  Widget _buildAppleChart(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final style = TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      );
                      int index = value.toInt();
                      if (index < 0 || index > 6) return const SizedBox();
                      
                      final targetDate = DateTime.now().subtract(Duration(days: 6 - index));
                      return SideTitleWidget(meta: meta, child: Text(targetDate.day.toString(), style: style));
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: _maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: _chartData,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  color: const Color(0xFF007AFF),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF007AFF).withValues(alpha: 0.3),
                        const Color(0xFF007AFF).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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