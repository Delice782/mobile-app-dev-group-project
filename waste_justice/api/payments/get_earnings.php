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

// Only waste collectors can view their earnings
if ($currentUser['user_role'] !== 'Waste Collector') {
    sendUnauthorizedResponse('Only waste collectors can view earnings');
}

// Get query parameters
$startDate = $_GET['startDate'] ?? null;
$endDate = $_GET['endDate'] ?? null;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

// Validate limit
if ($limit > 100 || $limit < 1) {
    $limit = 50;
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Build date filter
    $dateFilter = "";
    $params = [':collectorID' => $currentUser['user_id']];
    
    if ($startDate) {
        $dateFilter .= " AND DATE(p.paidAt) >= :startDate";
        $params[':startDate'] = $startDate;
    }
    
    if ($endDate) {
        $dateFilter .= " AND DATE(p.paidAt) <= :endDate";
        $params[':endDate'] = $endDate;
    }
    
    // Get earnings with pagination
    $earningsQuery = "
        SELECT 
            p.paymentID,
            p.amount,
            p.platformFee,
            p.grossAmount,
            p.paymentMethod,
            p.mobileMoneyNumber,
            p.referenceNumber,
            p.paidAt,
            p.createdAt,
            wc.collectionID,
            wc.weight,
            wc.collectionDate,
            pt.typeName as plasticType,
            pt.typeCode,
            u.userName as aggregatorName
        FROM Payment p
        JOIN WasteCollection wc ON p.collectionID = wc.collectionID
        JOIN PlasticType pt ON wc.plasticTypeID = pt.plasticTypeID
        LEFT JOIN User u ON wc.aggregatorID = u.userID
        WHERE p.toUserID = :collectorID
        AND p.status = 'completed'
        $dateFilter
        ORDER BY p.paidAt DESC
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $conn->prepare($earningsQuery);
    
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    
    $stmt->execute();
    $earnings = $stmt->fetchAll();
    
    // Get total earnings summary
    $summaryQuery = "
        SELECT 
            COUNT(*) as totalTransactions,
            SUM(p.amount) as totalEarnings,
            SUM(p.grossAmount) as totalGrossEarnings,
            SUM(p.platformFee) as totalPlatformFees,
            SUM(wc.weight) as totalWeightDelivered,
            COUNT(CASE WHEN DATE(p.paidAt) = CURDATE() THEN 1 END) as todayTransactions,
            SUM(CASE WHEN DATE(p.paidAt) = CURDATE() THEN p.amount ELSE 0 END) as todayEarnings,
            COUNT(CASE WHEN DATE(p.paidAt) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 END) as weekTransactions,
            SUM(CASE WHEN DATE(p.paidAt) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN p.amount ELSE 0 END) as weekEarnings,
            COUNT(CASE WHEN DATE(p.paidAt) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN 1 END) as monthTransactions,
            SUM(CASE WHEN DATE(p.paidAt) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN p.amount ELSE 0 END) as monthEarnings
        FROM Payment p
        JOIN WasteCollection wc ON p.collectionID = wc.collectionID
        WHERE p.toUserID = :collectorID
        AND p.status = 'completed'
        $dateFilter
    ";
    
    $stmt = $conn->prepare($summaryQuery);
    foreach ($params as $key => $value) {
        if ($key !== ':limit' && $key !== ':offset') {
            $stmt->bindValue($key, $value);
        }
    }
    $stmt->execute();
    $summary = $stmt->fetch();
    
    // Get earnings by plastic type
    $byTypeQuery = "
        SELECT 
            pt.typeName,
            pt.typeCode,
            COUNT(*) as transactionCount,
            SUM(p.amount) as totalEarnings,
            SUM(wc.weight) as totalWeight,
            AVG(p.amount) as avgEarningPerTransaction
        FROM Payment p
        JOIN WasteCollection wc ON p.collectionID = wc.collectionID
        JOIN PlasticType pt ON wc.plasticTypeID = pt.plasticTypeID
        WHERE p.toUserID = :collectorID
        AND p.status = 'completed'
        $dateFilter
        GROUP BY pt.plasticTypeID, pt.typeName, pt.typeCode
        ORDER BY totalEarnings DESC
    ";
    
    $stmt = $conn->prepare($byTypeQuery);
    foreach ($params as $key => $value) {
        if ($key !== ':limit' && $key !== ':offset') {
            $stmt->bindValue($key, $value);
        }
    }
    $stmt->execute();
    $earningsByType = $stmt->fetchAll();
    
    // Format earnings data
    $formattedEarnings = [];
    foreach ($earnings as $earning) {
        $formattedEarnings[] = [
            'paymentID' => (int)$earning['paymentID'],
            'amount' => (float)$earning['amount'],
            'platformFee' => (float)$earning['platformFee'],
            'grossAmount' => (float)$earning['grossAmount'],
            'paymentMethod' => $earning['paymentMethod'],
            'mobileMoneyNumber' => $earning['mobileMoneyNumber'],
            'referenceNumber' => $earning['referenceNumber'],
            'paidAt' => $earning['paidAt'],
            'createdAt' => $earning['createdAt'],
            'collection' => [
                'collectionID' => (int)$earning['collectionID'],
                'weight' => (float)$earning['weight'],
                'collectionDate' => $earning['collectionDate'],
                'plasticType' => [
                    'typeName' => $earning['plasticType'],
                    'typeCode' => $earning['typeCode']
                ]
            ],
            'aggregatorName' => $earning['aggregatorName']
        ];
    }
    
    // Format earnings by type
    $formattedEarningsByType = [];
    foreach ($earningsByType as $type) {
        $formattedEarningsByType[] = [
            'plasticType' => [
                'typeName' => $type['typeName'],
                'typeCode' => $type['typeCode']
            ],
            'transactionCount' => (int)$type['transactionCount'],
            'totalEarnings' => (float)$type['totalEarnings'],
            'totalWeight' => (float)$type['totalWeight'],
            'avgEarningPerTransaction' => (float)$type['avgEarningPerTransaction']
        ];
    }
    
    // Format summary
    $formattedSummary = [
        'totalTransactions' => (int)$summary['totalTransactions'],
        'totalEarnings' => (float)$summary['totalEarnings'],
        'totalGrossEarnings' => (float)$summary['totalGrossEarnings'],
        'totalPlatformFees' => (float)$summary['totalPlatformFees'],
        'totalWeightDelivered' => (float)$summary['totalWeightDelivered'],
        'today' => [
            'transactions' => (int)$summary['todayTransactions'],
            'earnings' => (float)$summary['todayEarnings']
        ],
        'thisWeek' => [
            'transactions' => (int)$summary['weekTransactions'],
            'earnings' => (float)$summary['weekEarnings']
        ],
        'thisMonth' => [
            'transactions' => (int)$summary['monthTransactions'],
            'earnings' => (float)$summary['monthEarnings']
        ]
    ];
    
    sendSuccessResponse([
        'earnings' => $formattedEarnings,
        'summary' => $formattedSummary,
        'earningsByType' => $formattedEarningsByType,
        'currency' => 'GHS',
        'filter' => [
            'startDate' => $startDate,
            'endDate' => $endDate
        ]
    ], 'Earnings data retrieved successfully');
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
