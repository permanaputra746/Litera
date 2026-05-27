import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti IP ini dengan IP Wi-Fi lokal Anda jika menggunakan device HP asli (contoh: 192.168.1.5)
  static String get baseUrl {
    // Karena Anda menggunakan HP fisik yang connect hotspot, kita harus pakai IP Hotspot
    return 'http://172.20.10.6/perpustakaan_api';
  }

  static Future<Map<String, dynamic>> register(String username, String password) async {
    final url = Uri.parse('$baseUrl/register.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal terhubung ke server. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal terhubung ke server. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }
  static Future<Map<String, dynamic>> loginWithGoogle(String email, String name, String role) async {
    final url = Uri.parse('$baseUrl/login_google.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal terhubung ke server. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }
  static Future<Map<String, dynamic>> loginStudent(String nim, String password) async {
    final url = Uri.parse('$baseUrl/mahasiswa.php?action=login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nim': nim,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal terhubung ke server. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerStudent(Map<String, dynamic> studentData) async {
    final url = Uri.parse('$baseUrl/mahasiswa.php?action=register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal terhubung ke server. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<List<dynamic>> getNotifications(String userId) async {
    final url = Uri.parse('$baseUrl/notifikasi.php?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> sendNotification(String userId, String title, String body) async {
    final url = Uri.parse('$baseUrl/notifikasi.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'body': body,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'status': 'error', 'message': 'Gagal mengirim notifikasi'};
  }

  static Future<Map<String, dynamic>> markNotificationsAsRead(String userId) async {
    final url = Uri.parse('$baseUrl/notifikasi.php');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'status': 'error', 'message': 'Gagal menandai notifikasi'};
  }
}

