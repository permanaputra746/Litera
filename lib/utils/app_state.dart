import 'package:flutter/material.dart';

class AppState {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<String> langNotifier = ValueNotifier('id'); // 'id' or 'en'
  static final ValueNotifier<String> adminNameNotifier = ValueNotifier('NEXUS ADMIN');
  static final ValueNotifier<String> userRoleNotifier = ValueNotifier('admin'); // 'admin' or 'siswa'
  static final ValueNotifier<String> studentNIMNotifier = ValueNotifier('');
  static final ValueNotifier<String> studentNameNotifier = ValueNotifier('');

  static void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void changeLanguage(String langCode) {
    langNotifier.value = langCode;
  }

  static void updateAdminName(String newName) {
    adminNameNotifier.value = newName;
  }

  static void updateUserRole(String role) {
    userRoleNotifier.value = role;
  }

  static void updateStudentData(String nim, String name) {
    studentNIMNotifier.value = nim;
    studentNameNotifier.value = name;
  }

  // --- GLOBAL DICTIONARY ---
  static const Map<String, Map<String, String>> dict = {
    'id': {
      // Home Page Dock
      'hub': 'Utama',
      'books': 'Buku',
      'students': 'Siswa',
      'loans': 'Pinjam',
      'settings': 'Opsi',
      'library': 'Litera',
      
      // Dashboard
      'overview': 'Ringkasan',
      'active_loans': 'Peminjaman Aktif',
      'activity': 'Aktivitas',
      
      // Buku
      'search_books': 'Cari koleksi buku...',
      'all': 'Semua',
      'available': 'Tersedia',
      'out_of_stock': 'Habis',
      'no_books': 'Buku tidak ditemukan',
      'stock': 'Stok',
      'new_book': 'Buku Baru',
      
      // Mahasiswa
      'search_students': 'Cari kontak siswa...',
      'no_students': 'Siswa tidak ditemukan',
      'new_student': 'Kontak Baru',
      
      // Peminjaman
      'new_loan': 'Pinjaman Baru',
      'wallet_active': 'Pinjaman Aktif',
      'student': 'Siswa',
      'book': 'Buku',
      'duration': 'Durasi',
      'days': 'Hari',
      'authorize_loan': 'Otorisasi Pinjaman',
      'wallet_empty': 'Belum ada pinjaman',
      'library_pass': 'LITERA PASS',
      'issued': 'Dikeluarkan',
      'return': 'Kembalikan',
      'overdue': 'Terlambat',
      'due_today': 'Jatuh tempo hari ini',
      'days_left': 'hari tersisa',

      // Settings & Shared Profile
      'title': 'Pengaturan',
      'level_student': 'Akses Siswa / Mahasiswa',
      'level_admin': 'Level 5 Akses',
      'pref': 'PREFERENSI',
      'notif': 'Notifikasi Senyap',
      'notif_active_msg': 'Fitur notifikasi senyap aktif',
      'dark': 'Mode Gelap (Enforced)',
      'lang': 'Bahasa (Language)',
      'sys': 'SISTEM',
      'info': 'Sistem Info',
      'logout': 'Keluar dari Akun',
      'confirm_logout': 'Apakah Anda yakin ingin keluar?',
      'cancel': 'Batal',
      'confirm': 'Keluar',
      'edit_name': 'Ubah Nama',
      'save': 'Simpan',
      'dock_main': 'Utama',
      'dock_search': 'Cari',
      'dock_fav': 'Favorit',
      'dock_loans': 'Pinjamanku',
      'dock_options': 'Opsi',
      'db_avail': 'Buku Tersedia',
      'db_borrowed': 'Sedang Dipinjam',
      'db_pop': '🔥 Koleksi Terpopuler',
      'db_latest': '📚 Buku Terbaru',
      'db_stock_out': 'Habis',
      'db_stock': 'Stok',
      'search_placeholder': 'Cari judul, penulis, kategori...',
      'search_empty': 'Buku tidak ditemukan',
      'detail_synopsis': 'Sinopsis',
      'detail_synopsis_text': 'Buku ini merupakan salah satu literatur unggulan di perpustakaan kami. Memberikan ulasan komprehensif mengenai konsep dasar dan implementasi praktis di bidangnya, ditulis khusus untuk menunjang kegiatan pembelajaran.',
      'detail_stock': 'Stok Tersedia',
      'detail_borrow': 'Pinjam Buku',
      'detail_booking': 'Booking Buku',
      'detail_already_booked': 'Sudah Di-booking',
      'detail_dur_title': 'Pilih Durasi Peminjaman',
      'detail_days': 'Hari',
      'fav_empty': 'Belum ada buku favorit',
      'loans_empty': 'Belum ada riwayat peminjaman',
      'loans_date': 'TANGGAL',
      'loans_duration': 'Durasi Pinjam',
      'loans_fine': 'Denda Keterlambatan',
      'app_title': 'Litera',
      'writer': 'Penulis',
      'category': 'Kategori',
      'pub_year': 'Tahun Terbit',
      'shelf_loc': 'Lokasi Rak',

      // Notifications
      'notif_title': 'Notifikasi',
      'notif_unread': 'belum dibaca',
      'notif_mark_read': 'Tandai Dibaca',
      'notif_empty': 'Belum ada notifikasi',
      'err_loan_limit': 'Limit pinjaman terlampaui (Maks 2 buku)',
      'notif_loan_requested': 'Peminjaman Diajukan',
      'notif_loan_pending_body_1': 'Peminjaman',
      'notif_loan_pending_body_2': 'sedang menunggu persetujuan admin.',
      'notif_new_loan_request_title': 'Permintaan Peminjaman Baru',
      'notif_new_loan_request_body': 'mengajukan peminjaman buku',
      'msg_loan_request_success': 'Pengajuan peminjaman berhasil dikirim!',
      'notif_booking_success_title': 'Booking Buku Berhasil',
      'notif_booking_success_body_1': 'Antrean booking',
      'notif_booking_success_body_2': 'terdaftar. Kami akan memberi tahu jika buku tersedia.',
      'notif_new_booking_request_title': 'Antrean Booking Baru',
      'notif_new_booking_request_body': 'mem-booking buku',
      'msg_booking_success': 'Booking berhasil ditambahkan ke antrean!',

      // Peminjaman (Admin)
      'loan_title': 'Peminjaman',
      'loan_tab_request': 'Pengajuan',
      'loan_tab_active': 'Aktif',
      'loan_tab_history': 'Riwayat',
      'loan_tab_manual': 'Manual',
      'loan_no_pending': 'Tidak ada pengajuan pending',
      'loan_no_active': 'Tidak ada peminjaman aktif',
      'loan_no_history': 'Tidak ada riwayat peminjaman',
      'loan_action_approve': 'Setujui',
      'loan_action_reject': 'Tolak',
      'loan_status_approved': 'Aktif / Disetujui',
      'loan_status_returned': 'Telah Dikembalikan',
      'loan_status_rejected': 'Ditolak',
      'loan_status_pending': 'Diproses',
      'loan_select_student': 'Pilih Siswa',
      'loan_select_book': 'Pilih Buku',
      'loan_duration_select': 'Durasi Peminjaman',
      'loan_submit_btn': 'Buat Transaksi',
      'loan_confirm_return': 'Kembalikan Buku',
      'loan_confirm_return_msg': 'Apakah Anda yakin ingin mengembalikan buku ini?',
      'loan_msg_complete': 'Pengembalian Berhasil',
      'loan_msg_fill_fields': 'Mohon lengkapi semua data',
      'loan_msg_limit_exceeded': 'Siswa ini sudah mencapai limit (Maks 2 buku)',
      'loan_msg_out_of_stock': 'Stok buku habis',
      'loan_msg_success': 'Peminjaman Manual Berhasil',
      'notif_return_title': 'Pengembalian Dikonfirmasi',
      'notif_return_body': 'Terima kasih telah mengembalikan buku',
      'notif_approved_title': 'Peminjaman Disetujui',
      'notif_approved_body': 'Peminjaman buku Anda telah disetujui oleh admin',
      'notif_rejected_title': 'Peminjaman Ditolak',
      'notif_rejected_body': 'Peminjaman buku Anda ditolak oleh admin',

      // Report & Dashboard (Admin)
      'report_title': 'Laporan Bulanan Litera',
      'report_subtitle': 'Buku terpopuler, transaksi aktif, & mahasiswa teraktif',
      'report_heading': '📊 Laporan Bulanan',
      'report_desc': 'Statistik Litera terbaru',
      'report_total_loans': 'Total Transaksi Peminjaman',
      'report_times': 'Kali',
      'report_popular_books': '📚 Buku Paling Sering Dipinjam',
      'report_no_data': 'Belum ada data',
      'report_times_borrowed': 'x dipinjam',
      'report_active_students': '👤 Mahasiswa Paling Aktif',
      'report_books_borrowed': 'Buku',

      // Mahasiswa (Admin)
      'student_action_title': 'Pilih aksi untuk siswa ini',
      'student_edit': 'Edit Profil',
      'student_delete': 'Hapus Akun',

      // Buku (Admin)
      'book_edit': 'Edit Buku',
      'book_delete': 'Hapus Buku',

      // Forms
      'form_add_student': 'Tambah Mahasiswa Baru',
      'form_edit_student': 'Edit Mahasiswa',
      'form_err_nim': 'NIM harus diisi',
      'form_err_name': 'Nama harus diisi',
      'form_err_class': 'Kelas harus diisi',
      'form_err_major': 'Jurusan harus diisi',
      'form_err_age': 'Umur harus diisi',
      'form_add_book': 'Tambah Buku Baru',
      'form_edit_book': 'Edit Buku',
      'form_label_book_id': 'ID Buku (e.g. BK001)',
      'form_err_id': 'ID harus diisi',
      'form_label_title': 'Judul Buku',
      'form_err_title': 'Judul harus diisi',
      'form_label_writer': 'Penulis / Pengarang',
      'form_err_writer': 'Penulis harus diisi',
      'form_label_category': 'Kategori (e.g. Fiksi, Sains)',
      'form_err_category': 'Kategori harus diisi',
      'form_label_pub_year': 'Tahun Terbit',
      'form_err_required': 'Wajib',
      'form_label_shelf': 'Lokasi Rak',
      'form_label_stock': 'Jumlah Stok',
      'form_err_stock': 'Stok harus diisi',
      'form_label_nim': 'NIM',
      'form_label_name': 'Nama Lengkap',
      'form_label_class': 'Kelas',
      'form_label_major': 'Jurusan',
      'form_label_age': 'Umur',
      'by': 'Oleh',
      'shelf': 'Rak',
      'year': 'Tahun',
      'choose': 'Pilih',
      'admin_subtitle': 'Administrator Sistem Litera',
      'years_old_abbr': 'thn',
      'hello': 'Halo',
    },
    'en': {
      // Home Page Dock
      'hub': 'Hub',
      'books': 'Books',
      'students': 'Students',
      'loans': 'Loans',
      'settings': 'Settings',
      'library': 'Litera',
      
      // Dashboard
      'overview': 'Overview',
      'active_loans': 'Active Loans',
      'activity': 'Activity',
      
      // Buku
      'search_books': 'Search library...',
      'all': 'All',
      'available': 'Available',
      'out_of_stock': 'Out of Stock',
      'no_books': 'No books found',
      'stock': 'Stock',
      'new_book': 'New Book',
      
      // Mahasiswa
      'search_students': 'Search contacts...',
      'no_students': 'No contacts found',
      'new_student': 'New Contact',
      
      // Peminjaman
      'new_loan': 'New Loan',
      'wallet_active': 'Active Loans',
      'student': 'Student',
      'book': 'Book',
      'duration': 'Duration',
      'days': 'Days',
      'authorize_loan': 'Authorize Loan',
      'wallet_empty': 'No active loans',
      'library_pass': 'LITERA PASS',
      'issued': 'Issued',
      'return': 'Return',
      'overdue': 'Overdue',
      'due_today': 'Due Today',
      'days_left': 'days left',

      // Settings & Shared Profile
      'title': 'Settings',
      'level_student': 'Student Clearance',
      'level_admin': 'Level 5 Clearance',
      'pref': 'PREFERENCES',
      'notif': 'Silent Notifications',
      'notif_active_msg': 'Silent notifications are active',
      'dark': 'Dark Mode',
      'lang': 'Language',
      'sys': 'SYSTEM',
      'info': 'About',
      'logout': 'Sign Out',
      'confirm_logout': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'confirm': 'Sign Out',
      'edit_name': 'Edit Name',
      'save': 'Save',
      'dock_main': 'Home',
      'dock_search': 'Search',
      'dock_fav': 'Favorites',
      'dock_loans': 'My Loans',
      'dock_options': 'Settings',
      'db_avail': 'Books Available',
      'db_borrowed': 'Borrowed Books',
      'db_pop': '🔥 Most Popular',
      'db_latest': '📚 New Releases',
      'db_stock_out': 'Out of Stock',
      'db_stock': 'Stock',
      'search_placeholder': 'Search title, author, category...',
      'search_empty': 'No books found',
      'detail_synopsis': 'Synopsis',
      'detail_synopsis_text': 'This book is one of the leading literatures in our library. It provides a comprehensive review of basic concepts and practical implementation, written specifically to support learning activities.',
      'detail_stock': 'Available Stock',
      'detail_borrow': 'Borrow Book',
      'detail_booking': 'Book Queue',
      'detail_already_booked': 'Already Booked',
      'detail_dur_title': 'Choose Borrow Duration',
      'detail_days': 'Days',
      'fav_empty': 'No favorite books yet',
      'loans_empty': 'No borrowing history',
      'loans_date': 'DATE',
      'loans_duration': 'Borrow Duration',
      'loans_fine': 'Overdue Fine',
      'app_title': 'Litera',
      'writer': 'Author',
      'category': 'Category',
      'pub_year': 'Publish Year',
      'shelf_loc': 'Shelf Location',

      // Notifications
      'notif_title': 'Notifications',
      'notif_unread': 'unread',
      'notif_mark_read': 'Mark as Read',
      'notif_empty': 'No notifications yet',
      'err_loan_limit': 'Borrow limit exceeded (Max 2 books)',
      'notif_loan_requested': 'Borrow Requested',
      'notif_loan_pending_body_1': 'Borrowing for',
      'notif_loan_pending_body_2': 'is waiting for admin approval.',
      'notif_new_loan_request_title': 'New Borrow Request',
      'notif_new_loan_request_body': 'requested to borrow the book',
      'msg_loan_request_success': 'Borrow request submitted successfully!',
      'notif_booking_success_title': 'Book Booked Successfully',
      'notif_booking_success_body_1': 'Booking queue for',
      'notif_booking_success_body_2': 'is registered. We will notify you when the book is available.',
      'notif_new_booking_request_title': 'New Booking Queue',
      'notif_new_booking_request_body': 'booked the book',
      'msg_booking_success': 'Booking added to the queue successfully!',

      // Peminjaman (Admin)
      'loan_title': 'Loans',
      'loan_tab_request': 'Requests',
      'loan_tab_active': 'Active',
      'loan_tab_history': 'History',
      'loan_tab_manual': 'Manual',
      'loan_no_pending': 'No pending requests',
      'loan_no_active': 'No active loans',
      'loan_no_history': 'No borrowing history',
      'loan_action_approve': 'Approve',
      'loan_action_reject': 'Reject',
      'loan_status_approved': 'Active / Approved',
      'loan_status_returned': 'Returned',
      'loan_status_rejected': 'Rejected',
      'loan_status_pending': 'Pending',
      'loan_select_student': 'Select Student',
      'loan_select_book': 'Select Book',
      'loan_duration_select': 'Borrow Duration',
      'loan_submit_btn': 'Create Loan',
      'loan_confirm_return': 'Return Book',
      'loan_confirm_return_msg': 'Are you sure you want to return this book?',
      'loan_msg_complete': 'Returned Successfully',
      'loan_msg_fill_fields': 'Please fill in all fields',
      'loan_msg_limit_exceeded': 'This student has reached the limit (Max 2 books)',
      'loan_msg_out_of_stock': 'Book out of stock',
      'loan_msg_success': 'Manual Loan Created Successfully',
      'notif_return_title': 'Return Confirmed',
      'notif_return_body': 'Thank you for returning the book',
      'notif_approved_title': 'Borrow Approved',
      'notif_approved_body': 'Your book borrowing request has been approved by admin',
      'notif_rejected_title': 'Borrow Rejected',
      'notif_rejected_body': 'Your book borrowing request was rejected by admin',

      // Report & Dashboard (Admin)
      'report_title': 'Litera Monthly Report',
      'report_subtitle': 'Most popular books, active transactions, & most active students',
      'report_heading': '📊 Monthly Report',
      'report_desc': 'Latest Litera statistics',
      'report_total_loans': 'Total Borrow Transactions',
      'report_times': 'Times',
      'report_popular_books': '📚 Most Borrowed Books',
      'report_no_data': 'No data available',
      'report_times_borrowed': 'x borrowed',
      'report_active_students': '👤 Most Active Students',
      'report_books_borrowed': 'Books',

      // Mahasiswa (Admin)
      'student_action_title': 'Choose action for this student',
      'student_edit': 'Edit Profile',
      'student_delete': 'Delete Account',

      // Buku (Admin)
      'book_edit': 'Edit Book',
      'book_delete': 'Delete Book',

      // Forms
      'form_add_student': 'Add New Student',
      'form_edit_student': 'Edit Student',
      'form_err_nim': 'NIM is required',
      'form_err_name': 'Name is required',
      'form_err_class': 'Class is required',
      'form_err_major': 'Major is required',
      'form_err_age': 'Age is required',
      'form_add_book': 'Add New Book',
      'form_edit_book': 'Edit Book',
      'form_label_book_id': 'Book ID (e.g. BK001)',
      'form_err_id': 'ID is required',
      'form_label_title': 'Book Title',
      'form_err_title': 'Title is required',
      'form_label_writer': 'Author / Writer',
      'form_err_writer': 'Author is required',
      'form_label_category': 'Category (e.g. Fiction, Science)',
      'form_err_category': 'Category is required',
      'form_label_pub_year': 'Publish Year',
      'form_err_required': 'Required',
      'form_label_shelf': 'Shelf Location',
      'form_label_stock': 'Stock Quantity',
      'form_err_stock': 'Stock is required',
      'form_label_nim': 'NIM',
      'form_label_name': 'Full Name',
      'form_label_class': 'Class',
      'form_label_major': 'Major',
      'form_label_age': 'Age',
      'by': 'By',
      'shelf': 'Shelf',
      'year': 'Year',
      'choose': 'Choose',
      'admin_subtitle': 'Litera System Administrator',
      'years_old_abbr': 'y/o',
      'hello': 'Hello',
    }
  };

  static String getString(String key) {
    final lang = langNotifier.value;
    return dict[lang]?[key] ?? key;
  }
}
