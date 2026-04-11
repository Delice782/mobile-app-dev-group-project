<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';
require_once '../config/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse("Method not allowed", 405);
}

try {
    $currentUser = requireAuth();

    if ($currentUser['user_role'] !== 'Waste Collector') {
        sendUnauthorizedResponse('Only waste collectors can upload collection photos');
    }

    if (!isset($_FILES['photo']) || !is_uploaded_file($_FILES['photo']['tmp_name'])) {
        sendErrorResponse('No photo uploaded', 400);
    }

    if ($_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
        sendErrorResponse('Upload failed (error code ' . (int) $_FILES['photo']['error'] . ')', 400);
    }

    $maxBytes = 5 * 1024 * 1024;
    if ($_FILES['photo']['size'] > $maxBytes) {
        sendErrorResponse('Photo must be 5MB or smaller', 400);
    }

    $ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!in_array($ext, $allowed, true)) {
        sendErrorResponse('Allowed types: JPG, PNG, WEBP', 400);
    }

    $uploadBase = realpath(__DIR__ . '/..');
    if ($uploadBase === false) {
        sendServerErrorResponse('Upload directory not available');
    }

    $dir = $uploadBase . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'collections';
    if (!is_dir($dir)) {
        if (!@mkdir($dir, 0755, true)) {
            sendServerErrorResponse('Could not create upload directory');
        }
    }

    $safe = 'col_' . (int) $currentUser['user_id'] . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $dest = $dir . DIRECTORY_SEPARATOR . $safe;

    if (!move_uploaded_file($_FILES['photo']['tmp_name'], $dest)) {
        sendServerErrorResponse('Could not save file');
    }

    $relative = 'uploads/collections/' . $safe;
    if (strlen($relative) > 255) {
        @unlink($dest);
        sendErrorResponse('Generated path too long', 500);
    }

    sendSuccessResponse(['photoPath' => $relative], 'Photo uploaded');
} catch (Throwable $e) {
    sendServerErrorResponse('Upload error: ' . $e->getMessage());
}
