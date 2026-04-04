  
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
>>>>>>> 09ed1922cd54e8bd2985e91a58f167f273c9c766
import 'login_page.dart';
import 'pages.dart';
import 'home_page.dart';
import 'notification.dart';
import 'offline_storage.dart';

// background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background notification received: ${message.notification?.title}');
}

// main entry point for the WasteJustice application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('wasteJusticeBox');

  // initialize notification service
  await NotificationService().init();

  runApp(const WasteJusticeApp());
}

// root widget of the WasteJustice application
class WasteJusticeApp extends StatelessWidget {
  const WasteJusticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteJustice',
      theme: ThemeData(
        // use green color scheme to match the waste management theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// dashboard page showing waste collection statistics and upload functionality
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // minimum weight requirement for waste uploads in KG
  static const double minimumWeightKG = 5.0;

  // controllers for form inputs
  final TextEditingController _weightController = TextEditingController();

  // dashboard statistics - these will be dynamic from database
  double totalEarnings = 45000.0; // UGX
  int totalDeliveries = 12;

  // form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // current selected tab
  int _selectedTab = 1; // Start with Prices tab (index 1)

  // plastic prices data - this will come from database
  final Map<String, Map<String, dynamic>> _plasticPrices = {
    'PET': {'price': 1200, 'change': 5, 'description': 'Water bottles'},
    'HDPE': {'price': 1000, 'change': 0, 'description': 'Milk jugs'},
    'LDPE': {'price': 800, 'change': -2, 'description': 'Shopping bags'},
    'PP': {'price': 900, 'change': 3, 'description': 'Yogurt containers'},
    'Mixed': {'price': 600, 'change': 0, 'description': 'Mixed plastics'},
  };

  // method to handle waste upload with weight validation
  void _uploadWaste() async {
    if (_formKey.currentState!.validate()) {
      final double weight = double.parse(_weightController.text);

      // check if weight is below minimum requirement
      if (weight < minimumWeightKG) {
        _showNotification(
          'Weight Below Minimum',
          'The minimum weight for upload is ${minimumWeightKG.toStringAsFixed(1)} KG. '
              'Current weight: ${weight.toStringAsFixed(1)} KG.',
          isError: true,
        );
        return;
      }

      // save request offline first (works even without internet)
      await OfflineStorageService.saveRequest({
        'weight': weight,
        'type': 'Mixed',
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // simulate successful upload
      _showNotification(
        'Upload Successful',
        'Waste of ${weight.toStringAsFixed(1)} KG has been saved. It will sync when connected.',
        isError: false,
      );

      // update dashboard statistics
      setState(() {
        totalDeliveries++;
        totalEarnings += weight * 1000;
      });

      // clear the form
      _weightController.clear();
    }
  }

  // method to display notifications to the user
  void _showNotification(String title, String message,
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
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'WasteJustice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          // login / account icon - leads to login page
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
          // hamburger menu icon
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // statistics cards section
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    'UGX ${totalEarnings.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Deliveries',
                    totalDeliveries.toString(),
                    Icons.local_shipping,
                    Colors.orange.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // interactive action buttons section
            Row(
              children: [
                Expanded(
                    child: _buildInteractiveActionButton('Upload', Icons.upload, 0)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInteractiveActionButton(
                        'Prices', Icons.price_check, 1)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInteractiveActionButton(
                        'Buyers', Icons.people, 2)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInteractiveActionButton(
                        'Earnings', Icons.trending_up, 3)),
              ],
            ),

            const SizedBox(height: 32),

            // dynamic content based on selected tab
            _buildSelectedTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveActionButton(
      String label, IconData icon, int tabIndex) {
    bool isSelected = _selectedTab == tabIndex;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade600 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _selectedTab = tabIndex;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                isSelected ? Colors.white : Colors.green.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildUploadNavigationContent();
      case 1:
        return _buildPricesContent();
      case 2:
        return _buildBuyersNavigationContent();
      case 3:
        return _buildEarningsContent();
      default:
        return _buildUploadNavigationContent();
    }
  }

  Widget _buildUploadNavigationContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit Waste',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start the waste submission process by getting your location and selecting the nearest aggregator.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LocationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Waste Submission',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyersNavigationContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Aggregators',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'View all available waste aggregators in your area and their contact information.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AggregatorsPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View All Aggregators',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prices',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prices updated daily. Check back for the best rates!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ..._plasticPrices.entries.map((entry) {
            final String type = entry.key;
            final Map<String, dynamic> data = entry.value;
            final double price = data['price'].toDouble();
            final int change = data['change'];
            final String description = data['description'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$type ($description)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('UGX ${price.toStringAsFixed(0)}/kg',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: change >= 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        change >= 0 ? '+$change%' : '$change%',
                        style: TextStyle(
                          color: change >= 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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

<<<<<<< HEAD
  // buyers tab content
  Widget _buildBuyersContent() {
    final List<Map<String, dynamic>> buyers = [
      {'name': 'EcoRecycle Ghana', 'location': 'Accra', 'rating': 4.8, 'active': true},
      {'name': 'Green Solutions Ltd', 'location': 'Kumasi', 'rating': 4.5, 'active': true},
      {'name': 'Plastic Recovery Co', 'location': 'Tema', 'rating': 4.2, 'active': false},
      {'name': 'Sustainable Waste Mgt', 'location': 'Takoradi', 'rating': 4.6, 'active': true},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buyers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // buyers list
          ...buyers.map((buyer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.business, color: Colors.green.shade600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyer['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                buyer['location'],
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.star, size: 14, color: Colors.orange.shade600),
                              const SizedBox(width: 4),
                              Text(
                                buyer['rating'].toString(),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: buyer['active'] ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        buyer['active'] ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: buyer['active'] ? Colors.green.shade800 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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

  // earnings tab content
=======
>>>>>>> 09ed1922cd54e8bd2985e91a58f167f273c9c766
  Widget _buildEarningsContent() {
    final List<Map<String, dynamic>> earnings = [
      {'date': '2024-03-12', 'weight': 8.5, 'amount': 8500, 'type': 'PET'},
      {'date': '2024-03-11', 'weight': 6.2, 'amount': 6200, 'type': 'HDPE'},
      {'date': '2024-03-10', 'weight': 12.0, 'amount': 12000, 'type': 'Mixed'},
      {'date': '2024-03-09', 'weight': 5.5, 'amount': 5500, 'type': 'LDPE'},
      {'date': '2024-03-08', 'weight': 7.8, 'amount': 7800, 'type': 'PP'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 20),
          ...earnings.map((earning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(earning['date'],
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${earning['weight']} kg ${earning['type']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                    Text(
                      'UGX ${earning['amount'].toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600),
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

// menu page for hamburger menu navigation
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Menu',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content:
                    const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade600,
                  child: const Icon(Icons.person,
                      size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Waste Collector',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('collector@wastejustice.com',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.pop(context)),
          _buildMenuItem(context,
              icon: Icons.login,
              title: 'Login',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage()))),
          _buildMenuItem(context,
              icon: Icons.history,
              title: 'History',
              onTap: () => _showNotification(context, 'History Page',
                  'View your waste collection history.',
                  isError: false)),
          _buildMenuItem(context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => _showNotification(context, 'Settings Page',
                  'Manage your app settings.',
                  isError: false)),
          _buildMenuItem(context,
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () => _showNotification(context,
                  'Help & Support', 'Get support here.',
                  isError: false)),
          _buildMenuItem(context,
              icon: Icons.info,
              title: 'About',
              onTap: () => _showNotification(
                  context, 'About', 'WasteJustice app v1.0.0',
                  isError: false)),
          const SizedBox(height: 32),
          Center(
            child: Text('WasteJustice v1.0.0',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500))),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotification(BuildContext context, String title,
      String message,
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
