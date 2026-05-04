import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3425),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Introduction',
              content:
                  'Stride Probe ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              title: 'Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Personal Information: Name, email address, and account credentials\n'
                  '• Health Data: Heart rate, heart rate variability (HRV), stress scores, and cognitive test results\n'
                  '• Sensor Data: Accelerometer and gyroscope data during tests\n'
                  '• Usage Data: Test completion times, response times, and accuracy metrics',
            ),
            _buildSection(
              title: 'How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide and maintain our stress assessment services\n'
                  '• Calculate and display your stress scores and health metrics\n'
                  '• Improve and personalize your experience\n'
                  '• Analyze trends and usage patterns\n'
                  '• Communicate with you about your account and services',
            ),
            _buildSection(
              title: 'Data Storage and Security',
              content:
                  'Your data is stored securely using Supabase, a trusted cloud database provider. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              title: 'Data Retention',
              content:
                  'We retain your personal information for as long as your account is active or as needed to provide you services. You may request deletion of your account and associated data at any time by contacting us.',
            ),
            _buildSection(
              title: 'Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Withdraw consent for data processing\n'
                  '• Export your data in a portable format',
            ),
            _buildSection(
              title: 'Third-Party Services',
              content:
                  'We use third-party services for authentication and data storage (Supabase). These services have their own privacy policies governing the use of your information.',
            ),
            _buildSection(
              title: 'Children\'s Privacy',
              content:
                  'Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),
            _buildSection(
              title: 'Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            _buildSection(
              title: 'Contact Us',
              content:
                  'If you have questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: support@strideprobe.com\n'
                  'Website: www.strideprobe.com',
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last Updated: ${_getFormattedDate()}',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF1A0A08).withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B3425),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF1A0A08),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
