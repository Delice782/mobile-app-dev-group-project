<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';
require_once '../config/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendErrorResponse("Method not allowed", 405);
}

// Require authentication
$currentUser = requireAuth();

$data = getJsonInput();
$data = sanitizeInput($data);

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Build update query dynamically based on provided fields
    $updateFields = [];
    $params = [':userID' => $currentUser['user_id']];
    
    // Allowed fields for update
    $allowedFields = [
        'userName' => 'userName',
        'userContact' => 'userContact',
        'address' => 'address',
        'latitude' => 'latitude',
        'longitude' => 'longitude'
    ];
    
    foreach ($allowedFields as $field => $dbField) {
        if (isset($data[$field]) && !empty(trim($data[$field]))) {
            // Validate specific fields
            if ($field === 'userContact') {
                if (!preg_match('/^\+233\d{9}$/', $data[$field])) {
                    sendValidationErrorResponse([$field => 'Invalid Ghana phone number format (+233XXXXXXXXX)']);
                }
            }
            
            if ($field === 'latitude') {
                if (!is_numeric($data[$field]) || $data[$field] < -90 || $data[$field] > 90) {
                    sendValidationErrorResponse([$field => 'Invalid latitude']);
                }
            }
            
            if ($field === 'longitude') {
                if (!is_numeric($data[$field]) || $data[$field] < -180 || $data[$field] > 180) {
                    sendValidationErrorResponse([$field => 'Invalid longitude']);
                }
            }
            
            $updateFields[] = "$dbField = :$field";
            $params[":$field"] = $data[$field];
        }
    }
    
    if (empty($updateFields)) {
        sendValidationErrorResponse(['general' => 'No valid fields provided for update']);
    }
    
    // Check if email is being updated and validate uniqueness
    if (isset($data['userEmail']) && !empty(trim($data['userEmail']))) {
        if (!filter_var($data['userEmail'], FILTER_VALIDATE_EMAIL)) {
            sendValidationErrorResponse(['userEmail' => 'Invalid email format']);
        }
        
        // Check if email already exists for another user
        $checkEmailQuery = "SELECT userID FROM User WHERE userEmail = :email AND userID != :userID";
        $stmt = $conn->prepare($checkEmailQuery);
        $stmt->bindParam(':email', $data['userEmail']);
        $stmt->bindParam(':userID', $currentUser['user_id']);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            sendErrorResponse('Email already exists', 409);
        }
        
        $updateFields[] = "userEmail = :userEmail";
        $params[':userEmail'] = $data['userEmail'];
    }
    
    // Check if password is being updated
    if (isset($data['userPassword']) && !empty(trim($data['userPassword']))) {
        if (strlen($data['userPassword']) < 6) {
            sendValidationErrorResponse(['userPassword' => 'Password must be at least 6 characters long']);
        }
        
        $hashedPassword = password_hash($data['userPassword'], PASSWORD_DEFAULT);
        $updateFields[] = "userPassword = :userPassword";
        $params[':userPassword'] = $hashedPassword;
    }
    
    // Build the final query
    $updateQuery = "UPDATE User SET " . implode(', ', $updateFields) . " WHERE userID = :userID";
    
    $stmt = $conn->prepare($updateQuery);
    
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    
    if ($stmt->execute()) {
        // Get updated user data
        $getUserQuery = "SELECT userID, userName, userEmail, userContact, userRole, status, 
                                latitude, longitude, address, rating, totalRatings, 
                                subscription_status, subscription_expires, createdAt
                         FROM User WHERE userID = :userID";
        
        $stmt = $conn->prepare($getUserQuery);
        $stmt->bindParam(':userID', $currentUser['user_id']);
        $stmt->execute();
        
        $updatedUser = $stmt->fetch();
        
        // Format response data
        $userData = [
            'userID' => (int)$updatedUser['userID'],
            'userName' => $updatedUser['userName'],
            'userEmail' => $updatedUser['userEmail'],
            'userContact' => $updatedUser['userContact'],
            'userRole' => $updatedUser['userRole'],
            'status' => $updatedUser['status'],
            'latitude' => $updatedUser['latitude'] ? (float)$updatedUser['latitude'] : null,
            'longitude' => $updatedUser['longitude'] ? (float)$updatedUser['longitude'] : null,
            'address' => $updatedUser['address'],
            'rating' => $updatedUser['rating'] ? (float)$updatedUser['rating'] : 0.00,
            'totalRatings' => (int)$updatedUser['totalRatings'],
            'subscription_status' => $updatedUser['subscription_status'],
            'subscription_expires' => $updatedUser['subscription_expires'],
            'createdAt' => $updatedUser['createdAt']
        ];
        
        sendSuccessResponse([
            'user' => $userData
        ], 'Profile updated successfully');
        
    } else {
        sendServerErrorResponse('Failed to update profile');
    }
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
