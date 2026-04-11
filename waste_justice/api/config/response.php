<?php
/**
 * API Response Helper Functions
 * Standardizes API responses for WasteJustice mobile app
 */

if (!function_exists('getallheaders')) {
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (strncmp($name, 'HTTP_', 5) === 0) {
                $key = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))));
                $headers[$key] = $value;
            }
        }
        if (isset($_SERVER['CONTENT_TYPE'])) {
            $headers['Content-Type'] = $_SERVER['CONTENT_TYPE'];
        }
        return $headers;
    }
}

/**
 * Send success response
 */
function sendSuccessResponse($data = null, $message = "Success", $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    
    $response = [
        'success' => true,
        'message' => $message,
        'data' => $data,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response);
    exit;
}

/**
 * Send error response
 */
function sendErrorResponse($message = "Error occurred", $statusCode = 400, $data = null) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    
    $response = [
        'success' => false,
        'message' => $message,
        'data' => $data,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response);
    exit;
}

/**
 * Send validation error response
 */
function sendValidationErrorResponse($errors) {
    http_response_code(422);
    header('Content-Type: application/json');
    
    $response = [
        'success' => false,
        'message' => 'Validation failed',
        'errors' => $errors,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response);
    exit;
}

/**
 * Send unauthorized response
 */
function sendUnauthorizedResponse($message = "Unauthorized access") {
    sendErrorResponse($message, 401);
}

/**
 * Send not found response
 */
function sendNotFoundResponse($message = "Resource not found") {
    sendErrorResponse($message, 404);
}

/**
 * Send server error response
 */
function sendServerErrorResponse($message = "Internal server error") {
    sendErrorResponse($message, 500);
}

/**
 * Validate required fields
 */
function validateRequiredFields($data, $requiredFields) {
    $errors = [];

    foreach ($requiredFields as $field) {
        if (!array_key_exists($field, $data)) {
            $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
            continue;
        }
        $value = $data[$field];
        if ($value === null || $value === '') {
            $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
            continue;
        }
        if (is_string($value) && trim($value) === '') {
            $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
        }
    }

    return $errors;
}

/**
 * Sanitize input data (JSON may contain int/float; never call trim() on those — PHP 8+ fatals).
 */
function sanitizeInput($data) {
    if (is_array($data)) {
        return array_map('sanitizeInput', $data);
    }
    if (is_int($data) || is_float($data) || is_bool($data)) {
        return $data;
    }
    if ($data === null) {
        return null;
    }
    $str = (string) $data;
    return htmlspecialchars(strip_tags(trim($str)), ENT_QUOTES, 'UTF-8');
}

/**
 * Get JSON input from request
 */
function getJsonInput() {
    $json = file_get_contents('php://input');
    return json_decode($json, true) ?: [];
}

/**
 * Generate JWT token (simplified version)
 */
function generateToken($userId, $userRole) {
    $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    $payload = json_encode([
        'user_id' => $userId,
        'user_role' => $userRole,
        'exp' => time() + (60 * 60 * 24), // 24 hours
        'iat' => time()
    ]);
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, 'your-secret-key', true);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
}

/**
 * Validate JWT token (simplified version)
 */
function validateToken($token) {
    if (empty($token)) {
        return false;
    }
    
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    
    $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1])), true);
    
    if (!$payload || $payload['exp'] < time()) {
        return false;
    }
    
    return $payload;
}

/**
 * Get current user from token
 */
function getCurrentUser() {
    $headers = getallheaders();
    if (!is_array($headers)) {
        $headers = [];
    }
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if ($authHeader === '' && !empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    }
    if ($authHeader === '' && !empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }

    if (empty($authHeader) || !preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        return null;
    }

    $token = $matches[1];
    return validateToken($token);
}

/**
 * Require authentication
 */
function requireAuth() {
    $user = getCurrentUser();
    if (!$user) {
        sendUnauthorizedResponse('Authentication required');
    }
    return $user;
}

/**
 * Check if user has specific role
 */
function requireRole($requiredRole) {
    $user = requireAuth();
    
    if ($user['user_role'] !== $requiredRole && $user['user_role'] !== 'Admin') {
        sendUnauthorizedResponse('Insufficient permissions');
    }
    
    return $user;
}
?>
