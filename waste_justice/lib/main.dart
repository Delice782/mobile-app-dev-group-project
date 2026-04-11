  
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'login_page.dart';
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

  try {
    // initialize Firebase only on secure contexts or mobile
    if (kIsWeb) {
      print('Running on web - Firebase may not work without HTTPS');
      // Skip Firebase on HTTP web to prevent errors
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue with app initialization even if Firebase fails
  }

  // initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('wasteJusticeBox');

  try {
    // initialize notification service only on mobile or secure web
    if (!kIsWeb) {
<<<<<<< HEAD
      await NotificationService.instance.init();
=======
      await NotificationService().init();
>>>>>>> aba38a0e9b5c188f2c7b1f126409da3e0730f20a
    } else {
      print('Notifications disabled on HTTP web - requires HTTPS');
    }
  } catch (e) {
    print('Notification service initialization error: $e');
    // Continue with app initialization even if notifications fail
  }

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
                        onPressed: () async {
                          await OfflineStorageService.clearUserCredentials();
                          if (!context.mounted) return;
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

