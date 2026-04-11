import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
<<<<<<< HEAD
import 'api_service.dart';
import 'dashboard_page.dart';
import 'notification.dart';
import 'offline_storage.dart';
=======
import 'contact_utils.dart';
>>>>>>> aba38a0e9b5c188f2c7b1f126409da3e0730f20a

/// Same pattern as web `views/collector/submit_waste.php`: typeName, GH₵/kg from DB, then description.
String _plasticTypeDropdownLabel(
  Map<String, dynamic> type, {
  int? aggregatorId,
}) {
  final typeName = type['typeName']?.toString() ?? '';
  final description = type['description']?.toString().trim() ?? '';
  final dynamic rawPrice = type['pricePerKg'];
  final hasAggregator = aggregatorId != null && aggregatorId > 0;

  final parts = <String>[typeName];
  if (hasAggregator) {
    if (rawPrice != null && rawPrice is num) {
      parts.add('GH₵${rawPrice.toDouble().toStringAsFixed(2)}/kg');
    } else {
      parts.add('(No pricing set)');
    }
  }
  if (description.isNotEmpty) {
    parts.add(description);
  }
  return parts.join(' - ');
}

/// Aggregator info + per-kg prices, then opens [WasteTypePage] (in-app only, no calls).
class AggregatorDetailPage extends StatefulWidget {
  const AggregatorDetailPage({
    super.key,
    required this.aggregatorId,
    required this.businessName,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final int aggregatorId;
  final String businessName;
  final String address;
  final double? latitude;
  final double? longitude;

  @override
  State<AggregatorDetailPage> createState() => _AggregatorDetailPageState();
}

class _AggregatorDetailPageState extends State<AggregatorDetailPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _types = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await ApiService.getPlasticTypes(
        aggregatorId: widget.aggregatorId,
      );
      if (!mounted) return;
      setState(() {
        _types = types;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Aggregator & prices',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.businessName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.address,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Prices are set by the aggregator. Submit through the app only — '
                            'no calls or direct negotiation.',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  const Text(
                    'Pricing per kg at this site',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._types.map((t) {
                    final name = t['typeName']?.toString() ?? '';
                    final desc = t['description']?.toString() ?? '';
                    final p = t['pricePerKg'];
                    final priceStr = p is num
                        ? 'GH₵${p.toDouble().toStringAsFixed(2)}/kg'
                        : '(No pricing set)';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$priceStr${desc.isNotEmpty ? '\n$desc' : ''}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: widget.aggregatorId <= 0
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WasteTypePage(
                                    aggregatorName: widget.businessName,
                                    aggregatorAddress: widget.address,
                                    aggregatorId: widget.aggregatorId,
                                    latitude: widget.latitude,
                                    longitude: widget.longitude,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Open waste submission form',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// location page for getting user location and selecting aggregators
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool _locationPermissionGranted = false;
  bool _isLoading = false;
  String _locationStatus = 'Location not requested';
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _aggregators = [];

  Future<void> _requestAllPermissions() async {
    try {
      if (!kIsWeb) {
        // Request location permissions first (Android only)
        await [
          Permission.location,
          Permission.locationWhenInUse,
          Permission.locationAlways,
        ].request();

        // Request camera and storage permissions (Android only)
        await [
          Permission.camera,
          Permission.storage,
        ].request();
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

   Future<void> _requestLocationPermission() async {
  setState(() {
    _isLoading = true;
    _locationStatus = 'Requesting location permission...';
  });

  try {
    // On Android, request permissions manually first
    if (!kIsWeb) {
      await Permission.location.request();
      await Permission.locationWhenInUse.request();
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showNotification(context, 'Location Services Disabled',
          kIsWeb
              ? 'Please enable location in your browser settings.'
              : 'Please enable GPS in your phone settings.',
          isError: true);
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location services disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showNotification(
        context,
        'Location Permission Required',
        kIsWeb
            ? 'Click the lock 🔒 in browser address bar → Location → Allow.'
            : 'Please enable location permission in your phone App Settings.',
        isError: true,
      );
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location permission denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

<<<<<<< HEAD
    setState(() {
      _locationPermissionGranted = true;
      _isLoading = false;
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationStatus =
          'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });

    await _loadNearestAggregators();

    _showNotification(context, 'Location Obtained',
        'Your location has been successfully obtained.',
        isError: false);

  } catch (e) {
    setState(() {
      _isLoading = false;
      _locationStatus = 'Error getting location';
    });
    _showNotification(context, 'Location Error',
        'Failed to get location. Please check your settings.',
        isError: true);
  }
}

  Future<void> _loadNearestAggregators() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final items = await ApiService.getNearestAggregators(
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      setState(() {
        _aggregators = items;
      });
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        context,
        'Unable to load aggregators',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
=======
  Future<void> _requestAllPermissions() async {
    try {
      if (!kIsWeb) {
        // Request location permissions first (Android only)
        await [
          Permission.location,
          Permission.locationWhenInUse,
          Permission.locationAlways,
        ].request();

        // Request camera and storage permissions (Android only)
        await [
          Permission.camera,
          Permission.storage,
        ].request();
      }
    } catch (e) {
      print('Permission request error: $e');
>>>>>>> aba38a0e9b5c188f2c7b1f126409da3e0730f20a
    }
  }

   Future<void> _requestLocationPermission() async {
  setState(() {
    _isLoading = true;
    _locationStatus = 'Requesting location permission...';
  });

  try {
    // On Android, request permissions manually first
    if (!kIsWeb) {
      await Permission.location.request();
      await Permission.locationWhenInUse.request();
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showNotification(context, 'Location Services Disabled',
          kIsWeb
              ? 'Please enable location in your browser settings.'
              : 'Please enable GPS in your phone settings.',
          isError: true);
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location services disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showNotification(
        context,
        'Location Permission Required',
        kIsWeb
            ? 'Click the lock 🔒 in browser address bar → Location → Allow.'
            : 'Please enable location permission in your phone App Settings.',
        isError: true,
      );
      setState(() {
        _isLoading = false;
        _locationStatus = 'Location permission denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _locationPermissionGranted = true;
      _isLoading = false;
      _locationStatus =
          'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });

    _showNotification(context, 'Location Obtained',
        'Your location has been successfully obtained.',
        isError: false);

  } catch (e) {
    setState(() {
      _isLoading = false;
      _locationStatus = 'Error getting location';
    });
    _showNotification(context, 'Location Error',
        'Failed to get location. Please check your settings.',
        isError: true);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Get Location',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Get location
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 1: Get Your Location',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Text(
                      'First, click the button below to share your current location. This helps us find the nearest aggregators.',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                      _isLoading ? null : _requestLocationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Colors.white))),
                          SizedBox(width: 12),
                          Text('Getting Location...'),
                        ],
                      )
                          : const Text('Get My Location',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_locationStatus,
                      style: TextStyle(
                          color: _locationPermissionGranted
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                          fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step 2: Select aggregator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 2: Select Nearest Aggregator',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Text(
                      'Here are the nearest aggregators sorted by distance. You can call or SMS them, or tap "Select & Go".',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),
                  if (_locationPermissionGranted)
                    _buildAggregatorList()
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Icon(Icons.location_off,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Enable location to see nearest aggregators',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAggregatorList() {
    if (_aggregators.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No nearby aggregators found for your current location.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return Column(
      children: _aggregators.map((aggregator) {
        final businessName =
            (aggregator['businessName'] ?? aggregator['contactPerson'] ?? 'Aggregator')
                .toString();
        final address = (aggregator['address'] ?? 'No address').toString();
        final distance = aggregator['distance']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name, address, contact, distance
                Text(businessName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(address,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(distance.isEmpty ? '' : '$distance km',
                    style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AggregatorDetailPage(
                            aggregatorId:
                                (aggregator['aggregatorID'] ?? 0) as int,
                            businessName: businessName,
                            address: address,
                            latitude: _latitude,
                            longitude: _longitude,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.price_change_outlined, size: 20),
                    label: const Text('View details & prices'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showNotification(BuildContext context, String title, String message,
      {required bool isError}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          backgroundColor:
          isError ? Colors.red.shade50 : Colors.green.shade50,
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'))
          ],
        );
      },
    );
  }
}

// ─── AGGREGATORS PAGE ──────────────────────────────────────
class AggregatorsPage extends StatelessWidget {
  const AggregatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> aggregators = [
      {'name': 'EcoRecycle Ghana', 'location': 'Accra', 'contact': '+233555123456', 'rating': 4.8, 'active': true},
      {'name': 'Green Solutions Ltd', 'location': 'Kumasi', 'contact': '+233544987654', 'rating': 4.5, 'active': true},
      {'name': 'Plastic Recovery Co', 'location': 'Tema', 'contact': '+233244567890', 'rating': 4.2, 'active': false},
      {'name': 'Sustainable Waste Mgt', 'location': 'Takoradi', 'contact': '+233208765432', 'rating': 4.6, 'active': true},
      {'name': 'uwdb', 'location': 'University Area', 'contact': '+23354827397', 'rating': 4.9, 'active': true},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('All Aggregators',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Available Aggregators',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          ...aggregators.map((aggregator) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.business,
                              color: Colors.green.shade600),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(aggregator['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14,
                                      color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(aggregator['location'],
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.star,
                                      size: 14,
                                      color: Colors.orange.shade600),
                                  const SizedBox(width: 4),
                                  Text(aggregator['rating'].toString(),
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: aggregator['active']
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            aggregator['active'] ? 'Active' : 'Inactive',
                            style: TextStyle(
                                color: aggregator['active']
                                    ? Colors.green.shade800
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Use “♻️ Upload Plastic Waste” on the dashboard to find '
                      'subscribed aggregators by GPS and submit in-app (no calls).',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── WASTE TYPE PAGE ───────────────────────────────────────
class WasteTypePage extends StatefulWidget {
  final String aggregatorName;
  final String aggregatorAddress;
  final int aggregatorId;
  final double? latitude;
  final double? longitude;

  const WasteTypePage({
    super.key,
    required this.aggregatorName,
    required this.aggregatorAddress,
    required this.aggregatorId,
    this.latitude,
    this.longitude,
  });

  @override
  State<WasteTypePage> createState() => _WasteTypePageState();
}

class _WasteTypePageState extends State<WasteTypePage> {
  int? _selectedPlasticTypeId;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _plasticTypes = [];
  bool _locationCaptured = false;
  double? _capturedLatitude;
  double? _capturedLongitude;
  final List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightChanged);
    _loadPlasticTypes();
    _locationController.text = widget.aggregatorAddress;
  }

  void _onWeightChanged() => setState(() {});

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _weightController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _unitPriceForSelectedType() {
    final id = _selectedPlasticTypeId;
    if (id == null) return null;
    for (final t in _plasticTypes) {
      if (t['plasticTypeID'] == id) {
        final p = t['pricePerKg'];
        if (p is num) return p.toDouble();
        return null;
      }
    }
    return null;
  }

  String? _selectedPlasticTypeName() {
    final id = _selectedPlasticTypeId;
    if (id == null) return null;
    for (final t in _plasticTypes) {
      final tid = t['plasticTypeID'];
      final match = tid == id || (tid is num && tid.toInt() == id);
      if (match) return t['typeName']?.toString();
    }
    return null;
  }

  bool _isLikelyOfflineError(Object e) {
    if (e is SocketException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('timed out') ||
        s.contains('clientexception') ||
        s.contains('connection reset');
  }

  Future<void> _loadPlasticTypes() async {
    try {
      final types = await ApiService.getPlasticTypes(
        aggregatorId: widget.aggregatorId,
      );
      if (!mounted) return;
      setState(() {
        _plasticTypes = types;
      });
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        context,
        'Could not load plastic types',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _captureImage() async {
    try {
      if (kIsWeb) {
        _showNotification(context, 'Camera Not Available on Web',
            'Please use the Gallery option to upload photos.',
            isError: true);
        return;
      }
      final picker = ImagePicker();
      final image = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        setState(() => _selectedImages.add(image));
      }
    } catch (_) {
      _showNotification(context, 'Camera Error',
          'Failed to capture photo. Please try again.',
          isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() => _selectedImages.add(image));
      }
    } catch (_) {
      _showNotification(context, 'Gallery Error',
          'Failed to select photo. Please try again.',
          isError: true);
    }
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  Future<void> _captureLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _capturedLatitude = pos.latitude;
        _capturedLongitude = pos.longitude;
        _locationCaptured = true;
        _locationController.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      _showNotification(context, 'Location Captured',
          'Your GPS location has been captured.',
          isError: false);
    } catch (_) {
      _showNotification(context, 'Location Error',
          'Unable to capture GPS location now. Try again.',
          isError: true);
    }
  }

  Future<void> _submitWasteCollection() async {
    String errorMessage = '';
    if (_selectedPlasticTypeId == null) {
      errorMessage = 'Please select a plastic type.';
    } else if (_weightController.text.isEmpty) {
      errorMessage = 'Please enter the weight of your waste.';
    } else {
      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) {
        errorMessage = 'Please enter a valid weight greater than 0.';
      } else if (weight < 5) {
        errorMessage =
        'Sorry, minimum weight required is 5 KG.';
      }
    }
    if (!_locationCaptured) {
      errorMessage = 'Please capture your location at the aggregator site.';
    }
    if (!kIsWeb && _selectedImages.isEmpty) {
      errorMessage =
          'Please add at least one photo as evidence (camera or gallery).';
    }

    if (errorMessage.isNotEmpty || !_formKey.currentState!.validate()) {
      _showNotification(
        context,
        'Required Information Missing',
        errorMessage.isEmpty ? 'Please complete the form correctly.' : errorMessage,
        isError: true,
      );
      return;
    }

    final weight = double.parse(_weightController.text.trim());
    final lat = _capturedLatitude ?? widget.latitude ?? 0;
    final lng = _capturedLongitude ?? widget.longitude ?? 0;
    final loc = _locationController.text.trim();
    final notes = _notesController.text.trim();

    try {
      String photoPath = '';
      if (_selectedImages.isNotEmpty && !kIsWeb) {
        final file = File(_selectedImages.first.path);
        if (await file.exists()) {
          photoPath = await ApiService.uploadCollectionPhoto(file);
        }
      }

      await ApiService.submitCollection(
        plasticTypeId: _selectedPlasticTypeId!,
        weight: weight,
        latitude: lat,
        longitude: lng,
        location: loc,
        notes: notes,
        photoPath: photoPath,
        aggregatorId: widget.aggregatorId,
      );
      if (!kIsWeb) {
        await NotificationService.instance.notifyWasteSubmissionSent(
          weightKg: weight,
          plasticTypeLabel: _selectedPlasticTypeName(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DashboardPage(
            uploadSuccessMessage:
                'Waste submitted successfully! An aggregator will review and accept your delivery.',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!kIsWeb &&
          _isLikelyOfflineError(e) &&
          _selectedImages.isNotEmpty) {
        await OfflineStorageService.enqueuePendingCollection({
          'plasticTypeID': _selectedPlasticTypeId!,
          'plasticTypeName': _selectedPlasticTypeName() ?? '',
          'weight': weight,
          'latitude': lat,
          'longitude': lng,
          'location': loc,
          'notes': notes,
          'aggregatorID': widget.aggregatorId,
          'localPhotoPath': _selectedImages.first.path,
          'createdAt': DateTime.now().toIso8601String(),
        });
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardPage(
              uploadSuccessMessage:
                  'Saved offline. We will send your submission when you are back online.',
            ),
          ),
          (route) => false,
        );
        return;
      }
      _showNotification(
        context,
        'Submission Failed',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Submit Waste',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selected Aggregator',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Business: ${widget.aggregatorName}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Address: ${widget.aggregatorAddress}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    'All communication goes through the app — no calls to the aggregator.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Change aggregator'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Step 3: Submit Waste at Aggregator Location',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(
                      'You selected ${widget.aggregatorName}. Capture your GPS location and submit your waste collection.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedPlasticTypeId,
                      decoration: InputDecoration(
                        labelText: 'Plastic Type *',
                        helperText:
                            '(Select the type of plastic you collected)',
                        hintText: '-- Select plastic type --',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      selectedItemBuilder: (context) {
                        return _plasticTypes.map((type) {
                          final label = _plasticTypeDropdownLabel(
                            type,
                            aggregatorId: widget.aggregatorId,
                          );
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              label,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },
                      items: _plasticTypes.map((type) {
                        final label = _plasticTypeDropdownLabel(
                          type,
                          aggregatorId: widget.aggregatorId,
                        );
                        return DropdownMenuItem<int>(
                          value: type['plasticTypeID'] as int,
                          child: Text(
                            label,
                            softWrap: true,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (int? value) =>
                          setState(() => _selectedPlasticTypeId = value),
                      validator: (value) =>
                      value == null ? 'Please select a waste type' : null,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Minimum weight requirement: 5 KG.',
                              style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg) *',
                        hintText: 'e.g., 25.50',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter weight';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Please enter a valid weight';
                        }
                        if (weight < 5) {
                          return 'Minimum weight is 5 KG';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final unit = _unitPriceForSelectedType();
                        final w =
                            double.tryParse(_weightController.text.trim());
                        final total = (unit != null && w != null && w >= 5)
                            ? unit * w
                            : null;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💰 Estimated payout (aggregator rate × weight)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (unit == null)
                                Text(
                                  'Select a plastic type with a set price to see an estimate.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                )
                              else if (w == null || w < 5)
                                Text(
                                  'Enter weight (≥ 5 kg) to calculate.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                )
                              else if (total != null)
                                Text(
                                  'GH₵${unit.toStringAsFixed(2)}/kg × ${w.toStringAsFixed(2)} kg = '
                                  'GH₵${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade900,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: Use a scale to get accurate weight for better pricing.',
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Current Location at Aggregator *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: TextButton(
                          onPressed: _captureLocation,
                          child: const Text('Capture'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Important: Click "Capture" to verify you are at the aggregator location.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      kIsWeb ? 'Upload Photo (optional on web)' : 'Evidence photo *',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'On mobile, a photo is required before submit.'
                          : 'Required on this device. Max 5MB, JPG/PNG/WEBP.',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${_selectedImages.length} photo(s) selected',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText:
                            'e.g., Clean and sorted, collected from beach cleanup...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'What Happens Next?\n'
                        '• Submit your waste collection with accurate details\n'
                        '• Aggregator reviews and accepts your delivery\n'
                        '• You receive payment after acceptance\n'
                        '• Leave feedback about your experience',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitWasteCollection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Waste Collection at This Location',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotification(BuildContext context, String title, String message,
      {required bool isError}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade50 : Colors.green.shade50,
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }
}

// ─── FINAL SUBMISSION PAGE ─────────────────────────────────
class FinalSubmissionPage extends StatefulWidget {
  final String aggregatorName;
  final String aggregatorAddress;
  final String wasteType;
  final int plasticTypeId;
  final String weight;
  final double? latitude;
  final double? longitude;

  const FinalSubmissionPage({
    super.key,
    required this.aggregatorName,
    required this.aggregatorAddress,
    required this.wasteType,
    required this.plasticTypeId,
    required this.weight,
    this.latitude,
    this.longitude,
  });

  @override
  State<FinalSubmissionPage> createState() => _FinalSubmissionPageState();
}

class _FinalSubmissionPageState extends State<FinalSubmissionPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _locationCaptured = false;
  double? _capturedLatitude;
  double? _capturedLongitude;
  final List<XFile> _selectedImages = [];


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }



  Future<void> _captureImage() async {
    try {
      if (kIsWeb) {
        _showNotification(context, 'Camera Not Available on Web',
            'Please use the Gallery option to upload photos.',
            isError: true);
        return;
      }

      // Check camera permission before accessing camera
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        var result = await Permission.camera.request();
        if (!result.isGranted) {
          _showNotification(context, 'Camera Permission Required',
              'Camera permission is required to take photos. Please enable it in app settings.',
              isError: true);
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        setState(() => _selectedImages.add(image));
        _showNotification(
            context, 'Photo Captured', 'Photo captured successfully.',
            isError: false);
      }
    } catch (e) {
      _showNotification(context, 'Camera Error',
          'Failed to capture photo: ${e.toString()}',
          isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Check storage permission before accessing gallery
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        var result = await Permission.storage.request();
        if (!result.isGranted) {
          _showNotification(context, 'Storage Permission Required',
              'Storage permission is required to access photos. Please enable it in app settings.',
              isError: true);
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() => _selectedImages.add(image));
        _showNotification(
            context, 'Photo Selected', 'Photo selected successfully.',
            isError: false);
      }
    } catch (e) {
      _showNotification(context, 'Gallery Error',
          'Failed to select photo: ${e.toString()}',
          isError: true);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<void> _captureLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _capturedLatitude = pos.latitude;
        _capturedLongitude = pos.longitude;
        _locationCaptured = true;
        _locationController.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      _showNotification(context, 'Location Captured',
          'Your GPS location has been successfully verified.',
          isError: false);
    } catch (_) {
      _showNotification(context, 'Location Error',
          'Unable to capture GPS location now. Try again.',
          isError: true);
    }
  }

  Future<void> _submitWasteCollection() async {
    if (_formKey.currentState!.validate() && _locationCaptured) {
      try {
        await ApiService.submitCollection(
          plasticTypeId: widget.plasticTypeId,
          weight: double.parse(widget.weight),
          latitude: _capturedLatitude ?? widget.latitude ?? 0,
          longitude: _capturedLongitude ?? widget.longitude ?? 0,
          location: _locationController.text,
          notes: _notesController.text.trim(),
        );
        if (!kIsWeb) {
          await NotificationService.instance.notifyWasteSubmissionSent(
            weightKg: double.tryParse(widget.weight),
            plasticTypeLabel: widget.wasteType,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardPage(
              uploadSuccessMessage:
                  'Waste submitted successfully! An aggregator will review and accept your delivery.',
            ),
          ),
          (route) => false,
        );
      } catch (e) {
        _showNotification(
          context,
          'Submission Failed',
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } else if (!_locationCaptured) {
      _showNotification(context, 'Location Required',
          'Please capture your location before submitting.',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Step 3: Submit Waste',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitting to ${widget.aggregatorName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${widget.wasteType}'),
                  Text('Weight: ${widget.weight} KG'),
                  const SizedBox(height: 12),
                  Text(
                    'Complete submission in the app only — no direct calls to the aggregator.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submission form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submit Waste Collection Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 20),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Current Location at Aggregator',
                        hintText: 'Click "Capture Location" to verify',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: ElevatedButton(
                          onPressed: _captureLocation,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white),
                          child: const Text('Capture Location'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click "Capture Location" to verify you are at the aggregator\'s location.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),

                    
                    const SizedBox(height: 20),

                    // Photo buttons
                    const Text('Upload Photo of wastes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('Photos help aggregators verify waste quality',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Image previews
                    if (_selectedImages.isNotEmpty) ...[
                      const Text('Selected Photos:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final image = _selectedImages[index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                  borderRadius:
                                  BorderRadius.circular(8)),
                              child: Stack(
                                children: [
                                  kIsWeb
                                      ? Image.network(image.path,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover)
                                      : Image.file(File(image.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera_outlined,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('No photos selected',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'Any extra information about waste',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitWasteCollection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                            'Submit Waste Collection at This Location',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                '© 2025 WasteJustice. Building a cleaner Ghana together.\nFair • Transparent • Connected',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotification(BuildContext context, String title, String message,
      {required bool isError}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade50 : Colors.green.shade50,
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }
}
