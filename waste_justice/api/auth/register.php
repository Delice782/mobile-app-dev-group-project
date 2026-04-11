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
$requiredFields = ['userEmail', 'userPassword', 'userContact'];
$errors = validateRequiredFields($data, $requiredFields);

// Accept either userName directly OR firstName + lastName from older/newer clients.
if (empty($data['userName'])) {
    $first = isset($data['firstName']) ? trim($data['firstName']) : '';
    $last = isset($data['lastName']) ? trim($data['lastName']) : '';
    $data['userName'] = trim($first . ' ' . $last);
}

if (empty($data['userName'])) {
    $errors['userName'] = 'User name is required';
}

// Auto-approve all waste collectors
$data['userRole'] = 'Waste Collector';
$data['status'] = 'active';

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
    
    // Insert new waste collector.
    // Supports both schemas:
    // 1) User table with firstName/lastName columns
    // 2) User table with userName only (as in your shared database_schema.sql)
    $hasFirstName = false;
    $hasLastName = false;

    $columnsStmt = $conn->query("SHOW COLUMNS FROM `User`");
    $userColumns = $columnsStmt ? $columnsStmt->fetchAll(PDO::FETCH_COLUMN, 0) : [];
    $hasFirstName = in_array('firstName', $userColumns, true);
    $hasLastName = in_array('lastName', $userColumns, true);

    $insertColumns = ['userName', 'userEmail', 'userPassword', 'userContact', 'userRole', 'status', 'subscription_status'];
    $insertValues = [':userName', ':userEmail', ':userPassword', ':userContact', "'Waste Collector'", "'active'", "'free'"];

    if ($hasFirstName) {
        $insertColumns[] = 'firstName';
        $insertValues[] = ':firstName';
    }
    if ($hasLastName) {
        $insertColumns[] = 'lastName';
        $insertValues[] = ':lastName';
    }

    $insertQuery = "INSERT INTO User (" . implode(', ', $insertColumns) . ")
                    VALUES (" . implode(', ', $insertValues) . ")";

    $stmt = $conn->prepare($insertQuery);
    $stmt->bindValue(':userName', $data['userName']);
    $stmt->bindValue(':userEmail', $data['userEmail']);
    $stmt->bindValue(':userPassword', $hashedPassword);
    $stmt->bindValue(':userContact', $data['userContact']);
    if ($hasFirstName) {
        $stmt->bindValue(':firstName', isset($data['firstName']) ? $data['firstName'] : '');
    }
    if ($hasLastName) {
        $stmt->bindValue(':lastName', isset($data['lastName']) ? $data['lastName'] : '');
    }
    
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
        ], 'Registration successful! You can now login immediately.');
        
    } else {
        sendServerErrorResponse('Registration failed');
    }
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
