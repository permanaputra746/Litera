class Mahasiswa {
  final String nim;
  final String nama;
  final String kelas;
  final String jurusan;
  final int umur;

  Mahasiswa({
    required this.nim,
    required this.nama,
    this.kelas = '-',
    this.jurusan = '-',
    this.umur = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'nama': nama,
      'kelas': kelas,
      'jurusan': jurusan,
      'umur': umur,
    };
  }

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? '-',
      jurusan: json['jurusan']?.toString() ?? '-',
      umur: json['umur'] != null ? int.tryParse(json['umur'].toString()) ?? 0 : 0,
    );
  }

  String toStorageString() {
    return '$nim|$nama|$kelas|$jurusan|$umur';
  }

  factory Mahasiswa.fromStorageString(String str) {
    final parts = str.split('|');
    return Mahasiswa(
      nim: parts.isNotEmpty ? parts[0] : '',
      nama: parts.length > 1 ? parts[1] : '',
      kelas: parts.length > 2 ? parts[2] : '-',
      jurusan: parts.length > 3 ? parts[3] : '-',
      umur: parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0,
    );
  }
}