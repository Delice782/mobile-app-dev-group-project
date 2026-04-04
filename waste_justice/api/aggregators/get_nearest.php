<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';
require_once '../config/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendErrorResponse("Method not allowed", 405);
}

// Require authentication
$currentUser = requireAuth();

// Only waste collectors can view aggregators
if ($currentUser['user_role'] !== 'Waste Collector') {
    sendUnauthorizedResponse('Only waste collectors can view aggregators');
}

// Get query parameters
$latitude = $_GET['latitude'] ?? null;
$longitude = $_GET['longitude'] ?? null;
$radius = isset($_GET['radius']) ? (float)$_GET['radius'] : 10.0; // Default 10km radius
$plasticTypeID = $_GET['plasticTypeID'] ?? null;

// Validate coordinates
if (!$latitude || !$longitude) {
    sendValidationErrorResponse(['latitude' => 'Latitude is required', 'longitude' => 'Longitude is required']);
}

if (!is_numeric($latitude) || $latitude < -90 || $latitude > 90) {
    sendValidationErrorResponse(['latitude' => 'Invalid latitude']);
}

if (!is_numeric($longitude) || $longitude < -180 || $longitude > 180) {
    sendValidationErrorResponse(['longitude' => 'Invalid longitude']);
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Build query to find nearest aggregators with pricing
    $query = "
        SELECT 
            u.userID as aggregatorID,
            u.userName,
            u.userContact as contact,
            u.address,
            u.latitude,
            u.longitude,
            u.rating,
            u.totalRatings,
            ar.businessName,
            ar.capacity,
            pt.plasticTypeID,
            pt.typeName as plasticType,
            ap.pricePerKg,
            (6371 * acos(cos(radians(:latitude)) * cos(radians(u.latitude)) * 
             cos(radians(u.longitude) - radians(:longitude)) + sin(radians(:latitude)) * 
             sin(radians(u.latitude)))) AS distance
        FROM User u
        JOIN AggregatorRegistration ar ON u.userID = ar.userID
        JOIN AggregatorPricing ap ON u.userID = ap.aggregatorID
        JOIN PlasticType pt ON ap.plasticTypeID = pt.plasticTypeID
        INNER JOIN Subscriptions s ON u.userID = s.userID
        WHERE u.userRole = 'Aggregator' 
        AND u.status = 'active' 
        AND ap.isActive = TRUE
        AND s.paymentStatus = 'Success'
        AND s.isActive = TRUE
        AND (s.subscriptionEnd IS NULL OR s.subscriptionEnd >= CURDATE())
        HAVING distance <= :radius
        ORDER BY distance, ap.pricePerKg DESC
    ";
    
    $params = [
        ':latitude' => $latitude,
        ':longitude' => $longitude,
        ':radius' => $radius
    ];
    
    // Filter by plastic type if specified
    if ($plasticTypeID) {
        $query .= " AND pt.plasticTypeID = :plasticTypeID";
        $params[':plasticTypeID'] = $plasticTypeID;
    }
    
    $stmt = $conn->prepare($query);
    
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    
    $stmt->execute();
    $aggregators = $stmt->fetchAll();
    
    // Format aggregators data
    $formattedAggregators = [];
    foreach ($aggregators as $aggregator) {
        $formattedAggregators[] = [
            'aggregatorID' => (int)$aggregator['aggregatorID'],
            'businessName' => $aggregator['businessName'],
            'contactPerson' => $aggregator['userName'],
            'contact' => $aggregator['contact'],
            'address' => $aggregator['address'],
            'location' => [
                'latitude' => (float)$aggregator['latitude'],
                'longitude' => (float)$aggregator['longitude']
            ],
            'distance' => round((float)$aggregator['distance'], 2),
            'rating' => (float)$aggregator['rating'],
            'totalRatings' => (int)$aggregator['totalRatings'],
            'capacity' => (float)$aggregator['capacity'],
            'pricing' => [
                'plasticTypeID' => (int)$aggregator['plasticTypeID'],
                'plasticType' => $aggregator['plasticType'],
                'pricePerKg' => (float)$aggregator['pricePerKg']
            ]
        ];
    }
    
    // Get all plastic types for reference
    $plasticTypesQuery = "SELECT plasticTypeID, typeName, typeCode, description FROM PlasticType ORDER BY typeName";
    $stmt = $conn->prepare($plasticTypesQuery);
    $stmt->execute();
    $plasticTypes = $stmt->fetchAll();
    
    $formattedPlasticTypes = [];
    foreach ($plasticTypes as $type) {
        $formattedPlasticTypes[] = [
            'plasticTypeID' => (int)$type['plasticTypeID'],
            'typeName' => $type['typeName'],
            'typeCode' => $type['typeCode'],
            'description' => $type['description']
        ];
    }
    
    sendSuccessResponse([
        'aggregators' => $formattedAggregators,
        'plasticTypes' => $formattedPlasticTypes,
        'searchCriteria' => [
            'latitude' => (float)$latitude,
            'longitude' => (float)$longitude,
            'radius' => $radius,
            'plasticTypeID' => $plasticTypeID ? (int)$plasticTypeID : null
        ]
    ], 'Nearest aggregators retrieved successfully');
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
