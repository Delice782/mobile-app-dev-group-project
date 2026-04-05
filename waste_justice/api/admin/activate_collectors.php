<?php
/**
 * Admin endpoint to activate all waste collectors
 */

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

// Simple admin password protection (change this to your secure admin password)
$adminPassword = $_POST['admin_password'] ?? '';
if ($adminPassword !== 'admin123') {
    sendErrorResponse("Invalid admin password", 401);
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Update all waste collectors from pending to active
    $updateQuery = "UPDATE User SET status = 'active' 
                   WHERE userRole = 'Waste Collector' AND status = 'pending'";
    
    $stmt = $conn->prepare($updateQuery);
    
    if ($stmt->execute()) {
        $affectedRows = $stmt->rowCount();
        
        sendSuccessResponse([
            'message' => "Successfully activated $affectedRows waste collectors",
            'affected_collectors' => $affectedRows
        ]);
    } else {
        sendServerErrorResponse('Failed to update collector statuses');
    }
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
