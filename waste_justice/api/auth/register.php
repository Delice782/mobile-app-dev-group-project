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
$requiredFields = ['firstName', 'lastName', 'userName', 'userEmail', 'userPassword', 'userContact'];
$errors = validateRequiredFields($data, $requiredFields);

if (!empty($errors)) {
    sendValidationErrorResponse($errors);
}

// Validate email format
if (!filter_var($data['userEmail'], FILTER_VALIDATE_EMAIL)) {
    sendValidationErrorResponse(['userEmail' => 'Invalid email format']);
}

// Validate password length
if (strlen($data['userPassword']) < 6) {
    sendValidationErrorResponse(['userPassword' => 'Password must be at least 6 characters long']);
}

// Validate phone number (Ghana format)
if (!preg_match('/^\+233\d{9}$/', $data['userContact'])) {
    sendValidationErrorResponse(['userContact' => 'Invalid Ghana phone number format (+233XXXXXXXXX)']);
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Check if email already exists
    $checkEmailQuery = "SELECT userID FROM User WHERE userEmail = :email";
    $stmt = $conn->prepare($checkEmailQuery);
    $stmt->bindParam(':email', $data['userEmail']);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        sendErrorResponse('Email already exists', 409);
    }
    
    // Check if phone number already exists
    $checkPhoneQuery = "SELECT userID FROM User WHERE userContact = :contact";
    $stmt = $conn->prepare($checkPhoneQuery);
    $stmt->bindParam(':contact', $data['userContact']);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        sendErrorResponse('Phone number already exists', 409);
    }
    
    // Hash password
    $hashedPassword = password_hash($data['userPassword'], PASSWORD_DEFAULT);
    
    // Insert new waste collector
    $insertQuery = "INSERT INTO User (firstName, lastName, userName, userEmail, userPassword, userContact, userRole, status, subscription_status) 
                    VALUES (:firstName, :lastName, :userName, :userEmail, :userPassword, :userContact, 'Waste Collector', 'pending', 'free')";
    
    $stmt = $conn->prepare($insertQuery);
    $stmt->bindParam(':firstName', $data['firstName']);
    $stmt->bindParam(':lastName', $data['lastName']);
    $stmt->bindParam(':userName', $data['userName']);
    $stmt->bindParam(':userEmail', $data['userEmail']);
    $stmt->bindParam(':userPassword', $hashedPassword);
    $stmt->bindParam(':userContact', $data['userContact']);
    
    if ($stmt->execute()) {
        $userId = $conn->lastInsertId();
        
        // Get user details for response
        $getUserQuery = "SELECT userID, userName, userEmail, userContact, userRole, status, subscription_status, createdAt 
                        FROM User WHERE userID = :userId";
        $stmt = $conn->prepare($getUserQuery);
        $stmt->bindParam(':userId', $userId);
        $stmt->execute();
        
        $user = $stmt->fetch();
        
        // Generate token
        $token = generateToken($user['userID'], $user['userRole']);
        
        // Remove sensitive data
        unset($user['userPassword']);
        
        sendSuccessResponse([
            'user' => $user,
            'token' => $token
        ], 'Registration successful. Your account is pending approval.');
        
    } else {
        sendServerErrorResponse('Registration failed');
    }
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
