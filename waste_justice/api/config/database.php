<?php
/**
 * WasteJustice Configuration
 */

// Define base directory.
if (!defined('BASE_DIR')) {
    define('BASE_DIR', dirname(dirname(__FILE__)));
}

// Define URL base.
// If deployed directly in public_html root, set to ''.
// If deployed under public_html/WasteJustice, set to '/WasteJustice'.
if (!defined('BASE_URL')) {
    define('BASE_URL', '/WasteJustice');
}

// Define URL paths.
if (!defined('ASSETS_URL')) define('ASSETS_URL', BASE_URL . '/assets');
if (!defined('VIEWS_URL')) define('VIEWS_URL', BASE_URL . '/views');
if (!defined('ACTIONS_URL')) define('ACTIONS_URL', BASE_URL . '/actions');
if (!defined('API_URL')) define('API_URL', BASE_URL . '/api');
if (!defined('PAGES_URL')) define('PAGES_URL', BASE_URL . '/pages');
if (!defined('JS_URL')) define('JS_URL', BASE_URL . '/js');

// App metadata.
if (!defined('APP_NAME')) define('APP_NAME', 'WasteJustice');
if (!defined('APP_TAGLINE')) define('APP_TAGLINE', 'Fair, Transparent Waste Management in Ghana');

class Database {
    private $host = 'localhost';
    private $db_name = 'u628771162_nd';
    private $username = 'u628771162_nda';
    private $password = 'Ndala1950@@';
    private $charset = 'utf8mb4';

    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $dsn = "mysql:host={$this->host};dbname={$this->db_name};charset={$this->charset}";
            $this->conn = new PDO($dsn, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            $this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        } catch (PDOException $exception) {
            echo 'Connection error: ' . $exception->getMessage();
        }

        return $this->conn;
    }

    public function testConnection() {
        try {
            $conn = $this->getConnection();
            if ($conn) {
                return ['status' => 'success', 'message' => 'Database connected successfully'];
            }
        } catch (PDOException $exception) {
            return ['status' => 'error', 'message' => $exception->getMessage()];
        }

        return ['status' => 'error', 'message' => 'Database connection failed'];
    }
}

// Session management.
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
