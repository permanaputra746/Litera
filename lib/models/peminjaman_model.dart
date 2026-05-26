class Peminjaman {
  final String id;
  final String nim;
  final String bukuId;
  final String judulBuku;
  final String tanggal; // represents tanggalPinjam
  final int durasiHari;
  final String tanggalKembali;
  final String status; // 'diproses', 'disetujui', 'ditolak', 'dikembalikan'
  final double denda;

  Peminjaman({
    required this.id,
    required this.nim,
    required this.bukuId,
    required this.judulBuku,
    required this.tanggal,
    required this.durasiHari,
    this.tanggalKembali = '',
    this.status = 'diproses',
    this.denda = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nim': nim,
      'bukuId': bukuId,
      'judulBuku': judulBuku,
      'tanggal': tanggal,
      'durasiHari': durasiHari,
      'tanggalKembali': tanggalKembali,
      'status': status,
      'denda': denda,
    };
  }

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nim: json['nim']?.toString() ?? '',
      bukuId: json['bukuId']?.toString() ?? '',
      judulBuku: json['judulBuku']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      durasiHari: int.tryParse(json['durasiHari']?.toString() ?? '7') ?? 7,
      tanggalKembali: json['tanggalKembali']?.toString() ?? '',
      status: json['status']?.toString() ?? 'diproses',
      denda: double.tryParse(json['denda']?.toString() ?? '0') ?? 0.0,
    );
  }

  String toStorageString() {
    return '$id|$nim|$bukuId|$judulBuku|$tanggal|$durasiHari|$tanggalKembali|$status|$denda';
  }

  factory Peminjaman.fromStorageString(String str) {
    final parts = str.split('|');
    return Peminjaman(
      id: parts[0],
      nim: parts[1],
      bukuId: parts.length > 2 ? parts[2] : '',
      judulBuku: parts.length > 3 ? parts[3] : '',
      tanggal: parts.length > 4 ? parts[4] : '',
      durasiHari: parts.length > 5 ? (int.tryParse(parts[5]) ?? 7) : 7,
      tanggalKembali: parts.length > 6 ? parts[6] : '',
      status: parts.length > 7 ? parts[7] : 'diproses',
      denda: parts.length > 8 ? (double.tryParse(parts[8]) ?? 0.0) : 0.0,
    );
  }
}