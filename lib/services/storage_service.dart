import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buku_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/peminjaman_model.dart';
import '../models/booking_model.dart';
import 'api_service.dart';

class StorageService {
  // SETTINGS
  Future<void> saveAdminName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_name', name);
  }

  Future<String> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_name') ?? 'NEXUS ADMIN';
  }

  Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_lang') ?? 'id';
  }

  // BUKU
  Future<List<Buku>> getBukuList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('buku_data');
      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> data = jsonDecode(dataString);
        return data.map((json) => Buku.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getBukuList: $e');
    }
    return _getDefaultBukuList();
  }

  Future<void> saveBukuList(List<Buku> bukuList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(bukuList.map((b) => b.toJson()).toList());
      await prefs.setString('buku_data', dataString);
    } catch (e) {
      print('Error saveBukuList: $e');
    }
  }

  List<Buku> _getDefaultBukuList() {
    return [
      Buku(id: 'BK001', judul: 'Belajar Dart', penulis: 'Informatika', kategori: 'Pemrograman', tahunTerbit: '2022', lokasiRak: 'Rak A-1', cover: '', stok: 4),
      Buku(id: 'BK002', judul: 'Belajar Flutter', penulis: 'Andi Publisher', kategori: 'Mobile Dev', tahunTerbit: '2023', lokasiRak: 'Rak B-2', cover: '', stok: 5),
      Buku(id: 'BK003', judul: 'Pemrograman Dasar', penulis: 'Gramedia', kategori: 'Dasar', tahunTerbit: '2021', lokasiRak: 'Rak C-1', cover: '', stok: 3),
    ];
  }

  // MAHASISWA
  Future<List<Mahasiswa>> getMahasiswaList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('mahasiswa_data');
      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> data = jsonDecode(dataString);
        return data.map((json) => Mahasiswa.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getMahasiswaList: $e');
    }
    return _getDefaultMahasiswaList();
  }

  Future<void> saveMahasiswaList(List<Mahasiswa> mahasiswaList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(mahasiswaList.map((m) => m.toJson()).toList());
      await prefs.setString('mahasiswa_data', dataString);
    } catch (e) {
      print('Error saveMahasiswaList: $e');
    }
  }

  List<Mahasiswa> _getDefaultMahasiswaList() {
    return [
      Mahasiswa(nim: '09030015', nama: 'Joko'),
      Mahasiswa(nim: '09030016', nama: 'Udin'),
      Mahasiswa(nim: '09030017', nama: 'Siti'),
    ];
  }

  // PEMINJAMAN
  Future<List<Peminjaman>> getPeminjamanList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('peminjaman_data');
      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> data = jsonDecode(dataString);
        return data.map((json) => Peminjaman.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getPeminjamanList: $e');
    }
    return [];
  }

  Future<void> savePeminjamanList(List<Peminjaman> peminjamanList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(peminjamanList.map((p) => p.toJson()).toList());
      await prefs.setString('peminjaman_data', dataString);
    } catch (e) {
      print('Error savePeminjamanList: $e');
    }
  }

  // STATISTIK
  Future<int> getTotalBuku() async {
    final buku = await getBukuList();
    return buku.length;
  }

  Future<int> getTotalMahasiswa() async {
    final mahasiswa = await getMahasiswaList();
    return mahasiswa.length;
  }

  Future<int> getTotalPeminjaman() async {
    final peminjaman = await getPeminjamanList();
    return peminjaman.length;
  }

  // BOOKMARKS / FAVORITES (Stored as list of book IDs)
  Future<List<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('favorite_books') ?? [];
    } catch (e) {
      print('Error getFavorites: $e');
      return [];
    }
  }

  Future<void> toggleFavorite(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favs = prefs.getStringList('favorite_books') ?? [];
      if (favs.contains(bookId)) {
        favs.remove(bookId);
      } else {
        favs.add(bookId);
      }
      await prefs.setStringList('favorite_books', favs);
    } catch (e) {
      print('Error toggleFavorite: $e');
    }
  }

  // BOOKINGS (Book queue reservation)
  Future<List<Booking>> getBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('booking_data');
      if (dataString != null && dataString.isNotEmpty) {
        final List<dynamic> data = jsonDecode(dataString);
        return data.map((json) => Booking.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getBookings: $e');
    }
    return [];
  }

  Future<void> saveBookings(List<Booking> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = jsonEncode(bookings.map((b) => b.toJson()).toList());
      await prefs.setString('booking_data', dataString);
    } catch (e) {
      print('Error saveBookings: $e');
    }
  }

  Future<void> addBooking(Booking booking) async {
    final bookings = await getBookings();
    bookings.add(booking);
    await saveBookings(bookings);
  }
}