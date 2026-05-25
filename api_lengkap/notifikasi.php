<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Content-Type: application/json');

require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    exit(0);
}

if ($method === 'GET') {
    // Fetch notifications for a user (or admin, or all)
    $user_id = isset($_GET['user_id']) ? $conn->real_escape_string($_GET['user_id']) : '';

    if ($user_id) {
        // Fetch specific user notifications, admin notifications, or global 'all' notifications
        $sql = "SELECT * FROM notifikasi 
                WHERE user_id = '$user_id' OR user_id = 'all' 
                ORDER BY created_at DESC LIMIT 50";
        $result = $conn->query($sql);
        
        $notifications = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $notifications[] = [
                    'id' => (int)$row['id'],
                    'user_id' => $row['user_id'],
                    'title' => $row['title'],
                    'body' => $row['body'],
                    'created_at' => $row['created_at'],
                    'is_read' => (int)$row['is_read']
                ];
            }
        }
        echo json_encode($notifications);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Parameter user_id diperlukan']);
    }

} elseif ($method === 'POST') {
    // Insert new notification
    $data = json_decode(file_get_contents('php://input'), true);

    if (isset($data['user_id']) && isset($data['title']) && isset($data['body'])) {
        $user_id = $conn->real_escape_string($data['user_id']);
        $title = $conn->real_escape_string($data['title']);
        $body = $conn->real_escape_string($data['body']);

        $sql = "INSERT INTO notifikasi (user_id, title, body) VALUES ('$user_id', '$title', '$body')";
        
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success', 'message' => 'Notifikasi berhasil ditambahkan', 'id' => $conn->insert_id]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan notifikasi: ' . $conn->error]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    }

} elseif ($method === 'PUT') {
    // Mark notifications as read
    $data = json_decode(file_get_contents('php://input'), true);
    $user_id = isset($data['user_id']) ? $conn->real_escape_string($data['user_id']) : '';

    if ($user_id) {
        $sql = "UPDATE notifikasi SET is_read = 1 WHERE user_id = '$user_id' OR user_id = 'all'";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['status' => 'success', 'message' => 'Notifikasi ditandai telah dibaca']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Gagal mengubah status: ' . $conn->error]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Parameter user_id diperlukan']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode HTTP tidak didukung']);
}

$conn->close();
?>
