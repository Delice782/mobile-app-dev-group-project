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

$data = getJsonInput();
$data = sanitizeInput($data);

// Validate required fields
$requiredFields = ['userEmail', 'userPassword'];
$errors = validateRequiredFields($data, $requiredFields);

if (!empty($errors)) {
    sendValidationErrorResponse($errors);
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Get user by email
    $query = "SELECT userID, userName, userEmail, userPassword, userContact, userRole, status, 
                     latitude, longitude, address, rating, totalRatings, subscription_status, subscription_expires 
              FROM User 
              WHERE userEmail = :email AND userRole IN ('Waste Collector', 'Admin')";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':email', $data['userEmail']);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        sendErrorResponse('Invalid email or password', 401);
    }
    
    $user = $stmt->fetch();
    
    // Verify password
    if (!password_verify($data['userPassword'], $user['userPassword'])) {
        sendErrorResponse('Invalid email or password', 401);
    }
    
    // Check account status
    if ($user['status'] === 'suspended') {
        sendErrorResponse('Your account has been suspended', 403);
    }
    
    // Check subscription status
    if ($user['subscription_status'] === 'expired') {
        sendErrorResponse('Your subscription has expired. Please renew to continue.', 403);
    }
    
    // Generate token
    $token = generateToken($user['userID'], $user['userRole']);
    
    // Remove sensitive data
    unset($user['userPassword']);
    
    // Format response data
    $userData = [
        'userID' => (int)$user['userID'],
        'userName' => $user['userName'],
        'userEmail' => $user['userEmail'],
        'userContact' => $user['userContact'],
        'userRole' => $user['userRole'],
        'status' => $user['status'],
        'latitude' => $user['latitude'] ? (float)$user['latitude'] : null,
        'longitude' => $user['longitude'] ? (float)$user['longitude'] : null,
        'address' => $user['address'],
        'rating' => $user['rating'] ? (float)$user['rating'] : 0.00,
        'totalRatings' => (int)$user['totalRatings'],
        'subscription_status' => $user['subscription_status'],
        'subscription_expires' => $user['subscription_expires']
    ];
    
    sendSuccessResponse([
        'user' => $userData,
        'token' => $token
    ], 'Login successful');
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
