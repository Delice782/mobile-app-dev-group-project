
import 'package:flutter/material.dart'; 
import 'package:url_launcher/url_launcher.dart';

class ContactUtils { 
  // Launch phone dialer with number pre-filled 
  static Future<void> makeCall(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context, 'Could not open dialer for $phoneNumber');
    }
  } 
 
  // Launch SMS app with number and optional pre-filled message 
  static Future<void> sendSms(
      BuildContext context, 
      String phoneNumber, {
        String? message,
      }) async { 
    final Uri uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: message != null ? {'body': message} : null,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context, 'Could not open SMS app for $phoneNumber');
    }
  }
 
  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
      ),
    );
  } 
}
 
  
