import 'package:flutter/material.dart';
import '../models/peminjaman_model.dart';
import '../services/storage_service.dart';
import '../widgets/stat_card.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final StorageService _storage = StorageService();
  int _totalBuku = 0;
  int _totalMahasiswa = 0;
  int _totalPeminjaman = 0;
  List<Peminjaman> _peminjamanList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final totalBuku = await _storage.getTotalBuku();
    final totalMahasiswa = await _storage.getTotalMahasiswa();
    final totalPeminjaman = await _storage.getTotalPeminjaman();
    final peminjaman = await _storage.getPeminjamanList();

    setState(() {
      _totalBuku = totalBuku;
      _totalMahasiswa = totalMahasiswa;
      _totalPeminjaman = totalPeminjaman;
      _peminjamanList = peminjaman;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Laporan Litera', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF6A1B9A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  StatCard(
                    title: 'Total Buku',
                    value: _totalBuku.toString(),
                    icon: Icons.book_outlined,
                    color: const Color(0xFF00796B),
                  ),
                  const SizedBox(width: 15),
                  StatCard(
                    title: 'Mahasiswa',
                    value: _totalMahasiswa.toString(),
                    icon: Icons.person_outline,
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 15),
                  StatCard(
                    title: 'Peminjaman',
                    value: _totalPeminjaman.toString(),
                    icon: Icons.swap_horiz,
                    color: const Color(0xFFE65100),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                '📋 Daftar Peminjaman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 15),
              if (_peminjamanList.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.book_outlined, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada data peminjaman',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _peminjamanList.length,
                  itemBuilder: (ctx, i) {
                    final p = _peminjamanList[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6A1B9A).withOpacity(0.1),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                        title: Text(p.judulBuku, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('NIM: ${p.nim}'),
                        trailing: Text(
                          p.tanggal,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}