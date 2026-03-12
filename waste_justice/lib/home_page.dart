import 'package:flutter/material.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildWelcomeSection(),
                  _buildFeatureCards(context),
                  _buildHowItWorks(),
                  _buildCallToAction(context),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.green.shade600,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      child: Row(
        children: [
          const Text('🌍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WasteJustice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Fair, Transparent Waste Management in Ghana',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Login'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign up coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.green.shade400, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to WasteJustice',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          Divider(color: Colors.green.shade200, thickness: 1, height: 20),
          const Text(
            'Fair, Transparent, and Connected Waste Management in Ghana',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'WasteJustice is a digital platform that connects waste collectors and recycling '
            'companies to make every transaction transparent, fair, and traceable. Together, '
            "we're building a cleaner, more sustainable Ghana.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildCard(
            icon: '♻️',
            title: 'For Waste Collectors',
            body: 'Track your waste collection, view transparent prices, and get fair compensation for your work.',
            buttonText: 'Register as Collector',
            isPrimary: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Collector registration coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: '🏭',
            title: 'For Recycling Companies',
            body: 'Connect with waste collectors, set fair prices, and build a sustainable supply chain.',
            buttonText: 'Register as Company',
            isPrimary: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company registration coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: '💚',
            title: 'Transparent System',
            body: 'Every transaction is tracked, every price is visible, and every payment is fair.',
            buttonText: 'Login to Dashboard',
            isPrimary: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String icon,
    required String title,
    required String body,
    required String buttonText,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? Colors.green.shade600 : Colors.white,
                foregroundColor: isPrimary ? Colors.white : Colors.black87,
                side: isPrimary ? null : BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {'number': '1', 'title': 'Collect Waste', 'body': 'Waste collectors gather recyclable materials from communities across Ghana.'},
      {'number': '2', 'title': 'Record Transaction', 'body': 'Log waste details in the system including type, weight, and location.'},
      {'number': '3', 'title': 'Connect with Companies', 'body': 'Recycling companies review requests and arrange collection.'},
      {'number': '4', 'title': 'Fair Payment', 'body': 'Transparent pricing ensures collectors receive fair compensation.'},
      {'number': '5', 'title': 'Track Impact', 'body': 'Monitor environmental impact and track waste management progress.'},
      {'number': '6', 'title': 'Build Together', 'body': 'Create a sustainable future through transparent collaboration.'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.green.shade400, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          Divider(color: Colors.green.shade200, thickness: 1, height: 20),
          ...List.generate((steps.length / 2).ceil(), (rowIndex) {
            final left = steps[rowIndex * 2];
            final rightIndex = rowIndex * 2 + 1;
            final right = rightIndex < steps.length ? steps[rightIndex] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStep(left['number']!, left['title']!, left['body']!)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: right != null
                        ? _buildStep(right['number']!, right['title']!, right['body']!)
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. $title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready to Get Started?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Join WasteJustice today and be part of Ghana's waste management revolution.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up coming soon!')),
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
                      'Create Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            '© 2025 WasteJustice. Building a cleaner Ghana together.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Fair • Transparent • Connected',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
