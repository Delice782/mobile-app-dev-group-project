<?php
/**
 * Quick script to activate Steve's account
 */

// Database configuration
$host = "localhost";
$user = "root";
$pass = "Nsabimana2@";
$db = "mobileapps_2026B_steve_nsabimana";

try {
    // Create database connection
    $conn = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Database connected successfully!\n";
    
    // Update Steve's account status
    $email = "steve.test@ashesi.edu.gh";
    $sql = "UPDATE User SET status = 'active' WHERE userEmail = :email";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':email', $email);
    
    if ($stmt->execute()) {
        $rowCount = $stmt->rowCount();
        if ($rowCount > 0) {
            echo "✅ Account activated successfully for: $email\n";
            
            // Verify the update
            $verifySql = "SELECT userName, userEmail, status FROM User WHERE userEmail = :email";
            $verifyStmt = $conn->prepare($verifySql);
            $verifyStmt->bindParam(':email', $email);
            $verifyStmt->execute();
            $user = $verifyStmt->fetch(PDO::FETCH_ASSOC);
            
            echo "📋 User Details:\n";
            echo "   Name: " . $user['userName'] . "\n";
            echo "   Email: " . $user['userEmail'] . "\n";
            echo "   Status: " . $user['status'] . "\n";
            
        } else {
            echo "❌ No user found with email: $email\n";
        }
    } else {
        echo "❌ Failed to update account\n";
    }
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
    echo "Trying alternative connection...\n";
    
    // Try without password
    try {
        $conn = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, "");
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        echo "Connected without password!\n";
        
        $email = "steve.test@ashesi.edu.gh";
        $sql = "UPDATE User SET status = 'active' WHERE userEmail = :email";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':email', $email);
        
        if ($stmt->execute()) {
            echo "✅ Account activated successfully for: $email\n";
        }
        
    } catch (PDOException $e2) {
        echo "❌ Alternative connection also failed: " . $e2->getMessage() . "\n";
    }
}

echo "\n🧪 Now try to login with:\n";
echo "Email: steve.test@ashesi.edu.gh\n";
echo "Password: TestPassword123\n";
?>
