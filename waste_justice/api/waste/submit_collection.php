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
    if ($conn === null) {
        sendServerErrorResponse('Database connection failed');
    }

    $plasticTypeID = (int) $data['plasticTypeID'];

    // Check if plastic type exists
    $checkPlasticQuery = "SELECT plasticTypeID, typeName FROM PlasticType WHERE plasticTypeID = :plasticTypeID";
    $stmt = $conn->prepare($checkPlasticQuery);
    $stmt->bindValue(':plasticTypeID', $plasticTypeID, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        sendValidationErrorResponse(['plasticTypeID' => 'Invalid plastic type']);
    }

    $weight = (float) $data['weight'];
    $latitude = (float) $data['latitude'];
    $longitude = (float) $data['longitude'];
    $location = (string) ($data['location'] ?? '');
    $notes = (string) ($data['notes'] ?? '');
    $photoPath = (string) ($data['photoPath'] ?? '');

    $aggregatorID = null;
    if (!empty($data['aggregatorID'])) {
        $aggregatorID = (int) $data['aggregatorID'];
        $aggCheck = $conn->prepare("
            SELECT u.userID 
            FROM User u
            INNER JOIN Subscriptions s ON u.userID = s.userID
            WHERE u.userID = :aid 
            AND u.userRole = 'Aggregator' 
            AND u.status = 'active'
            AND s.paymentStatus = 'Success'
            AND s.isActive = 1
            AND (s.subscriptionEnd IS NULL OR s.subscriptionEnd >= CURDATE())
            LIMIT 1
        ");
        $aggCheck->bindValue(':aid', $aggregatorID, PDO::PARAM_INT);
        $aggCheck->execute();
        if ($aggCheck->rowCount() === 0) {
            sendValidationErrorResponse(['aggregatorID' => 'Invalid aggregator or subscription not active']);
        }
    }

    // Generate unique hash to prevent duplicates
    $hashData = $currentUser['user_id'] . $plasticTypeID . $weight . $latitude . $longitude . time();
    $hash = hash('sha256', $hashData);

    // Insert waste collection (optional aggregatorID — same as web upload_waste_action)
    $columns = 'collectorID, plasticTypeID, weight, latitude, longitude, location, notes, photoPath, hash, statusID';
    $placeholders = ':collectorID, :plasticTypeID, :weight, :latitude, :longitude, :location, :notes, :photoPath, :hash, 1';
    if ($aggregatorID !== null) {
        $columns .= ', aggregatorID';
        $placeholders .= ', :aggregatorID';
    }

    $insertQuery = "INSERT INTO WasteCollection ($columns) VALUES ($placeholders)";

    $stmt = $conn->prepare($insertQuery);
    $collectorId = (int) $currentUser['user_id'];
    $stmt->bindValue(':collectorID', $collectorId, PDO::PARAM_INT);
    $stmt->bindValue(':plasticTypeID', $plasticTypeID, PDO::PARAM_INT);
    $stmt->bindValue(':weight', $weight);
    $stmt->bindValue(':latitude', $latitude);
    $stmt->bindValue(':longitude', $longitude);
    $stmt->bindParam(':location', $location);
    $stmt->bindParam(':notes', $notes);
    $stmt->bindParam(':photoPath', $photoPath);
    $stmt->bindParam(':hash', $hash);
    if ($aggregatorID !== null) {
        $stmt->bindValue(':aggregatorID', $aggregatorID, PDO::PARAM_INT);
    }

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
        $cid = (int) $collectionId;
        $stmt->bindValue(':collectionId', $cid, PDO::PARAM_INT);
        $stmt->execute();

        $collection = $stmt->fetch();
        if (!$collection) {
            sendServerErrorResponse('Collection record could not be loaded after submit');
        }

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
} catch (Throwable $e) {
    sendServerErrorResponse('Server error: ' . $e->getMessage());
}
?>
