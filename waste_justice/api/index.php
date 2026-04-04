<?php
/**
 * WasteJustice API Index
 * Entry point for API requests and health check
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config/database.php';
require_once 'config/response.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Test database connection
        $database = new Database();
        $connectionTest = $database->testConnection();
        
        if ($connectionTest['status'] === 'success') {
            sendSuccessResponse([
                'api' => 'WasteJustice API',
                'version' => '1.0.0',
                'status' => 'running',
                'database' => 'connected',
                'timestamp' => date('Y-m-d H:i:s'),
                'endpoints' => [
                    'Authentication' => [
                        'POST /auth/register.php' => 'Register new waste collector',
                        'POST /auth/login.php' => 'User login'
                    ],
                    'Waste Collection' => [
                        'POST /waste/submit_collection.php' => 'Submit waste collection',
                        'GET /waste/get_collections.php' => 'Get user collections'
                    ],
                    'Aggregators' => [
                        'GET /aggregators/get_nearest.php' => 'Get nearest aggregators'
                    ],
                    'Pricing' => [
                        'GET /pricing/get_prices.php' => 'Get current prices'
                    ],
                    'Payments' => [
                        'GET /payments/get_earnings.php' => 'Get user earnings'
                    ],
                    'User' => [
                        'PUT /user/update_profile.php' => 'Update user profile'
                    ]
                ],
                'documentation' => '/api/README.md'
            ], 'API is running successfully');
        } else {
            sendErrorResponse('Database connection failed', 500, [
                'database_error' => $connectionTest['message']
            ]);
        }
        
    } catch (Exception $e) {
        sendServerErrorResponse('API error: ' . $e->getMessage());
    }
} else {
    sendErrorResponse("Method not allowed", 405);
}
?>
