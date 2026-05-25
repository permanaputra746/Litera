<?php
header('Content-Type: application/json');
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $sql = "SELECT * FROM buku";
    $result = $conn->query($sql);
    $buku = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $buku[] = [
                'id' => $row['buku_id'],
                'judul' => $row['judul'],
                'penulis' => $row['penulis'],
                'kategori' => $row['kategori'],
                'tahunTerbit' => $row['tahun_terbit'],
                'lokasiRak' => $row['lokasi_rak'],
                'cover' => $row['cover'],
                'stok' => (int)$row['stok']
            ];
        }
    }
    echo json_encode($buku);
} elseif ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (is_array($data)) {
        // Clear all and write back bulk (fallback support)
        $conn->query("TRUNCATE TABLE buku");
        foreach($data as $item) {
            $id = $conn->real_escape_string($item['id']);
            $judul = $conn->real_escape_string($item['judul']);
            $penulis = $conn->real_escape_string($item['penulis'] ?? $item['penerbit'] ?? 'Anonim');
            $kategori = $conn->real_escape_string($item['kategori'] ?? 'Umum');
            $tahun = $conn->real_escape_string($item['tahunTerbit'] ?? '2024');
            $rak = $conn->real_escape_string($item['lokasiRak'] ?? 'Rak A-1');
            $cover = $conn->real_escape_string($item['cover'] ?? '');
            $stok = (int)$item['stok'];
            
            $sql = "INSERT INTO buku (buku_id, judul, penulis, kategori, tahun_terbit, lokasi_rak, cover, stok) 
                    VALUES ('$id', '$judul', '$penulis', '$kategori', '$tahun', '$rak', '$cover', $stok)";
            $conn->query($sql);
        }
        echo json_encode(['status' => 'success']);
    } else {
        // Individual single insert/update
        $id = $conn->real_escape_string($data['id']);
        $judul = $conn->real_escape_string($data['judul']);
        $penulis = $conn->real_escape_string($data['penulis']);
        $kategori = $conn->real_escape_string($data['kategori']);
        $tahun = $conn->real_escape_string($data['tahunTerbit']);
        $rak = $conn->real_escape_string($data['lokasiRak']);
        $cover = $conn->real_escape_string($data['cover'] ?? '');
        $stok = (int)$data['stok'];

        $sql = "INSERT INTO buku (buku_id, judul, penulis, kategori, tahun_terbit, lokasi_rak, cover, stok) 
                VALUES ('$id', '$judul', '$penulis', '$kategori', '$tahun', '$rak', '$cover', $stok)
                ON DUPLICATE KEY UPDATE 
                judul='$judul', penulis='$penulis', kategori='$kategori', tahun_terbit='$tahun', lokasi_rak='$rak', cover='$cover', stok=$stok";
        
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
    }
} elseif ($method === 'DELETE') {
    // Single delete by ID
    $id = isset($_GET['id']) ? $conn->real_escape_string($_GET['id']) : '';
    if ($id) {
        $sql = "DELETE FROM buku WHERE buku_id = '$id'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'No ID provided']);
    }
}
$conn->close();
?>
