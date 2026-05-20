import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../widget/custom_button.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0A08),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please read carefully',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.primary,
                        size: 28,
                      ),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Purpose
                      _buildSection(
                        title: 'App Purpose',
                        content:
                            'Stride Probe is a stress assessment application that measures physiological and cognitive stress through multiple tests and sensors. The app collects data to provide you with personalized stress insights and recommendations.',
                      ),

                      const SizedBox(height: 24),

                      // Data Collection
                      _buildSection(
                        title: 'Data We Collect',
                        content:
                            'To provide accurate stress assessments, we collect the following data:',
                        children: [
                          _buildListItem('Heart Rate (PPG via camera/sensor)'),
                          _buildListItem('Activity Level (steps, movement patterns)'),
                          _buildListItem('Typing Speed & Interaction Patterns'),
                          _buildListItem('Response Time during cognitive tests'),
                          _buildListItem('Error Rate in cognitive tasks'),
                          _buildListItem('Accelerometer data (movement detection)'),
                          _buildListItem('Gyroscope data (orientation & motion)'),
                          _buildListItem('WHO-5 Well-being Questionnaire responses'),
                          _buildListItem('Perceived Stress Scale (PSS) responses'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // How We Use Your Data
                      _buildSection(
                        title: 'How We Use Your Data',
                        content:
                            'Your data is used exclusively for:',
                        children: [
                          _buildListItem('Calculating your stress score using our 7-component model'),
                          _buildListItem('Providing personalized stress insights'),
                          _buildListItem('Generating weekly progress reports'),
                          _buildListItem('Improving the accuracy of our stress assessment algorithms'),
                          _buildListItem('Research purposes (anonymized and aggregated only)'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Data Security
                      _buildSection(
                        title: 'Data Security & Privacy',
                        content:
                            'We take your privacy seriously:',
                        children: [
                          _buildListItem('All data is encrypted during transmission and storage'),
                          _buildListItem('We use secure Supabase backend with enterprise-grade security'),
                          _buildListItem('Your personal information is never shared with third parties'),
                          _buildListItem('You can request data deletion at any time by contacting support'),
                          _buildListItem('Data is stored for research purposes for up to 2 years, after which it is anonymized'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // User Responsibilities
                      _buildSection(
                        title: 'User Responsibilities',
                        content:
                            'By using this app, you agree to:',
                        children: [
                          _buildListItem('Provide accurate information during tests'),
                          _buildListItem('Use the app in a safe environment (not while driving or operating machinery)'),
                          _buildListItem('Not use the app as a medical diagnostic tool'),
                          _buildListItem('Consult healthcare professionals for medical advice'),
                          _buildListItem('Keep your login credentials secure'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Important Notes
                      _buildSection(
                        title: 'Important Notes',
                        content:
                            'Please be aware that:',
                        children: [
                          _buildListItem('This app is for informational purposes only and not a medical device'),
                          _buildListItem('Stress scores are estimates based on collected data'),
                          _buildListItem('Individual results may vary based on many factors'),
                          _buildListItem('We recommend consulting with healthcare professionals for health concerns'),
                          _buildListItem('The app requires camera access for PPG heart rate measurement'),
                          _buildListItem('Sensor permissions are needed for accurate movement tracking'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Consent
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'By clicking "Continue" on the splash screen, you acknowledge that you have read and agree to these Terms & Conditions.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1A0A08),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Close Button
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A0A08),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),
        if (children != null) ...[
          const SizedBox(height: 12),
          ...children,
        ],
      ],
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}