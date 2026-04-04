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

// Optional authentication - allow public access to pricing
$currentUser = getCurrentUser();

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Get aggregator pricing
    $aggregatorPricingQuery = "
        SELECT 
            ap.pricePerKg,
            ap.updatedAt,
            u.userID as aggregatorID,
            ar.businessName,
            u.userName as contactPerson,
            u.userContact as contact,
            u.rating,
            u.totalRatings,
            pt.plasticTypeID,
            pt.typeName,
            pt.typeCode
        FROM AggregatorPricing ap
        JOIN User u ON ap.aggregatorID = u.userID
        JOIN AggregatorRegistration ar ON u.userID = ar.userID
        JOIN PlasticType pt ON ap.plasticTypeID = pt.plasticTypeID
        INNER JOIN Subscriptions s ON u.userID = s.userID
        WHERE ap.isActive = TRUE
        AND u.status = 'active'
        AND s.paymentStatus = 'Success'
        AND s.isActive = TRUE
        AND (s.subscriptionEnd IS NULL OR s.subscriptionEnd >= CURDATE())
        ORDER BY pt.typeName, ap.pricePerKg DESC
    ";
    
    $stmt = $conn->prepare($aggregatorPricingQuery);
    $stmt->execute();
    $aggregatorPrices = $stmt->fetchAll();
    
    // Group prices by plastic type
    $groupedPrices = [];
    foreach ($aggregatorPrices as $price) {
        $plasticTypeID = $price['plasticTypeID'];
        
        if (!isset($groupedPrices[$plasticTypeID])) {
            $groupedPrices[$plasticTypeID] = [
                'plasticTypeID' => (int)$price['plasticTypeID'],
                'typeName' => $price['typeName'],
                'typeCode' => $price['typeCode'],
                'aggregators' => [],
                'priceRange' => [
                    'min' => (float)$price['pricePerKg'],
                    'max' => (float)$price['pricePerKg'],
                    'average' => (float)$price['pricePerKg']
                ]
            ];
        }
        
        $groupedPrices[$plasticTypeID]['aggregators'][] = [
            'aggregatorID' => (int)$price['aggregatorID'],
            'businessName' => $price['businessName'],
            'contactPerson' => $price['contactPerson'],
            'contact' => $price['contact'],
            'rating' => (float)$price['rating'],
            'totalRatings' => (int)$price['totalRatings'],
            'pricePerKg' => (float)$price['pricePerKg'],
            'updatedAt' => $price['updatedAt']
        ];
        
        // Update price range
        $currentPrice = (float)$price['pricePerKg'];
        $groupedPrices[$plasticTypeID]['priceRange']['min'] = min($groupedPrices[$plasticTypeID]['priceRange']['min'], $currentPrice);
        $groupedPrices[$plasticTypeID]['priceRange']['max'] = max($groupedPrices[$plasticTypeID]['priceRange']['max'], $currentPrice);
    }
    
    // Calculate average prices
    foreach ($groupedPrices as $plasticTypeID => &$data) {
        $totalPrice = 0;
        $count = count($data['aggregators']);
        
        foreach ($data['aggregators'] as $aggregator) {
            $totalPrice += $aggregator['pricePerKg'];
        }
        
        $data['priceRange']['average'] = round($totalPrice / $count, 2);
        $data['aggregatorCount'] = $count;
    }
    
    // Get price trends (last 7 days)
    $trendsQuery = "
        SELECT 
            pt.plasticTypeID,
            pt.typeName,
            AVG(ap.pricePerKg) as avgPrice,
            DATE(ap.updatedAt) as priceDate
        FROM AggregatorPricing ap
        JOIN PlasticType pt ON ap.plasticTypeID = pt.plasticTypeID
        WHERE ap.updatedAt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        AND ap.isActive = TRUE
        GROUP BY pt.plasticTypeID, DATE(ap.updatedAt)
        ORDER BY pt.typeName, priceDate
    ";
    
    $stmt = $conn->prepare($trendsQuery);
    $stmt->execute();
    $trends = $stmt->fetchAll();
    
    // Group trends by plastic type
    $groupedTrends = [];
    foreach ($trends as $trend) {
        $plasticTypeID = $trend['plasticTypeID'];
        
        if (!isset($groupedTrends[$plasticTypeID])) {
            $groupedTrends[$plasticTypeID] = [
                'plasticTypeID' => (int)$trend['plasticTypeID'],
                'typeName' => $trend['typeName'],
                'trend' => []
            ];
        }
        
        $groupedTrends[$plasticTypeID]['trend'][] = [
            'date' => $trend['priceDate'],
            'avgPrice' => (float)$trend['avgPrice']
        ];
    }
    
    // Calculate price changes
    foreach ($groupedTrends as $plasticTypeID => &$trendData) {
        $trendPoints = $trendData['trend'];
        
        if (count($trendPoints) >= 2) {
            $firstPrice = $trendPoints[0]['avgPrice'];
            $lastPrice = end($trendPoints)['avgPrice'];
            $change = round((($lastPrice - $firstPrice) / $firstPrice) * 100, 2);
            
            $trendData['change'] = [
                'percentage' => $change,
                'direction' => $change > 0 ? 'up' : ($change < 0 ? 'down' : 'stable')
            ];
        } else {
            $trendData['change'] = [
                'percentage' => 0,
                'direction' => 'stable'
            ];
        }
    }
    
    // Merge pricing data with trends
    $finalPricingData = [];
    foreach ($groupedPrices as $plasticTypeID => $priceData) {
        $finalPricingData[] = [
            ...$priceData,
            'trend' => $groupedTrends[$plasticTypeID]['trend'] ?? [],
            'change' => $groupedTrends[$plasticTypeID]['change'] ?? [
                'percentage' => 0,
                'direction' => 'stable'
            ]
        ];
    }
    
    sendSuccessResponse([
        'pricing' => $finalPricingData,
        'lastUpdated' => date('Y-m-d H:i:s'),
        'currency' => 'GHS',
        'unit' => 'per kg'
    ], 'Pricing data retrieved successfully');
    
} catch (PDOException $e) {
    sendServerErrorResponse('Database error: ' . $e->getMessage());
}
?>
