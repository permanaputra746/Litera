<?php
header('Content-Type: application/json');
require 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if(isset($data['email']) && isset($data['name'])) {
    $email = $conn->real_escape_string($data['email']);
    $name = $conn->real_escape_string($data['name']);
    $role = isset($data['role']) ? $conn->real_escape_string($data['role']) : 'admin';

    if ($role === 'siswa') {
        $check = "SELECT * FROM mahasiswa WHERE email = '$email' OR nim = '$email'";
        $res = $conn->query($check);

        if ($res && $res->num_rows > 0) {
            $row = $res->fetch_assoc();
            echo json_encode([
                'status' => 'success',
                'message' => 'Login Google Mahasiswa berhasil',
                'user' => [
                    'nim' => $row['nim'],
                    'nama' => $row['nama']
                ]
            ]);
        } else {
            echo json_encode([
                'status' => 'new_user',
                'message' => 'Silakan lengkapi profil Anda.',
                'email' => $email,
                'name' => $name
            ]);
        }
    } else {
        // Default: Admin
        $check = "SELECT * FROM users WHERE username = '$email' OR email = '$email'";
        $res = $conn->query($check);

        if ($res && $res->num_rows > 0) {
            $row = $res->fetch_assoc();
            // User exists, allow login
            echo json_encode([
                'status' => 'success',
                'message' => 'Login Google Admin berhasil',
                'user' => [
                    'username' => $row['username'],
                    'name' => $row['username']
                ]
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'Email Anda tidak terdaftar sebagai Admin perpustakaan.'
            ]);
        }
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
}
$conn->close();
?>

