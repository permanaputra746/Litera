class Buku {
  final String id;
  final String judul;
  final String penulis;
  final String kategori;
  final String tahunTerbit;
  final String lokasiRak;
  final String cover;
  int stok;

  Buku({
    required this.id,
    required this.judul,
    required this.penulis,
    required this.kategori,
    required this.tahunTerbit,
    required this.lokasiRak,
    required this.cover,
    required this.stok,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'penulis': penulis,
      'kategori': kategori,
      'tahunTerbit': tahunTerbit,
      'lokasiRak': lokasiRak,
      'cover': cover,
      'stok': stok,
    };
  }

  factory Buku.fromJson(Map<String, dynamic> json) {
    return Buku(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      penulis: json['penulis']?.toString() ?? json['penerbit']?.toString() ?? 'Anonim',
      kategori: json['kategori']?.toString() ?? 'Umum',
      tahunTerbit: json['tahunTerbit']?.toString() ?? json['tahun_terbit']?.toString() ?? '2024',
      lokasiRak: json['lokasiRak']?.toString() ?? json['lokasi_rak']?.toString() ?? 'Rak A-1',
      cover: json['cover']?.toString() ?? '',
      stok: int.tryParse(json['stok']?.toString() ?? '0') ?? 0,
    );
  }

  String toStorageString() {
    return '$id|$judul|$penulis|$kategori|$tahunTerbit|$lokasiRak|$cover|$stok';
  }

  factory Buku.fromStorageString(String str) {
    final parts = str.split('|');
    return Buku(
      id: parts[0],
      judul: parts[1],
      penulis: parts.length > 2 ? parts[2] : 'Anonim',
      kategori: parts.length > 3 ? parts[3] : 'Umum',
      tahunTerbit: parts.length > 4 ? parts[4] : '2024',
      lokasiRak: parts.length > 5 ? parts[5] : 'Rak A-1',
      cover: parts.length > 6 ? parts[6] : '',
      stok: parts.length > 7 ? (int.tryParse(parts[7]) ?? 0) : (parts.length > 3 ? (int.tryParse(parts[3]) ?? 0) : 0),
    );
  }
}