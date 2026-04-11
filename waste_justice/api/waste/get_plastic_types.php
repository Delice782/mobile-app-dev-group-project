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

$currentUser = requireAuth();

if ($currentUser['user_role'] !== 'Waste Collector') {
    sendUnauthorizedResponse('Only waste collectors can view plastic types');
}

$aggregatorID = isset($_GET['aggregatorID']) ? (int) $_GET['aggregatorID'] : 0;

try {
    $database = new Database();
    $conn = $database->getConnection();

    if ($aggregatorID > 0) {
        $sql = "
            SELECT 
                pt.plasticTypeID,
                pt.typeName,
                pt.typeCode,
                pt.description,
                ap.pricePerKg
            FROM PlasticType pt
            LEFT JOIN AggregatorPricing ap 
                ON pt.plasticTypeID = ap.plasticTypeID 
                AND ap.aggregatorID = :aggregatorID 
                AND ap.isActive = 1
            ORDER BY pt.typeName
        ";
        $stmt = $conn->prepare($sql);
        $stmt->bindValue(':aggregatorID', $aggregatorID, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } else {
        $sql = "
            SELECT plasticTypeID, typeName, typeCode, description, NULL AS pricePerKg
            FROM PlasticType
            ORDER BY typeName
        ";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    $out = [];
    foreach ($rows as $row) {
        $out[] = [
            'plasticTypeID' => (int) $row['plasticTypeID'],
            'typeName' => $row['typeName'],
            'typeCode' => $row['typeCode'],
            'description' => $row['description'],
            'pricePerKg' => $row['pricePerKg'] !== null ? (float) $row['pricePerKg'] : null,
        ];
    }

    sendSuccessResponse(['plasticTypes' => $out], 'Plastic types retrieved successfully');
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
