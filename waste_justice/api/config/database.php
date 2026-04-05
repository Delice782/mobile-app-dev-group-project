<?php
/**
 * Database Configuration for WasteJustice API
 * Connects to MySQL database for waste collection management
 */

class Database {
    private $host = 'localhost';
    private $db_name = 'wastejustice';
    private $username = 'root';
    private $password = 'Nsabimana2@';
    private $charset = 'mobileapps_2026B_steve_nsabimana';
    
    public $conn;
    
    public function getConnection() {
        $this->conn = null;
        
        try {
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset;
            $this->conn = new PDO($dsn, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            $this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        } catch(PDOException $exception) {
            echo "Connection error: " . $exception->getMessage();
        }
        
        return $this->conn;
    }
    
    // Test database connection
    public function testConnection() {
        try {
            $conn = $this->getConnection();
            if ($conn) {
                return ["status" => "success", "message" => "Database connected successfully"];
            }
        } catch(PDOException $exception) {
            return ["status" => "error", "message" => $exception->getMessage()];
        }
    }
}
?>
