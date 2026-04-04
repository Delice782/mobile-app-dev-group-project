# WasteJustice API Documentation

## Overview
This API provides backend services for the WasteJustice mobile application, specifically designed for waste collectors to manage plastic waste collection, track earnings, and connect with aggregators.

## Base URL
```
http://your-domain.com/api
```

## Authentication
All protected endpoints require JWT token authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Response Format
All API responses follow a consistent format:

### Success Response
```json
{
    "success": true,
    "message": "Success message",
    "data": {},
    "timestamp": "2024-03-15 10:30:00"
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error message",
    "data": {},
    "timestamp": "2024-03-15 10:30:00"
}
```

## Endpoints

### Authentication

#### Register Waste Collector
```
POST /auth/register.php
```

**Request Body:**
```json
{
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "userPassword": "password123",
    "userContact": "+233244123456"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Registration successful. Your account is pending approval.",
    "data": {
        "user": {
            "userID": 1,
            "userName": "John Doe",
            "userEmail": "john@example.com",
            "userContact": "+233244123456",
            "userRole": "Waste Collector",
            "status": "pending"
        },
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
}
```

#### Login
```
POST /auth/login.php
```

**Request Body:**
```json
{
    "userEmail": "john@example.com",
    "userPassword": "password123"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "user": {
            "userID": 1,
            "userName": "John Doe",
            "userEmail": "john@example.com",
            "userContact": "+233244123456",
            "userRole": "Waste Collector",
            "status": "active",
            "latitude": 5.6037,
            "longitude": -0.1870,
            "address": "Accra Central",
            "rating": 4.5,
            "totalRatings": 12,
            "subscription_status": "free"
        },
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
}
```

### Waste Collection

#### Submit Waste Collection
```
POST /waste/submit_collection.php
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
    "plasticTypeID": 1,
    "weight": 8.5,
    "latitude": 5.6037,
    "longitude": -0.1870,
    "location": "Accra Central Market",
    "notes": "Clean PET bottles",
    "photoPath": "/uploads/collection_123.jpg"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Collection submitted successfully",
    "data": {
        "collection": {
            "collectionID": 123,
            "weight": 8.5,
            "collectionDate": "2024-03-15 10:30:00",
            "latitude": 5.6037,
            "longitude": -0.1870,
            "location": "Accra Central Market",
            "notes": "Clean PET bottles",
            "photoPath": "/uploads/collection_123.jpg",
            "plasticType": {
                "plasticTypeID": 1,
                "typeName": "PET",
                "typeCode": "PET"
            },
            "status": "Pending"
        }
    }
}
```

#### Get Collections
```
GET /waste/get_collections.php
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `status` (optional): Filter by status (all, pending, accepted, rejected, delivered)
- `limit` (optional): Number of results per page (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
    "success": true,
    "message": "Collections retrieved successfully",
    "data": {
        "collections": [
            {
                "collectionID": 123,
                "weight": 8.5,
                "collectionDate": "2024-03-15 10:30:00",
                "latitude": 5.6037,
                "longitude": -0.1870,
                "location": "Accra Central Market",
                "plasticType": {
                    "plasticTypeID": 1,
                    "typeName": "PET",
                    "typeCode": "PET"
                },
                "status": {
                    "statusID": 1,
                    "statusName": "Pending"
                },
                "aggregator": null
            }
        ],
        "statistics": {
            "totalCollections": 45,
            "totalWeight": 385.5,
            "deliveredCollections": 38,
            "deliveredWeight": 325.0,
            "pendingCollections": 7
        },
        "pagination": {
            "total": 45,
            "limit": 20,
            "offset": 0,
            "hasMore": true
        }
    }
}
```

### Aggregators

#### Get Nearest Aggregators
```
GET /aggregators/get_nearest.php
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `latitude` (required): User's latitude
- `longitude` (required): User's longitude
- `radius` (optional): Search radius in km (default: 10)
- `plasticTypeID` (optional): Filter by plastic type

**Response:**
```json
{
    "success": true,
    "message": "Nearest aggregators retrieved successfully",
    "data": {
        "aggregators": [
            {
                "aggregatorID": 3,
                "businessName": "Green Collection Hub",
                "contactPerson": "Ama Osei",
                "contact": "+233244789012",
                "address": "Kaneshie Market",
                "location": {
                    "latitude": 5.6050,
                    "longitude": -0.1900
                },
                "distance": 2.5,
                "rating": 4.2,
                "totalRatings": 15,
                "capacity": 5000.0,
                "pricing": {
                    "plasticTypeID": 1,
                    "plasticType": "PET",
                    "pricePerKg": 4.50
                }
            }
        ],
        "plasticTypes": [
            {
                "plasticTypeID": 1,
                "typeName": "PET",
                "typeCode": "PET",
                "description": "Polyethylene Terephthalate - water bottles, food containers"
            }
        ]
    }
}
```

### Pricing

#### Get Current Prices
```
GET /pricing/get_prices.php
```

**Response:**
```json
{
    "success": true,
    "message": "Pricing data retrieved successfully",
    "data": {
        "pricing": [
            {
                "plasticTypeID": 1,
                "typeName": "PET",
                "typeCode": "PET",
                "aggregators": [
                    {
                        "aggregatorID": 3,
                        "businessName": "Green Collection Hub",
                        "contactPerson": "Ama Osei",
                        "contact": "+233244789012",
                        "rating": 4.2,
                        "totalRatings": 15,
                        "pricePerKg": 4.50,
                        "updatedAt": "2024-03-15 09:00:00"
                    }
                ],
                "priceRange": {
                    "min": 4.20,
                    "max": 5.20,
                    "average": 4.70
                },
                "aggregatorCount": 2,
                "trend": [
                    {
                        "date": "2024-03-14",
                        "avgPrice": 4.65
                    },
                    {
                        "date": "2024-03-15",
                        "avgPrice": 4.70
                    }
                ],
                "change": {
                    "percentage": 1.08,
                    "direction": "up"
                }
            }
        ],
        "lastUpdated": "2024-03-15 10:30:00",
        "currency": "GHS",
        "unit": "per kg"
    }
}
```

### Earnings

#### Get Earnings
```
GET /payments/get_earnings.php
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `startDate` (optional): Filter earnings from this date (YYYY-MM-DD)
- `endDate` (optional): Filter earnings until this date (YYYY-MM-DD)
- `limit` (optional): Number of results per page (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
    "success": true,
    "message": "Earnings data retrieved successfully",
    "data": {
        "earnings": [
            {
                "paymentID": 101,
                "amount": 38.25,
                "platformFee": 0.39,
                "grossAmount": 38.64,
                "paymentMethod": "Mobile Money",
                "mobileMoneyNumber": "+233244123456",
                "referenceNumber": "TXN123456",
                "paidAt": "2024-03-15 14:30:00",
                "createdAt": "2024-03-15 14:30:00",
                "collection": {
                    "collectionID": 123,
                    "weight": 8.5,
                    "collectionDate": "2024-03-15 10:30:00",
                    "plasticType": {
                        "typeName": "PET",
                        "typeCode": "PET"
                    }
                },
                "aggregatorName": "Green Collection Hub"
            }
        ],
        "summary": {
            "totalTransactions": 38,
            "totalEarnings": 1450.75,
            "totalGrossEarnings": 1465.41,
            "totalPlatformFees": 14.66,
            "totalWeightDelivered": 325.0,
            "today": {
                "transactions": 2,
                "earnings": 85.50
            },
            "thisWeek": {
                "transactions": 12,
                "earnings": 425.25
            },
            "thisMonth": {
                "transactions": 38,
                "earnings": 1450.75
            }
        },
        "earningsByType": [
            {
                "plasticType": {
                    "typeName": "PET",
                    "typeCode": "PET"
                },
                "transactionCount": 20,
                "totalEarnings": 850.50,
                "totalWeight": 170.1,
                "avgEarningPerTransaction": 42.53
            }
        ],
        "currency": "GHS",
        "filter": {
            "startDate": "2024-03-01",
            "endDate": "2024-03-15"
        }
    }
}
```

### User Profile

#### Update Profile
```
PUT /user/update_profile.php
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
    "userName": "John Updated",
    "userContact": "+233244789012",
    "address": "New Address, Accra",
    "latitude": 5.6037,
    "longitude": -0.1870,
    "userEmail": "johnupdated@example.com",
    "userPassword": "newpassword123"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Profile updated successfully",
    "data": {
        "user": {
            "userID": 1,
            "userName": "John Updated",
            "userEmail": "johnupdated@example.com",
            "userContact": "+233244789012",
            "userRole": "Waste Collector",
            "status": "active",
            "latitude": 5.6037,
            "longitude": -0.1870,
            "address": "New Address, Accra",
            "rating": 4.5,
            "totalRatings": 12,
            "subscription_status": "free",
            "subscription_expires": null,
            "createdAt": "2024-03-01 10:00:00"
        }
    }
}
```

## Error Codes

- **200**: Success
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **405**: Method Not Allowed
- **409**: Conflict
- **422**: Validation Error
- **500**: Internal Server Error

## Plastic Types

| ID | Type Code | Description |
|----|-----------|-------------|
| 1  | HDPE      | High-Density Polyethylene - bottles, containers |
| 2  | PET       | Polyethylene Terephthalate - water bottles, food containers |
| 3  | PVC       | Polyvinyl Chloride - pipes, packaging |
| 4  | LDPE      | Low-Density Polyethylene - bags, films |
| 5  | PP        | Polypropylene - containers, caps |

## Collection Status

| ID | Status     | Description |
|----|------------|-------------|
| 1  | Pending    | Collection submitted, waiting for aggregator acceptance |
| 2  | Accepted   | Aggregator has accepted the collection |
| 3  | Rejected   | Aggregator has rejected the collection |
| 4  | Delivered  | Collection has been delivered and paid for |

## Testing

Use tools like Postman or curl to test the API endpoints. Make sure to:

1. Update the database configuration in `config/database.php`
2. Use the correct base URL for your server
3. Include proper authentication tokens for protected endpoints
4. Validate request data before sending

## Security Notes

- All passwords are hashed using PHP's `password_hash()` function
- JWT tokens expire after 24 hours
- Input validation and sanitization is implemented
- SQL injection prevention using prepared statements
- CORS headers are configured for cross-origin requests
