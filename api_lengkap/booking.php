<?php
header('Content-Type: application/json');
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $sql = "SELECT * FROM booking";
    $result = $conn->query($sql);
    $bookings = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $bookings[] = [
                'id' => $row['id'],
                'nim' => $row['nim'],
                'bukuId' => $row['buku_id'],
                'judulBuku' => $row['judul_buku'],
                'tanggalBooking' => $row['tanggal_booking'],
                'status' => $row['status']
            ];
        }
    }
    echo json_encode($bookings);
} elseif ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (is_array($data)) {
        // Bulk Sync
        $conn->query("TRUNCATE TABLE booking");
        foreach($data as $item) {
            $id = $conn->real_escape_string($item['id'] ?? uniqid());
            $nim = $conn->real_escape_string($item['nim']);
            $buku_id = $conn->real_escape_string($item['bukuId']);
            $judul = $conn->real_escape_string($item['judulBuku']);
            $tanggal = $conn->real_escape_string($item['tanggalBooking']);
            $status = $conn->real_escape_string($item['status'] ?? 'menunggu');

            $sql = "INSERT INTO booking (id, nim, buku_id, judul_buku, tanggal_booking, status) 
                    VALUES ('$id', '$nim', '$buku_id', '$judul', '$tanggal', '$status')";
            $conn->query($sql);
        }
        echo json_encode(['status' => 'success']);
    } else {
        // Individual insert or status update
        $id = $conn->real_escape_string($data['id']);
        $nim = $conn->real_escape_string($data['nim']);
        $buku_id = $conn->real_escape_string($data['bukuId']);
        $judul = $conn->real_escape_string($data['judulBuku']);
        $tanggal = $conn->real_escape_string($data['tanggalBooking']);
        $status = $conn->real_escape_string($data['status'] ?? 'menunggu');

        $sql = "INSERT INTO booking (id, nim, buku_id, judul_buku, tanggal_booking, status) 
                VALUES ('$id', '$nim', '$buku_id', '$judul', '$tanggal', '$status')
                ON DUPLICATE KEY UPDATE status='$status'";
        
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
    }
}
$conn->close();
?>
