<?php
header('Content-Type: application/json');
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $sql = "SELECT * FROM peminjaman";
    $result = $conn->query($sql);
    $pem = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $pem[] = [
                'id' => $row['id'],
                'nim' => $row['nim'],
                'bukuId' => $row['buku_id'],
                'judulBuku' => $row['judul_buku'],
                'tanggal' => $row['tanggal_pinjam'],
                'durasiHari' => (int)$row['durasi_hari'],
                'tanggalKembali' => $row['tanggal_kembali'] ?? '',
                'status' => $row['status'],
                'denda' => (double)$row['denda']
            ];
        }
    }
    echo json_encode($pem);
} elseif ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (is_array($data)) {
        // Bulk Sync
        $conn->query("TRUNCATE TABLE peminjaman");
        foreach($data as $item) {
            $id = $conn->real_escape_string($item['id'] ?? uniqid());
            $nim = $conn->real_escape_string($item['nim']);
            $buku_id = $conn->real_escape_string($item['bukuId'] ?? '');
            $judul = $conn->real_escape_string($item['judulBuku']);
            $tanggal = $conn->real_escape_string($item['tanggal']);
            $durasi = isset($item['durasiHari']) ? (int)$item['durasiHari'] : 7;
            $tgl_kembali = isset($item['tanggalKembali']) && $item['tanggalKembali'] !== '' ? "'".$conn->real_escape_string($item['tanggalKembali'])."'" : "NULL";
            $status = $conn->real_escape_string($item['status'] ?? 'diproses');
            $denda = (double)($item['denda'] ?? 0.0);

            $sql = "INSERT INTO peminjaman (id, nim, buku_id, judul_buku, tanggal_pinjam, durasi_hari, tanggal_kembali, status, denda) 
                    VALUES ('$id', '$nim', '$buku_id', '$judul', '$tanggal', $durasi, $tgl_kembali, '$status', $denda)";
            $conn->query($sql);
        }
        echo json_encode(['status' => 'success']);
    } else {
        // Individual insert or status update
        $id = $conn->real_escape_string($data['id']);
        $nim = $conn->real_escape_string($data['nim']);
        $buku_id = $conn->real_escape_string($data['bukuId'] ?? '');
        $judul = $conn->real_escape_string($data['judulBuku']);
        $tanggal = $conn->real_escape_string($data['tanggal']);
        $durasi = isset($data['durasiHari']) ? (int)$data['durasiHari'] : 7;
        $tgl_kembali = isset($data['tanggalKembali']) && $data['tanggalKembali'] !== '' ? "'".$conn->real_escape_string($data['tanggalKembali'])."'" : "NULL";
        $status = $conn->real_escape_string($data['status'] ?? 'diproses');
        $denda = (double)($data['denda'] ?? 0.0);

        $sql = "INSERT INTO peminjaman (id, nim, buku_id, judul_buku, tanggal_pinjam, durasi_hari, tanggal_kembali, status, denda) 
                VALUES ('$id', '$nim', '$buku_id', '$judul', '$tanggal', $durasi, $tgl_kembali, '$status', $denda)
                ON DUPLICATE KEY UPDATE 
                status='$status', tanggal_kembali=$tgl_kembali, denda=$denda";
        
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
    }
}
$conn->close();
?>
