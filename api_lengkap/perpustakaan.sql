-- SQL Initialization Script for Digital Library Database (Perpustakaan)
-- You can run this in phpMyAdmin or MySQL console to set up or reset your database.

CREATE DATABASE IF NOT EXISTS `perpustakaan`;
USE `perpustakaan`;

-- 1. Table: users (for Admin login credentials)
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Table: buku (digital catalog)
CREATE TABLE IF NOT EXISTS `buku` (
  `buku_id` varchar(50) NOT NULL,
  `judul` varchar(255) NOT NULL,
  `penulis` varchar(255) NOT NULL DEFAULT 'Anonim',
  `kategori` varchar(100) NOT NULL DEFAULT 'Umum',
  `tahun_terbit` varchar(10) NOT NULL DEFAULT '2024',
  `lokasi_rak` varchar(100) NOT NULL DEFAULT 'Rak A-1',
  `cover` varchar(255) DEFAULT '',
  `stok` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`buku_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Table: mahasiswa (students)
CREATE TABLE IF NOT EXISTS `mahasiswa` (
  `nim` varchar(50) NOT NULL,
  `nama` varchar(255) NOT NULL,
  `kelas` varchar(50) NOT NULL DEFAULT '-',
  `jurusan` varchar(100) NOT NULL DEFAULT '-',
  `umur` int(11) NOT NULL DEFAULT 0,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) NOT NULL DEFAULT '123456', -- Default password
  PRIMARY KEY (`nim`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Table: peminjaman (loan transactions)
CREATE TABLE IF NOT EXISTS `peminjaman` (
  `id` varchar(50) NOT NULL,
  `nim` varchar(50) NOT NULL,
  `buku_id` varchar(50) NOT NULL,
  `judul_buku` varchar(255) NOT NULL,
  `tanggal_pinjam` date NOT NULL,
  `durasi_hari` int(11) NOT NULL DEFAULT 7,
  `tanggal_kembali` date DEFAULT NULL,
  `status` enum('diproses','disetujui','ditolak','dikembalikan') NOT NULL DEFAULT 'diproses',
  `denda` double(15,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`nim`) REFERENCES `mahasiswa` (`nim`) ON DELETE CASCADE,
  FOREIGN KEY (`buku_id`) REFERENCES `buku` (`buku_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Table: booking (queue reservations)
CREATE TABLE IF NOT EXISTS `booking` (
  `id` varchar(50) NOT NULL,
  `nim` varchar(50) NOT NULL,
  `buku_id` varchar(50) NOT NULL,
  `judul_buku` varchar(255) NOT NULL,
  `tanggal_booking` date NOT NULL,
  `status` enum('menunggu','siap','selesai') NOT NULL DEFAULT 'menunggu',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`nim`) REFERENCES `mahasiswa` (`nim`) ON DELETE CASCADE,
  FOREIGN KEY (`buku_id`) REFERENCES `buku` (`buku_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Table: notifikasi (real-time notification history)
CREATE TABLE IF NOT EXISTS `notifikasi` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(100) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --- SEED DEFAULT DATA ---
-- Insert default admin: user: admin@perpustakaan.com / pwd: password (hashed)
INSERT INTO `users` (`username`, `password`, `email`)
VALUES ('Admin Perpustakaan', '$2y$10$oX3hTf4dZtPZcskp1m2eie33Z2X7n5jFfe8H7z.t1g8y7.N2lVvIe', 'admin@perpustakaan.com')
ON DUPLICATE KEY UPDATE `username`=`username`;

-- Insert default students (password defaults to '123456')
INSERT INTO `mahasiswa` (`nim`, `nama`, `kelas`, `jurusan`, `umur`, `email`, `password`)
VALUES 
('09030015', 'Joko', '5A', 'Teknik Informatika', 20, 'joko@siswa.com', '123456'),
('09030016', 'Udin', '5B', 'Sistem Informasi', 21, 'udin@siswa.com', '123456'),
('09030017', 'Siti', '5C', 'Teknik Komputer', 20, 'siti@siswa.com', '123456')
ON DUPLICATE KEY UPDATE `nim`=`nim`;

-- Insert default books
INSERT INTO `buku` (`buku_id`, `judul`, `penulis`, `kategori`, `tahun_terbit`, `lokasi_rak`, `cover`, `stok`)
VALUES 
('BK001', 'Belajar Dart', 'Informatika', 'Pemrograman', '2022', 'Rak A-1', '', 4),
('BK002', 'Belajar Flutter', 'Andi Publisher', 'Mobile Dev', '2023', 'Rak B-2', '', 5),
('BK003', 'Pemrograman Dasar', 'Gramedia', 'Dasar', '2021', 'Rak C-1', '', 3)
ON DUPLICATE KEY UPDATE `buku_id`=`buku_id`;
