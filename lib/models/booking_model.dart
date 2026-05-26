class Booking {
  final String id;
  final String nim;
  final String bukuId;
  final String judulBuku;
  final String tanggalBooking;
  final String status; // 'menunggu', 'siap', 'selesai'

  Booking({
    required this.id,
    required this.nim,
    required this.bukuId,
    required this.judulBuku,
    required this.tanggalBooking,
    this.status = 'menunggu',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nim': nim,
      'bukuId': bukuId,
      'judulBuku': judulBuku,
      'tanggalBooking': tanggalBooking,
      'status': status,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      bukuId: json['bukuId']?.toString() ?? '',
      judulBuku: json['judulBuku']?.toString() ?? '',
      tanggalBooking: json['tanggalBooking']?.toString() ?? '',
      status: json['status']?.toString() ?? 'menunggu',
    );
  }

  String toStorageString() {
    return '$id|$nim|$bukuId|$judulBuku|$tanggalBooking|$status';
  }

  factory Booking.fromStorageString(String str) {
    final parts = str.split('|');
    return Booking(
      id: parts[0],
      nim: parts[1],
      bukuId: parts.length > 2 ? parts[2] : '',
      judulBuku: parts.length > 3 ? parts[3] : '',
      tanggalBooking: parts.length > 4 ? parts[4] : '',
      status: parts.length > 5 ? parts[5] : 'menunggu',
    );
  }
}
