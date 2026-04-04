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

// Only waste collectors can view their collections
if ($currentUser['user_role'] !== 'Waste Collector') {
    sendUnauthorizedResponse('Only waste collectors can view collections');
}

// Get query parameters
$status = $_GET['status'] ?? 'all';
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

// Validate limit
if ($limit > 100 || $limit < 1) {
    $limit = 20;
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Build query based on status filter
    $whereClause = "WHERE wc.collectorID = :collectorID";
    $params = [':collectorID' => $currentUser['user_id']];
    
    if ($status !== 'all') {
        $whereClause .= " AND s.statusName = :status";
        $params[':status'] = $status;
    }
    
    // Get collections with pagination
    $query = "
        SELECT wc.collectionID, wc.weight, wc.collectionDate, wc.latitude, wc.longitude, 
               wc.location, wc.notes, wc.photoPath,
               pt.plasticTypeID, pt.typeName, pt.typeCode,
               s.statusName, s.statusID,
               u.userName as aggregatorName, u.userContact as aggregatorContact
        FROM WasteCollection wc
        JOIN PlasticType pt ON wc.plasticTypeID = pt.plasticTypeID
        JOIN Status s ON wc.statusID = s.statusID
        LEFT JOIN User u ON wc.aggregatorID = u.userID
        $whereClause
        ORDER BY wc.collectionDate DESC
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $conn->prepare($query);
    
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    
    $stmt->execute();
    $collections = $stmt->fetchAll();
    
    // Get total count for pagination
    $countQuery = "
        SELECT COUNT(*) as total
        FROM WasteCollection wc
        JOIN Status s ON wc.statusID = s.statusID
        $whereClause
    ";
    
    $stmt = $conn->prepare($countQuery);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->execute();
    $totalCount = $stmt->fetch()['total'];
    
    // Format collections data
    $formattedCollections = [];
    foreach ($collections as $collection) {
        $formattedCollections[] = [
            'collectionID' => (int)$collection['collectionID'],
            'weight' => (float)$collection['weight'],
            'collectionDate' => $collection['collectionDate'],
            'latitude' => $collection['latitude'] ? (float)$collection['latitude'] : null,
            'longitude' => $collection['longitude'] ? (float)$collection['longitude'] : null,
            'location' => $collection['location'],
            'notes' => $collection['notes'],
            'photoPath' => $collection['photoPath'],
            'plasticType' => [
                'plasticTypeID' => (int)$collection['plasticTypeID'],
                'typeName' => $collection['typeName'],
                'typeCode' => $collection['typeCode']
            ],
            'status' => [
                'statusID' => (int)$collection['statusID'],
                'statusName' => $collection['statusName']
            ],
            'aggregator' => $collection['aggregatorName'] ? [
                'name' => $collection['aggregatorName'],
                'contact' => $collection['aggregatorContact']
            ] : null
        ];
    }
    
    // Calculate statistics
    $statsQuery = "
        SELECT 
            COUNT(*) as totalCollections,
            SUM(weight) as totalWeight,
            COUNT(CASE WHEN s.statusName = 'Delivered' THEN 1 END) as deliveredCollections,
            SUM(CASE WHEN s.statusName = 'Delivered' THEN weight ELSE 0 END) as deliveredWeight,
            COUNT(CASE WHEN s.statusName = 'Pending' THEN 1 END) as pendingCollections
        FROM WasteCollection wc
        JOIN Status s ON wc.statusID = s.statusID
        WHERE wc.collectorID = :collectorID
    ";
    
    $stmt = $conn->prepare($statsQuery);
    $stmt->bindValue(':collectorID', $currentUser['user_id']);
    $stmt->execute();
    $stats = $stmt->fetch();
    
    $statistics = [
        'totalCollections' => (int)$stats['totalCollections'],
        'totalWeight' => (float)$stats['totalWeight'],
        'deliveredCollections' => (int)$stats['deliveredCollections'],
        'deliveredWeight' => (float)$stats['deliveredWeight'],
        'pendingCollections' => (int)$stats['pendingCollections']
    ];
    
    sendSuccessResponse([
        'collections' => $formattedCollections,
        'statistics' => $statistics,
        'pagination' => [
            'total' => (int)$totalCount,
            'limit' => $limit,
            'offset' => $offset,
            'hasMore' => ($offset + $limit) < $totalCount
        ]
    ], 'Collections retrieved successfully');
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
