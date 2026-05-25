<?php
header('Content-Type: application/json');
require 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

if(isset($data['username']) && isset($data['password'])) {
    $user = $conn->real_escape_string($data['username']);
    $pass = $data['password'];

    $sql = "SELECT * FROM users WHERE username = '$user'";
    $res = $conn->query($sql);

    if ($res->num_rows > 0) {
        $row = $res->fetch_assoc();
        if (password_verify($pass, $row['password'])) {
            echo json_encode(['status' => 'success', 'message' => 'Login berhasil', 'user' => ['username' => $row['username']]]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Password salah']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Username tidak ditemukan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
}
$conn->close();
?>
