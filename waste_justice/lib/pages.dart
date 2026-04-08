import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'contact_utils.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'services/vibration_service.dart';
import 'widgets/mic_button.dart';


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

  Future<void> _requestAllPermissions() async {
    try {
      // Request location permissions first
      await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.locationAlways,
      ].request();

      // Request microphone permission for speech-to-text
      await Permission.microphone.request();

      // Request other permissions if needed
      await [
        Permission.camera,
        Permission.storage,
      ].request();
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _locationStatus = 'Requesting location permission...';
    });

    // Request all permissions at once to prevent resets
    await _requestAllPermissions();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showNotification(context, 'Location Services Disabled',
            'Please enable GPS/Location in your phone settings and try again.',
            isError: true);
        setState(() {
          _isLoading = false;
          _locationStatus = 'GPS/Location services disabled - enable in phone settings';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showNotification(context, 'Permission Denied',
              'Location permission is required to find nearest aggregators.',
              isError: true);
          setState(() {
            _isLoading = false;
            _locationStatus = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showNotification(context, 'Permission Permanently Denied',
            'Please enable location permission in app settings.',
            isError: true);
        setState(() {
          _isLoading = false;
          _locationStatus = 'Location permission permanently denied';
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
        'Location obtained: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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
          'Failed to get your location. Please try again.',
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
    final List<Map<String, dynamic>> aggregators = [
      {
        'name': 'uwdb',
        'address': '1 University Avenue',
        'contact': '+23354827397',
        'distance': '0.5 km',
        'active': true,
      },
      {
        'name': 'EcoRecycle Ghana',
        'address': '12 Industrial Area',
        'contact': '+233555123456',
        'distance': '2.3 km',
        'active': true,
      },
      {
        'name': 'Green Solutions Ltd',
        'address': '8 Market Street',
        'contact': '+233544987654',
        'distance': '3.7 km',
        'active': false,
      },
    ];

    return Column(
      children: aggregators.map((aggregator) {
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
                Text(aggregator['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(aggregator['address'],
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(aggregator['contact'],
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(aggregator['distance'],
                    style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),

                const SizedBox(height: 12),

                // ── ACTION BUTTONS ──────────────────────────
                Row(
                  children: [
                    // Call button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ContactUtils.makeCall(
                            context, aggregator['contact']),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // SMS button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ContactUtils.sendSms(
                          context,
                          aggregator['contact'],
                          message:
                          'Hi, I have waste ready for collection at your location.',
                        ),
                        icon: const Icon(Icons.sms, size: 16),
                        label: const Text('SMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Select & Go button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: aggregator['active']
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WasteTypePage(
                                aggregatorName: aggregator['name'],
                                aggregatorAddress:
                                aggregator['address'],
                                aggregatorContact:
                                aggregator['contact'],
                              ),
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aggregator['active']
                              ? Colors.green.shade600
                              : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Select',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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

                    const SizedBox(height: 12),

                    // ── CALL + SMS BUTTONS ──────────────────
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ContactUtils.makeCall(
                                context, aggregator['contact']),
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ContactUtils.sendSms(
                              context,
                              aggregator['contact'],
                              message:
                              'Hi, I have waste ready for collection.',
                            ),
                            icon: const Icon(Icons.sms, size: 16),
                            label: const Text('SMS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
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
  final String aggregatorContact; // ← new param

  const WasteTypePage({
    super.key,
    required this.aggregatorName,
    required this.aggregatorAddress,
    required this.aggregatorContact,
  });

  @override
  State<WasteTypePage> createState() => _WasteTypePageState();
}

class _WasteTypePageState extends State<WasteTypePage> {
  String? _selectedWasteType;
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _wasteTypes = [
    'PET (Water bottles)',
    'HDPE (Milk jugs)',
    'LDPE (Shopping bags)',
    'PP (Yogurt containers)',
    'Mixed plastics',
  ];

  void _proceedToFinalStep() {
    String errorMessage = '';
    if (_selectedWasteType == null || _selectedWasteType!.isEmpty) {
      errorMessage = 'Please select a waste type to proceed.';
    } else if (_weightController.text.isEmpty) {
      errorMessage = 'Please enter the weight of your waste to proceed.';
    } else {
      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) {
        errorMessage = 'Please enter a valid weight greater than 0.';
      } else if (weight < 25) {
        errorMessage =
        'Sorry, minimum weight required is 25 KG. Please enter at least 25 KG to proceed.';
      }
    }

    if (errorMessage.isEmpty && _formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalSubmissionPage(
            aggregatorName: widget.aggregatorName,
            aggregatorAddress: widget.aggregatorAddress,
            aggregatorContact: widget.aggregatorContact, // ← pass through
            wasteType: _selectedWasteType!,
            weight: _weightController.text,
          ),
        ),
      );
    } else {
      _showNotification(context, 'Required Information Missing', errorMessage,
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Select Waste Type',
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
                  Text(widget.aggregatorName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(widget.aggregatorAddress,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 12),
                  // Quick call/sms from this page too
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => ContactUtils.makeCall(
                            context, widget.aggregatorContact),
                        icon: const Icon(Icons.phone, size: 14),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => ContactUtils.sendSms(
                          context,
                          widget.aggregatorContact,
                          message:
                          'Hi, I am on my way with waste for collection.',
                        ),
                        icon: const Icon(Icons.sms, size: 14),
                        label: const Text('SMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
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
                    const Text('Waste Information',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedWasteType,
                      decoration: InputDecoration(
                        labelText: 'Select Plastic Type',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: _wasteTypes.map((String type) {
                        return DropdownMenuItem<String>(
                            value: type, child: Text(type));
                      }).toList(),
                      onChanged: (String? value) =>
                          setState(() => _selectedWasteType = value),
                      validator: (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please select a waste type'
                          : null,
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
                              'Minimum weight requirement: 25 KG.',
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
                        labelText: 'Weight (KG)',
                        hintText: 'Minimum: 25 KG',
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
                        if (weight < 25) {
                          return 'Minimum weight is 25 KG';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _proceedToFinalStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Proceed to Final Step',
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
  final String aggregatorContact; // ← new param
  final String wasteType;
  final String weight;

  const FinalSubmissionPage({
    super.key,
    required this.aggregatorName,
    required this.aggregatorAddress,
    required this.aggregatorContact,
    required this.wasteType,
    required this.weight,
  });

  @override
  State<FinalSubmissionPage> createState() => _FinalSubmissionPageState();
}

class _FinalSubmissionPageState extends State<FinalSubmissionPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _locationCaptured = false;
  final List<XFile> _selectedImages = [];

  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final VibrationService _vibrationService = VibrationService();
  String _liveSpeech = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speechService.initialize());
      unawaited(_ttsService.initialize());
    });
  }

  @override
  void dispose() {
    unawaited(_speechService.dispose());
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final ok = await _speechService.initialize();
    if (!mounted) return;
    if (!ok) {
      await _vibrationService.errorPattern();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone or speech recognition is not available. Check permissions in Settings.',
          ),
        ),
      );
      return;
    }

    await _speechService.toggleListening(
      onResult: (text, _) {
        if (!mounted) return;
        setState(() => _liveSpeech = text);
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _processVoiceInput() async {
    final spoken = _liveSpeech.trim();
    if (spoken.isEmpty) {
      await _vibrationService.errorPattern();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No speech heard yet. Tap the mic and speak, then try again.'),
        ),
      );
      return;
    }

    final existing = _notesController.text.trim();
    _notesController.text =
        existing.isEmpty ? spoken : '$existing\n$spoken';

    await _vibrationService.successPulse();
    if (!mounted) return;
    await _ttsService.speakWasteRecordedSuccess();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _captureImage() async {
    try {
      if (kIsWeb) {
        _showNotification(context, 'Camera Not Available on Web',
            'Please use the Gallery option to upload photos.',
            isError: true);
        return;
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

  void _captureLocation() {
    setState(() {
      _locationCaptured = true;
      _locationController.text =
      'Location captured: ${DateTime.now().toString().substring(0, 19)}';
    });
    _showNotification(context, 'Location Captured',
        'Your location has been successfully verified.',
        isError: false);
  }

  void _submitWasteCollection() {
    if (_formKey.currentState!.validate() && _locationCaptured) {
      _showNotification(context, 'Submission Successful',
          'Your waste collection has been submitted successfully!',
          isError: false);
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
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

                  const SizedBox(height: 16),

                  // ── CALL + SMS AGGREGATOR ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ContactUtils.makeCall(
                              context, widget.aggregatorContact),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call Aggregator'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ContactUtils.sendSms(
                            context,
                            widget.aggregatorContact,
                            message:
                            'I am at your location with ${widget.weight}kg of ${widget.wasteType}.',
                          ),
                          icon: const Icon(Icons.sms, size: 16),
                          label: const Text('SMS Aggregator'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
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

                    const Text(
                      'Voice input',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the microphone and speak the waste details (e.g., 2 plastic, 1 organic). '
                      'If you prefer voice instead of typing, use the microphone.',
                      style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: MicButton(
                        isListening: _speechService.isListening,
                        onPressed: _toggleMic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _liveSpeech.isEmpty ? '… listening text appears here' : _liveSpeech,
                      style: TextStyle(
                        fontSize: 14,
                        color: _liveSpeech.isEmpty ? Colors.grey.shade500 : Colors.black87,
                        fontStyle:
                            _liveSpeech.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _processVoiceInput,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Process'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
