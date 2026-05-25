<?php
header('Content-Type: application/json');
require 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if(isset($data['username']) && isset($data['password'])) {
    $user = $conn->real_escape_string($data['username']);
    $pass = $data['password'];

    $check = "SELECT * FROM users WHERE username = '$user'";
    $res = $conn->query($check);

    if ($res->num_rows > 0) {
        echo json_encode(['status' => 'error', 'message' => 'Username sudah digunakan']);
    } else {
        $hashed = password_hash($pass, PASSWORD_DEFAULT);
        $sql = "INSERT INTO users (username, password) VALUES ('$user', '$hashed')";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success', 'message' => 'Registrasi berhasil']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Gagal insert db']);
        }
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
}
$conn->close();
?>
