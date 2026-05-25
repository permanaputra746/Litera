<?php
header('Content-Type: application/json');
require 'config.php';

$action = isset($_GET['action']) ? $_GET['action'] : '';
$method = $_SERVER['REQUEST_METHOD'];

if ($action === 'login' && $method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (isset($data['nim']) && isset($data['password'])) {
        $nim = $conn->real_escape_string($data['nim']);
        $pass = $data['password'];

        $sql = "SELECT * FROM mahasiswa WHERE nim = '$nim'";
        $res = $conn->query($sql);

        if ($res && $res->num_rows > 0) {
            $row = $res->fetch_assoc();
            // Since the database might have a mix of plain passwords or hashed passwords, we check both
            if ($pass === $row['password'] || password_verify($pass, $row['password'])) {
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Login berhasil',
                    'mahasiswa' => [
                        'nim' => $row['nim'],
                        'nama' => $row['nama'],
                        'kelas' => $row['kelas'],
                        'jurusan' => $row['jurusan'],
                        'umur' => (int)$row['umur']
                    ]
                ]);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Password salah']);
            }
        } else {
            echo json_encode(['status' => 'error', 'message' => 'NIM tidak terdaftar']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    }
} elseif ($action === 'register' && $method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (isset($data['nim']) && isset($data['nama']) && isset($data['password'])) {
        $nim = $conn->real_escape_string($data['nim']);
        $nama = $conn->real_escape_string($data['nama']);
        $kelas = $conn->real_escape_string($data['kelas'] ?? '-');
        $jurusan = $conn->real_escape_string($data['jurusan'] ?? '-');
        $umur = (int)($data['umur'] ?? 0);
        $email = $conn->real_escape_string($data['email'] ?? '');
        $pass = $conn->real_escape_string($data['password']);

        // Check if NIM already exists
        $check = "SELECT * FROM mahasiswa WHERE nim = '$nim'";
        $res = $conn->query($check);

        if ($res && $res->num_rows > 0) {
            echo json_encode(['status' => 'error', 'message' => 'NIM sudah terdaftar']);
        } else {
            $sql = "INSERT INTO mahasiswa (nim, nama, kelas, jurusan, umur, email, password) 
                    VALUES ('$nim', '$nama', '$kelas', '$jurusan', $umur, '$email', '$pass')";
            if ($conn->query($sql) === TRUE) {
                echo json_encode(['status' => 'success', 'message' => 'Registrasi mahasiswa berhasil']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan ke database']);
            }
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    }
} else {
    // Normal CRUD/Sync Operations
    if ($method === 'GET') {
        $sql = "SELECT * FROM mahasiswa";
        $result = $conn->query($sql);
        $mhs = [];
        if ($result && $result->num_rows > 0) {
            while($row = $result->fetch_assoc()) {
                $mhs[] = [
                    'nim' => $row['nim'],
                    'nama' => $row['nama'],
                    'kelas' => $row['kelas'],
                    'jurusan' => $row['jurusan'],
                    'umur' => (int)$row['umur']
                ];
            }
        }
        echo json_encode($mhs);
    } elseif ($method === 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        if (is_array($data)) {
            $conn->query("TRUNCATE TABLE mahasiswa");
            foreach($data as $item) {
                $nim = $conn->real_escape_string($item['nim']);
                $nama = $conn->real_escape_string($item['nama']);
                $kelas = $conn->real_escape_string($item['kelas'] ?? '-');
                $jurusan = $conn->real_escape_string($item['jurusan'] ?? '-');
                $umur = (int)($item['umur'] ?? 0);
                
                $sql = "INSERT INTO mahasiswa (nim, nama, kelas, jurusan, umur) VALUES ('$nim', '$nama', '$kelas', '$jurusan', $umur)";
                $conn->query($sql);
            }
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Invalid data']);
        }
    }
}
$conn->close();
?>
