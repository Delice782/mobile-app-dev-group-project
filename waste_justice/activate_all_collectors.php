<?php
/**
 * Quick script to activate all waste collectors
 */

require_once 'api/config/database.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    echo "Connecting to database...\n";
    
    // Update all waste collectors from pending to active
    $updateSql = "UPDATE User SET status = 'active' WHERE userRole = 'Waste Collector' AND status = 'pending'";
    $stmt = $conn->prepare($updateSql);
    
    if ($stmt->execute()) {
        $affectedRows = $stmt->rowCount();
        echo "✅ Successfully activated $affectedRows waste collectors!\n";
        
        // Verify the update
        $checkSql = "SELECT COUNT(*) as total FROM User WHERE userRole = 'Waste Collector' AND status = 'active'";
        $checkStmt = $conn->prepare($checkSql);
        $checkStmt->execute();
        $result = $checkStmt->fetch();
        
        echo "📊 Total active waste collectors: " . $result['total'] . "\n";
        
        // Show sample of updated users
        $sampleSql = "SELECT userName, userEmail, status FROM User WHERE userRole = 'Waste Collector' ORDER BY userID DESC LIMIT 5";
        $sampleStmt = $conn->prepare($sampleSql);
        $sampleStmt->execute();
        
        echo "\n📋 Recent waste collectors:\n";
        while ($user = $sampleStmt->fetch()) {
            echo "   - " . $user['userName'] . " (" . $user['userEmail'] . ") - Status: " . $user['status'] . "\n";
        }
        
    } else {
        echo "❌ Failed to update waste collectors\n";
    }
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
}

echo "\n🎉 All waste collectors can now login immediately!\n";
?>
