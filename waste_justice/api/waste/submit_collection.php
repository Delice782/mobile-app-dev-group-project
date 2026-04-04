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

// Require authentication
$currentUser = requireAuth();

// Only waste collectors can submit collections
if ($currentUser['user_role'] !== 'Waste Collector') {
    sendUnauthorizedResponse('Only waste collectors can submit collections');
}

$data = getJsonInput();
$data = sanitizeInput($data);

// Validate required fields
$requiredFields = ['plasticTypeID', 'weight', 'latitude', 'longitude'];
$errors = validateRequiredFields($data, $requiredFields);

if (!empty($errors)) {
    sendValidationErrorResponse($errors);
}

// Validate weight
if (!is_numeric($data['weight']) || $data['weight'] <= 0) {
    sendValidationErrorResponse(['weight' => 'Weight must be a positive number']);
}

// Minimum weight validation (5kg as per your app)
if ($data['weight'] < 5) {
    sendValidationErrorResponse(['weight' => 'Minimum weight is 5kg']);
}

// Validate coordinates
if (!is_numeric($data['latitude']) || $data['latitude'] < -90 || $data['latitude'] > 90) {
    sendValidationErrorResponse(['latitude' => 'Invalid latitude']);
}

if (!is_numeric($data['longitude']) || $data['longitude'] < -180 || $data['longitude'] > 180) {
    sendValidationErrorResponse(['longitude' => 'Invalid longitude']);
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Check if plastic type exists
    $checkPlasticQuery = "SELECT plasticTypeID, typeName FROM PlasticType WHERE plasticTypeID = :plasticTypeID";
    $stmt = $conn->prepare($checkPlasticQuery);
    $stmt->bindParam(':plasticTypeID', $data['plasticTypeID']);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        sendValidationErrorResponse(['plasticTypeID' => 'Invalid plastic type']);
    }
    
    $plasticType = $stmt->fetch();
    
    // Generate unique hash to prevent duplicates
    $hashData = $currentUser['user_id'] . $data['plasticTypeID'] . $data['weight'] . $data['latitude'] . $data['longitude'] . time();
    $hash = hash('sha256', $hashData);
    
    // Insert waste collection
    $insertQuery = "INSERT INTO WasteCollection 
                    (collectorID, plasticTypeID, weight, latitude, longitude, location, notes, photoPath, hash, statusID) 
                    VALUES (:collectorID, :plasticTypeID, :weight, :latitude, :longitude, :location, :notes, :photoPath, :hash, 1)";
    
    $stmt = $conn->prepare($insertQuery);
    $stmt->bindParam(':collectorID', $currentUser['user_id']);
    $stmt->bindParam(':plasticTypeID', $data['plasticTypeID']);
    $stmt->bindParam(':weight', $data['weight']);
    $stmt->bindParam(':latitude', $data['latitude']);
    $stmt->bindParam(':longitude', $data['longitude']);
    $stmt->bindParam(':location', $data['location'] ?? '');
    $stmt->bindParam(':notes', $data['notes'] ?? '');
    $stmt->bindParam(':photoPath', $data['photoPath'] ?? '');
    $stmt->bindParam(':hash', $hash);
    
    if ($stmt->execute()) {
        $collectionId = $conn->lastInsertId();
        
        // Get collection details for response
        $getCollectionQuery = "
            SELECT wc.collectionID, wc.weight, wc.collectionDate, wc.latitude, wc.longitude, 
                   wc.location, wc.notes, wc.photoPath,
                   pt.plasticTypeID, pt.typeName, pt.typeCode,
                   s.statusName
            FROM WasteCollection wc
            JOIN PlasticType pt ON wc.plasticTypeID = pt.plasticTypeID
            JOIN Status s ON wc.statusID = s.statusID
            WHERE wc.collectionID = :collectionId
        ";
        
        $stmt = $conn->prepare($getCollectionQuery);
        $stmt->bindParam(':collectionId', $collectionId);
        $stmt->execute();
        
        $collection = $stmt->fetch();
        
        // Format response
        $collectionData = [
            'collectionID' => (int)$collection['collectionID'],
            'weight' => (float)$collection['weight'],
            'collectionDate' => $collection['collectionDate'],
            'latitude' => (float)$collection['latitude'],
            'longitude' => (float)$collection['longitude'],
            'location' => $collection['location'],
            'notes' => $collection['notes'],
            'photoPath' => $collection['photoPath'],
            'plasticType' => [
                'plasticTypeID' => (int)$collection['plasticTypeID'],
                'typeName' => $collection['typeName'],
                'typeCode' => $collection['typeCode']
            ],
            'status' => $collection['statusName']
        ];
        
        sendSuccessResponse([
            'collection' => $collectionData,
            'message' => 'Waste collection submitted successfully. It will be reviewed by aggregators.'
        ], 'Collection submitted successfully');
        
    } else {
        sendServerErrorResponse('Failed to submit collection');
    }
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
