import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/custom_button.dart';
import 'consent_support_screen.dart';

class DataConsentScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const DataConsentScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<DataConsentScreen> createState() => _DataConsentScreenState();
}

class _DataConsentScreenState extends State<DataConsentScreen> {
  bool _heartRate = false;
  bool _activityLevel = false;
  bool _typingSpeed = false;
  bool _responseTime = false;
  bool _errorRate = false;
  bool _accelerometer = false;
  bool _gyroscope = false;
  bool _who5 = false;
  bool _pss = false;

  bool get _allChecked =>
      _heartRate &&
      _activityLevel &&
      _typingSpeed &&
      _responseTime &&
      _errorRate &&
      _accelerometer &&
      _gyroscope &&
      _who5 &&
      _pss;

  void _handleContinue() async {
    if (_allChecked) {
      Navigator.pop(context, true); // Return true when all checked
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsentSupportScreen(
            onRetry: () {
              Navigator.pop(context);
            },
            onProceed: () {
              Navigator.pop(context, true); // Return true from support screen
            },
          ),
        ),
      );
      
      if (result == true) {
        Navigator.pop(context, true); // Return true to splash screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5EDE8),
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
                        color: const Color(0xFF9B2B1A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF9B2B1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Transparency',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0A08),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your privacy matters to us',
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
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF1A0A08),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getCheckedCount()}/9 consents',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9B2B1A),
                          ),
                        ),
                        Text(
                          _allChecked ? 'All set! ✓' : 'Review below',
                          style: TextStyle(
                            fontSize: 14,
                            color: _allChecked
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _getCheckedCount() / 9,
                        backgroundColor: const Color(0xFFE5D5CC),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF9B2B1A),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'We collect the following data to provide accurate stress assessments:',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Physiological Data
                      _buildSectionCard(
                        icon: Icons.favorite_border,
                        title: 'Physiological Data',
                        children: [
                          _buildCheckboxTile(
                            'Heart Rate (PPG via camera/sensor)',
                            _heartRate,
                            (value) => setState(() => _heartRate = value ?? false),
                          ),
                          _buildCheckboxTile(
                            'Activity Level (steps, movement patterns)',
                            _activityLevel,
                            (value) => setState(() => _activityLevel = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Behavioral Data
                      _buildSectionCard(
                        icon: Icons.psychology_outlined,
                        title: 'Behavioral Data',
                        children: [
                          _buildCheckboxTile(
                            'Typing Speed & Interaction Patterns',
                            _typingSpeed,
                            (value) => setState(() => _typingSpeed = value ?? false),
                          ),
                          _buildCheckboxTile(
                            'Response Time during tests',
                            _responseTime,
                            (value) => setState(() => _responseTime = value ?? false),
                          ),
                          _buildCheckboxTile(
                            'Error Rate in cognitive tasks',
                            _errorRate,
                            (value) => setState(() => _errorRate = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Device Sensor Data
                      _buildSectionCard(
                        icon: Icons.sensors,
                        title: 'Device Sensor Data',
                        children: [
                          _buildCheckboxTile(
                            'Accelerometer (movement detection)',
                            _accelerometer,
                            (value) => setState(() => _accelerometer = value ?? false),
                          ),
                          _buildCheckboxTile(
                            'Gyroscope (orientation & motion)',
                            _gyroscope,
                            (value) => setState(() => _gyroscope = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Self-Reported Data
                      _buildSectionCard(
                        icon: Icons.assignment_outlined,
                        title: 'Self-Reported Data',
                        children: [
                          _buildCheckboxTile(
                            'WHO-5 Well-being Questionnaire',
                            _who5,
                            (value) => setState(() => _who5 = value ?? false),
                          ),
                          _buildCheckboxTile(
                            'PSS (Perceived Stress Scale) Responses',
                            _pss,
                            (value) => setState(() => _pss = value ?? false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B2B1A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF9B2B1A).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B2B1A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF9B2B1A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Your data is encrypted and stored securely. We never share your personal information with third parties.',
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCheckedCount() {
    int count = 0;
    if (_heartRate) count++;
    if (_activityLevel) count++;
    if (_typingSpeed) count++;
    if (_responseTime) count++;
    if (_errorRate) count++;
    if (_accelerometer) count++;
    if (_gyroscope) count++;
    if (_who5) count++;
    if (_pss) count++;
    return count;
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B2B1A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF9B2B1A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF9B2B1A)
                    : Colors.transparent,
                border: Border.all(
                  color: value
                      ? const Color(0xFF9B2B1A)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: value
                      ? const Color(0xFF1A0A08)
                      : const Color(0xFF666666),
                  fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
